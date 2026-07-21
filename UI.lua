local _, RPWatcher = ...

local UI = {}
RPWatcher.UI = UI

local ROW_HEIGHT = 24
local watcherCount = 0
local isResizing = false

local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
frame:SetSize(1, 1)
frame:SetPoint("CENTER")
frame:SetFrameStrata("DIALOG")
frame:SetMovable(true)
frame:SetResizable(true)
frame:EnableMouse(true)
frame:RegisterForDrag("LeftButton")
frame:SetClampedToScreen(true)

local minWidth, minHeight, maxWidth, maxHeight = RPWatcher.Settings:GetWindowResizeBounds()
frame:SetResizeBounds(minWidth, minHeight, maxWidth, maxHeight)
frame:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
frame:SetBackdropColor(0.035, 0.035, 0.045, 1)
frame:SetBackdropBorderColor(0.32, 0.32, 0.38, 1)
frame:Hide()

local title = frame:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
title:SetPoint("TOPLEFT", 14, -12)
title:SetText("RPWatcher")

local statusSummary = frame:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
statusSummary:SetPoint("TOPLEFT", 14, -36)
statusSummary:SetPoint("TOPRIGHT", frame, "TOPRIGHT", -34, -36)
statusSummary:SetJustifyH("LEFT")
statusSummary:SetText("Aktuell: 0 · Vorher: 0 · Unbekannt: 0")

local closeButton = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", 1, 1)

local listArea = CreateFrame("Frame", nil, frame, "BackdropTemplate")
listArea:SetPoint("TOPLEFT", 12, -56)
listArea:SetPoint("BOTTOMRIGHT", -12, 12)
listArea:SetBackdrop({
    bgFile = "Interface\\Buttons\\WHITE8X8",
    edgeFile = "Interface\\Buttons\\WHITE8X8",
    edgeSize = 1,
})
listArea:SetBackdropColor(0.015, 0.015, 0.02, 0.55)
listArea:SetBackdropBorderColor(0.18, 0.18, 0.22, 1)

local emptyHint = listArea:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
emptyHint:SetPoint("CENTER")
emptyHint:SetText("Keine beobachtenden Spieler erfasst.")

local scrollFrame = CreateFrame("ScrollFrame", nil, listArea, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 5, -5)
scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(1, 1)
scrollFrame:SetScrollChild(scrollChild)

local resizeHandle = CreateFrame("Button", nil, frame)
resizeHandle:SetSize(16, 16)
resizeHandle:SetPoint("BOTTOMRIGHT", -2, 2)
resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")

local rows = {}
local nextElapsedUpdate = 0
local currentWatchers
local listNeedsRefresh = true

local function formatElapsed(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    if seconds < 60 then
        return seconds .. " Sek."
    end

    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    if minutes < 60 then
        if remainingSeconds > 0 then
            return minutes .. " Min. " .. remainingSeconds .. " Sek."
        end
        return minutes .. " Min."
    end

    local hours = math.floor(minutes / 60)
    local remainingMinutes = minutes % 60
    if remainingMinutes > 0 then
        return hours .. " Std. " .. remainingMinutes .. " Min."
    end
    return hours .. " Std."
end

local function getElapsedStart(watcher)
    if watcher.observationStatus == RPWatcher.Scanner.STATUS_ACTIVE then
        return watcher.targetStartedAt
    elseif watcher.observationStatus == RPWatcher.Scanner.STATUS_INACTIVE then
        return watcher.targetLostAt
    end
    return watcher.nameplateHiddenAt
end

local function updateRowTime(row, now)
    local watcher = row.watcher
    if not watcher then
        return
    end

    local elapsed = formatElapsed(now - (getElapsedStart(watcher) or now))
    if watcher.observationStatus == RPWatcher.Scanner.STATUS_ACTIVE then
        row.timeText:SetText("seit " .. elapsed)
    elseif watcher.observationStatus == RPWatcher.Scanner.STATUS_INACTIVE then
        row.timeText:SetText("zuletzt vor " .. elapsed)
    else
        row.timeText:SetText("nicht mehr sichtbar · vor " .. elapsed)
    end
end

local function hideOwnedTooltip(owner)
    if GameTooltip:IsOwned(owner) then
        GameTooltip:Hide()
    end
end

local function showNameTooltip(button)
    local watcher = button.row and button.row.watcher
    if not watcher then
        return
    end

    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if type(watcher.rpName) == "string" and watcher.rpName ~= "" then
        GameTooltip:AddLine(watcher.rpName, 1, 0.82, 0, true)
        GameTooltip:AddLine("Spielname: " .. (watcher.name or "Unbekannt"), 0.85, 0.85, 0.85, true)
    else
        GameTooltip:AddLine(watcher.name or "Unbekannter Spieler", 1, 0.82, 0, true)
        GameTooltip:AddLine("Kein RP-Name bekannt.", 0.75, 0.75, 0.75, true)
    end

    if not RPWatcher.TRP3 or not RPWatcher.TRP3:IsAvailable() then
        GameTooltip:AddLine("Total RP 3 ist nicht verfügbar.", 0.7, 0.7, 0.7, true)
    end
    GameTooltip:Show()
end

local function showProfileTooltip(button)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:AddLine("TRP3-Profil öffnen", 1, 0.82, 0)
    GameTooltip:Show()
end

local function openRowProfile(button)
    local watcher = button.row and button.row.watcher
    if not watcher or watcher.isTest or not RPWatcher.TRP3 then
        return
    end

    local opened, reason = RPWatcher.TRP3:OpenProfile(watcher)
    if opened then
        return
    elseif reason == "requested" or reason == "queued" or reason == "cooldown" then
        print("|cff66ccffRPWatcher|r: Profildaten wurden angefragt. Versuche es in wenigen Sekunden erneut.")
    else
        print("|cff66ccffRPWatcher|r: Das TRP3-Profil konnte nicht geöffnet werden.")
    end
end

local function acquireRow(index)
    local row = rows[index]
    if row then
        return row
    end

    row = CreateFrame("Frame", nil, scrollChild)
    row:SetHeight(ROW_HEIGHT)

    row.statusIcon = row:CreateFontString(nil, "OVERLAY", "GameFontNormalLarge")
    row.statusIcon:SetPoint("LEFT", 4, 0)
    row.statusIcon:SetWidth(18)
    row.statusIcon:SetJustifyH("CENTER")

    row.profileButton = CreateFrame("Button", nil, row)
    row.profileButton:SetPoint("RIGHT", -4, 0)
    row.profileButton:SetSize(46, ROW_HEIGHT)
    row.profileButton.row = row
    row.profileButton.label = row.profileButton:CreateFontString(nil, "OVERLAY", "GameFontNormalSmall")
    row.profileButton.label:SetAllPoints()
    row.profileButton.label:SetText("[Profil]")
    row.profileButton:SetScript("OnEnter", function(self)
        self.label:SetTextColor(1, 1, 1)
        showProfileTooltip(self)
    end)
    row.profileButton:SetScript("OnLeave", function(self)
        self.label:SetTextColor(1, 0.82, 0)
        hideOwnedTooltip(self)
    end)
    row.profileButton:SetScript("OnClick", openRowProfile)

    row.timeText = row:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    row.timeText:SetWidth(142)
    row.timeText:SetJustifyH("RIGHT")
    row.timeText:SetWordWrap(false)

    row.nameButton = CreateFrame("Button", nil, row)
    row.nameButton:SetPoint("LEFT", row.statusIcon, "RIGHT", 5, 0)
    row.nameButton:SetHeight(ROW_HEIGHT)
    row.nameButton.row = row
    row.nameButton:SetScript("OnEnter", showNameTooltip)
    row.nameButton:SetScript("OnLeave", hideOwnedTooltip)

    row.nameText = row.nameButton:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    row.nameText:SetAllPoints()
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)

    rows[index] = row
    return row
end

local function updateRow(row, watcher, now)
    row.watcher = watcher
    row.nameText:SetText(watcher.rpName or watcher.name or "Unbekannter Spieler")

    local profileAvailable = RPWatcher.Settings:IsProfileButtonEnabled()
        and not watcher.isTest
        and RPWatcher.TRP3
        and RPWatcher.TRP3:IsAvailable()
        and RPWatcher.TRP3:IsProfileOpenAvailable()
    row.profileButton:SetShown(profileAvailable and true or false)

    row.timeText:ClearAllPoints()
    if profileAvailable then
        row.timeText:SetPoint("RIGHT", row.profileButton, "LEFT", -7, 0)
    else
        row.timeText:SetPoint("RIGHT", row, "RIGHT", -4, 0)
    end
    row.nameButton:ClearAllPoints()
    row.nameButton:SetPoint("LEFT", row.statusIcon, "RIGHT", 5, 0)
    row.nameButton:SetPoint("RIGHT", row.timeText, "LEFT", -8, 0)

    if watcher.observationStatus == RPWatcher.Scanner.STATUS_ACTIVE then
        row.statusIcon:SetText("●")
        row.statusIcon:SetTextColor(0.2, 1, 0.25)
    elseif watcher.observationStatus == RPWatcher.Scanner.STATUS_INACTIVE then
        row.statusIcon:SetText("●")
        row.statusIcon:SetTextColor(0.55, 0.55, 0.58)
    else
        row.statusIcon:SetText("?")
        row.statusIcon:SetTextColor(0.85, 0.8, 0.55)
    end

    updateRowTime(row, now)
    row:Show()
end

local function hideRow(row)
    hideOwnedTooltip(row.nameButton)
    hideOwnedTooltip(row.profileButton)
    row.watcher = nil
    row:Hide()
end

local function refreshVisibleRows(now)
    if not frame:IsShown() or not currentWatchers then
        return
    end

    local firstWatcherIndex = math.floor(scrollFrame:GetVerticalScroll() / ROW_HEIGHT) + 1
    local visibleCapacity = math.max(1, math.ceil(scrollFrame:GetHeight() / ROW_HEIGHT) + 1)
    local rowsNeeded = math.max(0, math.min(visibleCapacity, watcherCount - firstWatcherIndex + 1))
    for poolIndex = 1, rowsNeeded do
        local watcherIndex = firstWatcherIndex + poolIndex - 1
        local row = acquireRow(poolIndex)
        local watcher = currentWatchers[watcherIndex]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -((watcherIndex - 1) * ROW_HEIGHT))
        row:SetPoint("TOPRIGHT", 0, -((watcherIndex - 1) * ROW_HEIGHT))
        updateRow(row, watcher, now)
    end
    for poolIndex = rowsNeeded + 1, #rows do
        hideRow(rows[poolIndex])
    end
end

local function renderWatcherList()
    currentWatchers = RPWatcher.Scanner:GetSortedWatchers()
    local contentHeight = math.max(1, watcherCount * ROW_HEIGHT)
    scrollChild:SetHeight(contentHeight)
    scrollFrame:UpdateScrollChildRect()

    local maximumScroll = math.max(0, contentHeight - scrollFrame:GetHeight())
    if scrollFrame:GetVerticalScroll() > maximumScroll then
        scrollFrame:SetVerticalScroll(maximumScroll)
    end

    refreshVisibleRows(GetTime())
    listNeedsRefresh = false
end

scrollFrame:SetScript("OnSizeChanged", function(_, width)
    scrollChild:SetWidth(math.max(1, width))
    if frame:IsShown() then
        refreshVisibleRows(GetTime())
    end
end)

scrollFrame:SetScript("OnVerticalScroll", function()
    refreshVisibleRows(GetTime())
end)

local function saveCurrentSize()
    RPWatcher.Settings:SaveWindowSize(frame:GetWidth(), frame:GetHeight())
end

local function restorePosition()
    local window = RPWatcher.Settings:GetWindowState()
    frame:ClearAllPoints()
    frame:SetPoint(window.point, UIParent, window.relativePoint, window.x, window.y)
end

local function applyWindowLock()
    local locked = RPWatcher.Settings:IsWindowLocked()
    if locked and isResizing then
        frame:StopMovingOrSizing()
        isResizing = false
        saveCurrentSize()
    end
    frame:SetMovable(not locked)
    frame:SetResizable(not locked)
    resizeHandle:SetShown(not locked)
end

frame:SetScript("OnDragStart", function(self)
    if not RPWatcher.Settings:IsWindowLocked() then
        self:StartMoving()
    end
end)

frame:SetScript("OnDragStop", function(self)
    self:StopMovingOrSizing()
    local point, _, relativePoint, x, y = self:GetPoint(1)
    RPWatcher.Settings:SaveWindowPosition(point, relativePoint, x, y)
end)

resizeHandle:SetScript("OnMouseDown", function()
    if not RPWatcher.Settings:IsWindowLocked() then
        isResizing = true
        frame:StartSizing("BOTTOMRIGHT")
    end
end)

resizeHandle:SetScript("OnMouseUp", function()
    if isResizing then
        frame:StopMovingOrSizing()
        isResizing = false
        saveCurrentSize()
    end
end)

closeButton:SetScript("OnClick", function()
    UI:SetManualVisibility(false)
end)

function UI:IsShown()
    return frame:IsShown()
end

function UI:IsManuallyShown()
    return RPWatcher.Settings:IsWindowManuallyShown()
end

function UI:UpdateActualVisibility()
    local shouldShow = self:IsManuallyShown()
        and (not RPWatcher.Settings:IsAutoHideEnabled() or watcherCount > 0)

    local wasShown = frame:IsShown()
    if shouldShow then
        frame:Show()
        if listNeedsRefresh and RPWatcher.Scanner then
            renderWatcherList()
        elseif not wasShown then
            self:RefreshElapsedTimes(GetTime(), true)
        end
    else
        frame:Hide()
    end
end

function UI:SetManualVisibility(isShown)
    RPWatcher.Settings:SetWindowManuallyShown(isShown)
end

function UI:ToggleManualVisibility()
    self:SetManualVisibility(not self:IsManuallyShown())
end

-- Compatibility surface: callers requesting visibility are treated as manual actions.
function UI:SetShown(isShown)
    self:SetManualVisibility(isShown)
end

function UI:Initialize()
    if RPWatcher.Scanner then
        RPWatcher.Scanner:SetChangeCallback(function()
            UI:RefreshWatcherList()
        end)
    end
end

function UI:RefreshWatcherList()
    if not RPWatcher.Scanner then
        return
    end

    if RPWatcher.Performance then
        RPWatcher.Performance:RecordUIDataUpdate()
    end
    local activeCount, inactiveCount, unknownCount = RPWatcher.Scanner:GetWatcherStatusCounts()
    watcherCount = activeCount + inactiveCount + unknownCount
    listNeedsRefresh = true

    statusSummary:SetText(("Aktuell: %d · Vorher: %d · Unbekannt: %d"):format(activeCount, inactiveCount, unknownCount))

    emptyHint:SetShown(watcherCount == 0)
    scrollFrame:SetShown(watcherCount > 0)
    self:UpdateActualVisibility()
    nextElapsedUpdate = GetTime() + 1
end

function UI:RefreshElapsedTimes(now, force)
    if not frame:IsShown() then
        return
    end
    if not force and now < nextElapsedUpdate then
        return
    end

    nextElapsedUpdate = now + 1
    for index = 1, #rows do
        local row = rows[index]
        if row:IsShown() and row.watcher then
            updateRowTime(row, now)
        end
    end
    if RPWatcher.Performance then
        RPWatcher.Performance:RecordUITimeUpdate()
    end
end

function UI:ApplySettings()
    local window = RPWatcher.Settings:GetWindowState()
    frame:SetScale(window.scale)
    frame:SetSize(window.width, window.height)
    frame:SetBackdropColor(0.035, 0.035, 0.045, window.backgroundAlpha)
    restorePosition()
    applyWindowLock()
    self:UpdateActualVisibility()
end

function UI:OnSettingChanged(settingName)
    if settingName == "showTRP3ProfileButton" then
        self:RefreshWatcherList()
    elseif settingName == "visibility" or settingName == "autoHideWhenEmpty" then
        self:UpdateActualVisibility()
    elseif settingName == "unknownRetentionSeconds" then
        return
    else
        self:ApplySettings()
    end
end

function UI:RestoreState()
    self:ApplySettings()
end

-- Public module surface. The main frame remains private.
UI.ListArea = listArea
UI.EmptyHint = emptyHint
