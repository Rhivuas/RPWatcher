local _, RPWatcher = ...

local UI = {}
RPWatcher.UI = UI

local Theme = RPWatcher.Theme
local colors = Theme.colors
local layout = Theme.layout
local ROW_HEIGHT = layout.rowHeight
local ROW_STRIDE = ROW_HEIGHT + layout.rowGap
local watcherCount = 0
local isResizing = false
local currentBackgroundAlpha = 1

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
Theme:ApplyBackdrop(frame, colors.background, colors.border, 1)
frame:Hide()

local titleBar = CreateFrame("Frame", nil, frame)
titleBar:SetPoint("TOPLEFT", 1, -1)
titleBar:SetPoint("TOPRIGHT", -1, -1)
titleBar:SetHeight(layout.titleHeight)
titleBar:EnableMouse(true)
titleBar:RegisterForDrag("LeftButton")

local titleBarBackground = Theme:CreateColorTexture(titleBar, "BACKGROUND", colors.titleBar)
titleBarBackground:SetAllPoints()

local titleAccent = Theme:CreateColorTexture(titleBar, "ARTWORK", colors.accent)
titleAccent:SetPoint("BOTTOMLEFT")
titleAccent:SetPoint("BOTTOMRIGHT")
titleAccent:SetHeight(1)

local title = titleBar:CreateFontString(nil, "OVERLAY", Theme.fonts.title)
title:SetPoint("TOPLEFT", 13, -6)
title:SetText("RPWatcher")
Theme:SetFontColor(title, colors.text)

local subtitle = titleBar:CreateFontString(nil, "OVERLAY", Theme.fonts.small)
subtitle:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -1)
subtitle:SetText("Beobachtungsübersicht")
Theme:SetFontColor(subtitle, colors.secondaryText)

local lockIndicator = CreateFrame("Frame", nil, titleBar)
lockIndicator:SetPoint("RIGHT", titleBar, "RIGHT", -35, 0)
lockIndicator:SetSize(58, 22)
lockIndicator:EnableMouse(true)
lockIndicator.text = lockIndicator:CreateFontString(nil, "OVERLAY", Theme.fonts.small)
lockIndicator.text:SetAllPoints()
lockIndicator.text:SetText("Gesperrt")
Theme:SetFontColor(lockIndicator.text, colors.accent)
lockIndicator:Hide()

local closeButton = CreateFrame("Button", nil, titleBar, "UIPanelCloseButton")
closeButton:SetPoint("TOPRIGHT", 0, 0)

local statusBar = CreateFrame("Frame", nil, frame)
statusBar:SetPoint("TOPLEFT", 1, -(layout.titleHeight + 1))
statusBar:SetPoint("TOPRIGHT", -1, -(layout.titleHeight + 1))
statusBar:SetHeight(layout.statusHeight)

local statusBarBackground = Theme:CreateColorTexture(statusBar, "BACKGROUND", colors.surfaceAlternate)
statusBarBackground:SetAllPoints()

local statusDivider = Theme:CreateColorTexture(statusBar, "ARTWORK", colors.divider)
statusDivider:SetPoint("BOTTOMLEFT")
statusDivider:SetPoint("BOTTOMRIGHT")
statusDivider:SetHeight(1)

local activeSummary = statusBar:CreateFontString(nil, "OVERLAY", Theme.fonts.secondary)
activeSummary:SetPoint("LEFT", 11, 0)
activeSummary:SetJustifyH("LEFT")
Theme:SetFontColor(activeSummary, colors.active)

local inactiveSummary = statusBar:CreateFontString(nil, "OVERLAY", Theme.fonts.secondary)
inactiveSummary:SetPoint("CENTER", 0, 0)
inactiveSummary:SetJustifyH("CENTER")
Theme:SetFontColor(inactiveSummary, colors.inactive)

local unknownSummary = statusBar:CreateFontString(nil, "OVERLAY", Theme.fonts.secondary)
unknownSummary:SetPoint("RIGHT", -11, 0)
unknownSummary:SetJustifyH("RIGHT")
Theme:SetFontColor(unknownSummary, colors.unknown)

activeSummary:SetText("● 0 aktuell")
inactiveSummary:SetText("● 0 vorher")
unknownSummary:SetText("? 0 unbekannt")

local listArea = CreateFrame("Frame", nil, frame, "BackdropTemplate")
listArea:SetPoint("TOPLEFT", layout.outerPadding, -(layout.titleHeight + layout.statusHeight + 5))
listArea:SetPoint("BOTTOMRIGHT", -layout.outerPadding, layout.outerPadding)
Theme:ApplyBackdrop(listArea, colors.surface, colors.divider, 0.88)

local emptyState = CreateFrame("Frame", nil, listArea)
emptyState:SetPoint("TOPLEFT", 18, -18)
emptyState:SetPoint("BOTTOMRIGHT", -18, 18)

local emptySymbol = emptyState:CreateFontString(nil, "OVERLAY", Theme.fonts.display)
emptySymbol:SetPoint("CENTER", 0, 18)
emptySymbol:SetText("?")
Theme:SetFontColor(emptySymbol, colors.unknown, 0.72)

local emptyHint = emptyState:CreateFontString(nil, "OVERLAY", Theme.fonts.body)
emptyHint:SetPoint("TOP", emptySymbol, "BOTTOM", 0, -3)
emptyHint:SetPoint("LEFT", 4, 0)
emptyHint:SetPoint("RIGHT", -4, 0)
emptyHint:SetJustifyH("CENTER")
emptyHint:SetText("Keine beobachtenden Spieler erfasst.")
Theme:SetFontColor(emptyHint, colors.text)

local emptyHelp = emptyState:CreateFontString(nil, "OVERLAY", Theme.fonts.muted)
emptyHelp:SetPoint("TOP", emptyHint, "BOTTOM", 0, -4)
emptyHelp:SetPoint("LEFT", 4, 0)
emptyHelp:SetPoint("RIGHT", -4, 0)
emptyHelp:SetJustifyH("CENTER")
emptyHelp:SetText("Spieler erscheinen hier, nachdem sie dich im Target hatten.")
Theme:SetFontColor(emptyHelp, colors.secondaryText)

local scrollFrame = CreateFrame("ScrollFrame", nil, listArea, "UIPanelScrollFrameTemplate")
scrollFrame:SetPoint("TOPLEFT", 5, -5)
scrollFrame:SetPoint("BOTTOMRIGHT", -25, 5)

local scrollChild = CreateFrame("Frame", nil, scrollFrame)
scrollChild:SetSize(1, 1)
scrollFrame:SetScrollChild(scrollChild)

local resizeHandle = CreateFrame("Button", nil, frame)
resizeHandle:SetSize(18, 18)
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
        row.timeText:SetText("nicht sichtbar · " .. elapsed)
    end
end

local function hideOwnedTooltip(owner)
    if GameTooltip:IsOwned(owner) then
        GameTooltip:Hide()
    end
end

local function getStatusTooltipText(watcher)
    if watcher.observationStatus == RPWatcher.Scanner.STATUS_ACTIVE then
        return "Status: Hat dich gerade im Target."
    elseif watcher.observationStatus == RPWatcher.Scanner.STATUS_INACTIVE then
        return "Status: Hatte dich zuvor im Target."
    end
    return "Status: Nameplate nicht mehr sichtbar."
end

local function setRowHovered(row, hovered)
    if row and row.hoverBackground then
        row.hoverBackground:SetShown(hovered and true or false)
    end
end

local function showNameTooltip(button)
    local watcher = button.row and button.row.watcher
    if not watcher then
        return
    end

    setRowHovered(button.row, true)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    if type(watcher.rpName) == "string" and watcher.rpName ~= "" then
        GameTooltip:AddLine(watcher.rpName, colors.accent[1], colors.accent[2], colors.accent[3], true)
        GameTooltip:AddLine("Spielname: " .. (watcher.name or "Unbekannt"), colors.text[1], colors.text[2], colors.text[3], true)
    else
        GameTooltip:AddLine(watcher.name or "Unbekannter Spieler", colors.accent[1], colors.accent[2], colors.accent[3], true)
        GameTooltip:AddLine("Kein RP-Name bekannt.", colors.secondaryText[1], colors.secondaryText[2], colors.secondaryText[3], true)
    end

    GameTooltip:AddLine(getStatusTooltipText(watcher), colors.secondaryText[1], colors.secondaryText[2], colors.secondaryText[3], true)
    if not RPWatcher.TRP3 or not RPWatcher.TRP3:IsAvailable() then
        GameTooltip:AddLine("Total RP 3 ist nicht verfügbar.", colors.mutedText[1], colors.mutedText[2], colors.mutedText[3], true)
    end
    GameTooltip:Show()
end

local function hideNameTooltip(button)
    setRowHovered(button.row, false)
    hideOwnedTooltip(button)
end

local function showProfileTooltip(button)
    setRowHovered(button.row, true)
    Theme:SetBackdropBackground(button, colors.buttonHover)
    GameTooltip:SetOwner(button, "ANCHOR_RIGHT")
    GameTooltip:AddLine("TRP3-Profil öffnen", colors.accent[1], colors.accent[2], colors.accent[3])
    GameTooltip:Show()
end

local function hideProfileTooltip(button)
    setRowHovered(button.row, false)
    Theme:SetBackdropBackground(button, colors.button)
    hideOwnedTooltip(button)
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

local function setProfileButtonPressed(button, pressed)
    Theme:SetBackdropBackground(button, pressed and colors.buttonPressed or colors.buttonHover)
end

local function acquireRow(index)
    local row = rows[index]
    if row then
        return row
    end

    row = CreateFrame("Frame", nil, scrollChild)
    row:SetHeight(ROW_HEIGHT)
    row:EnableMouse(true)

    row.baseBackground = Theme:CreateColorTexture(row, "BACKGROUND", colors.inactiveRow)
    row.baseBackground:SetAllPoints()

    row.alternateBackground = Theme:CreateColorTexture(row, "BORDER", colors.surfaceAlternate, 0.35)
    row.alternateBackground:SetAllPoints()

    row.hoverBackground = Theme:CreateColorTexture(row, "ARTWORK", colors.hover)
    row.hoverBackground:SetAllPoints()
    row.hoverBackground:Hide()

    row.statusAccent = Theme:CreateColorTexture(row, "ARTWORK", colors.inactive)
    row.statusAccent:SetPoint("TOPLEFT", 0, -3)
    row.statusAccent:SetPoint("BOTTOMLEFT", 0, 3)
    row.statusAccent:SetWidth(2)

    row.statusIcon = row:CreateFontString(nil, "OVERLAY", Theme.fonts.title)
    row.statusIcon:SetPoint("LEFT", 6, 0)
    row.statusIcon:SetWidth(19)
    row.statusIcon:SetJustifyH("CENTER")

    row.profileButton = CreateFrame("Button", nil, row, "BackdropTemplate")
    row.profileButton:SetPoint("RIGHT", -5, 0)
    row.profileButton:SetSize(layout.profileButtonWidth, 21)
    row.profileButton.row = row
    Theme:ApplyBackdrop(row.profileButton, colors.button, colors.border, 1)
    row.profileButton.label = row.profileButton:CreateFontString(nil, "OVERLAY", Theme.fonts.small)
    row.profileButton.label:SetAllPoints()
    row.profileButton.label:SetText("Profil")
    Theme:SetFontColor(row.profileButton.label, colors.accent)
    row.profileButton:SetScript("OnEnter", showProfileTooltip)
    row.profileButton:SetScript("OnLeave", hideProfileTooltip)
    row.profileButton:SetScript("OnMouseDown", function(self)
        setProfileButtonPressed(self, true)
    end)
    row.profileButton:SetScript("OnMouseUp", function(self)
        setProfileButtonPressed(self, false)
    end)
    row.profileButton:SetScript("OnClick", openRowProfile)

    row.timeText = row:CreateFontString(nil, "OVERLAY", Theme.fonts.secondary)
    row.timeText:SetWidth(142)
    row.timeText:SetJustifyH("RIGHT")
    row.timeText:SetWordWrap(false)
    Theme:SetFontColor(row.timeText, colors.secondaryText)

    row.nameButton = CreateFrame("Button", nil, row)
    row.nameButton:SetPoint("LEFT", row.statusIcon, "RIGHT", 4, 0)
    row.nameButton:SetHeight(ROW_HEIGHT)
    row.nameButton.row = row
    row.nameButton:SetScript("OnEnter", showNameTooltip)
    row.nameButton:SetScript("OnLeave", hideNameTooltip)

    row.nameText = row.nameButton:CreateFontString(nil, "OVERLAY", Theme.fonts.body)
    row.nameText:SetAllPoints()
    row.nameText:SetJustifyH("LEFT")
    row.nameText:SetWordWrap(false)
    Theme:SetFontColor(row.nameText, colors.text)

    row:SetScript("OnEnter", function(self)
        setRowHovered(self, true)
    end)
    row:SetScript("OnLeave", function(self)
        setRowHovered(self, false)
    end)

    rows[index] = row
    return row
end

local function getResponsiveTimeWidth()
    if scrollFrame:GetWidth() < 360 then
        return 115
    elseif scrollFrame:GetWidth() < 430 then
        return 125
    end
    return 142
end

local function updateRow(row, watcher, now, watcherIndex)
    row.watcher = watcher
    row.nameText:SetText(watcher.rpName or watcher.name or "Unbekannter Spieler")
    row.alternateBackground:SetShown((watcherIndex % 2) == 0)
    Theme:SetTextureColor(row.alternateBackground, colors.surfaceAlternate, currentBackgroundAlpha * 0.35)
    row.hoverBackground:Hide()
    Theme:SetBackdropBackground(row.profileButton, colors.button)

    local profileAvailable = RPWatcher.Settings:IsProfileButtonEnabled()
        and not watcher.isTest
        and RPWatcher.TRP3
        and RPWatcher.TRP3:IsAvailable()
        and RPWatcher.TRP3:IsProfileOpenAvailable()
    row.profileButton:SetShown(profileAvailable and true or false)

    row.timeText:SetWidth(getResponsiveTimeWidth())
    row.timeText:ClearAllPoints()
    if profileAvailable then
        row.timeText:SetPoint("RIGHT", row.profileButton, "LEFT", -7, 0)
    else
        row.timeText:SetPoint("RIGHT", row, "RIGHT", -7, 0)
    end
    row.nameButton:ClearAllPoints()
    row.nameButton:SetPoint("LEFT", row.statusIcon, "RIGHT", 4, 0)
    row.nameButton:SetPoint("RIGHT", row.timeText, "LEFT", -9, 0)

    if watcher.observationStatus == RPWatcher.Scanner.STATUS_ACTIVE then
        row.statusIcon:SetText("●")
        Theme:SetFontColor(row.statusIcon, colors.active)
        Theme:SetTextureColor(row.statusAccent, colors.active)
        Theme:SetTextureColor(row.baseBackground, colors.activeRow, currentBackgroundAlpha)
    elseif watcher.observationStatus == RPWatcher.Scanner.STATUS_INACTIVE then
        row.statusIcon:SetText("●")
        Theme:SetFontColor(row.statusIcon, colors.inactive)
        Theme:SetTextureColor(row.statusAccent, colors.inactive)
        Theme:SetTextureColor(row.baseBackground, colors.inactiveRow, currentBackgroundAlpha)
    else
        row.statusIcon:SetText("?")
        Theme:SetFontColor(row.statusIcon, colors.unknown)
        Theme:SetTextureColor(row.statusAccent, colors.unknown)
        Theme:SetTextureColor(row.baseBackground, colors.unknownRow, currentBackgroundAlpha)
    end

    updateRowTime(row, now)
    row:Show()
end

local function hideRow(row)
    hideOwnedTooltip(row.nameButton)
    hideOwnedTooltip(row.profileButton)
    row.watcher = nil
    row.hoverBackground:Hide()
    Theme:SetBackdropBackground(row.profileButton, colors.button)
    row:Hide()
end

local function refreshVisibleRows(now)
    if not frame:IsShown() or not currentWatchers then
        return
    end

    local firstWatcherIndex = math.floor(scrollFrame:GetVerticalScroll() / ROW_STRIDE) + 1
    local visibleCapacity = math.max(1, math.ceil(scrollFrame:GetHeight() / ROW_STRIDE) + 1)
    local rowsNeeded = math.max(0, math.min(visibleCapacity, watcherCount - firstWatcherIndex + 1))
    for poolIndex = 1, rowsNeeded do
        local watcherIndex = firstWatcherIndex + poolIndex - 1
        local row = acquireRow(poolIndex)
        local watcher = currentWatchers[watcherIndex]
        row:ClearAllPoints()
        row:SetPoint("TOPLEFT", 0, -((watcherIndex - 1) * ROW_STRIDE))
        row:SetPoint("TOPRIGHT", 0, -((watcherIndex - 1) * ROW_STRIDE))
        updateRow(row, watcher, now, watcherIndex)
    end
    for poolIndex = rowsNeeded + 1, #rows do
        hideRow(rows[poolIndex])
    end
end

local function renderWatcherList()
    currentWatchers = RPWatcher.Scanner:GetSortedWatchers()
    local contentHeight = math.max(1, watcherCount * ROW_STRIDE)
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

local function showSimpleTooltip(owner, text)
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:AddLine(text, colors.accent[1], colors.accent[2], colors.accent[3], true)
    GameTooltip:Show()
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
    lockIndicator:SetShown(locked)
end

local function startMoving(self)
    if not RPWatcher.Settings:IsWindowLocked() then
        frame:StartMoving()
    end
end

local function stopMoving(self)
    frame:StopMovingOrSizing()
    local point, _, relativePoint, x, y = frame:GetPoint(1)
    RPWatcher.Settings:SaveWindowPosition(point, relativePoint, x, y)
end

frame:SetScript("OnDragStart", startMoving)
frame:SetScript("OnDragStop", stopMoving)
titleBar:SetScript("OnDragStart", startMoving)
titleBar:SetScript("OnDragStop", stopMoving)

lockIndicator:SetScript("OnEnter", function(self)
    showSimpleTooltip(self, "Das RPWatcher-Fenster ist gesperrt.")
end)
lockIndicator:SetScript("OnLeave", hideOwnedTooltip)

resizeHandle:SetScript("OnEnter", function(self)
    showSimpleTooltip(self, "Fenstergröße ändern")
end)
resizeHandle:SetScript("OnLeave", hideOwnedTooltip)

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

    activeSummary:SetText(("● %d aktuell"):format(activeCount))
    inactiveSummary:SetText(("● %d vorher"):format(inactiveCount))
    unknownSummary:SetText(("? %d unbekannt"):format(unknownCount))

    emptyState:SetShown(watcherCount == 0)
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

local function applyBackgroundTransparency(alpha)
    currentBackgroundAlpha = alpha
    Theme:SetBackdropBackground(frame, colors.background, alpha)
    Theme:SetBackdropBackground(listArea, colors.surface, alpha * 0.88)
    Theme:SetTextureColor(titleBarBackground, colors.titleBar, alpha)
    Theme:SetTextureColor(statusBarBackground, colors.surfaceAlternate, alpha)
end

function UI:ApplySettings()
    local window = RPWatcher.Settings:GetWindowState()
    frame:SetScale(window.scale)
    frame:SetSize(window.width, window.height)
    applyBackgroundTransparency(window.backgroundAlpha)
    restorePosition()
    applyWindowLock()
    if frame:IsShown() then
        refreshVisibleRows(GetTime())
    end
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
