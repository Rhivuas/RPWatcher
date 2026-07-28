local _, RPWatcher = ...

local UI = {}
RPWatcher.UI = UI

local Theme = RPWatcher.Theme
local colors = Theme.colors
local layout = Theme.layout
local L = RPWatcher.L
local ROW_HEIGHT = layout.rowHeight
local ROW_STRIDE = ROW_HEIGHT + layout.rowGap
local watcherCount = 0
local isResizing = false
local currentBackgroundAlpha = 1
-- 1.2.0 combat visibility: purely transient, never persisted. The desired
-- manual visibility (RPWatcherDB.window.shown, via IsManuallyShown) already
-- survives combat untouched, so this flag only needs to say "suppress
-- actual visibility right now" -- no separate "shown before combat" bookkeeping
-- is needed on top of it. See computeActualVisibility below for how the two
-- combine.
local combatSuppressed = false

local frame = CreateFrame("Frame", nil, UIParent, "BackdropTemplate")
frame:SetSize(1, 1)
frame:SetPoint("CENTER")
-- 1.2.0: LOW keeps RPWatcher above the game world but behind Blizzard and
-- addon windows (character pane, map, bags, etc.). Nothing in this file may
-- call SetFrameStrata/SetFrameLevel/Raise on this frame afterward; see
-- Minimap.lua's button strata (a separate, unrelated frame) for the only
-- other strata call in the addon.
frame:SetFrameStrata("LOW")
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
title:SetPoint("LEFT", titleBar, "LEFT", 13, 0)
title:SetText("RPWatcher")
Theme:SetFontColor(title, colors.text)

local lockIndicator = CreateFrame("Frame", nil, titleBar)
lockIndicator:SetPoint("RIGHT", titleBar, "RIGHT", -35, 0)
lockIndicator:SetSize(58, 22)
lockIndicator:EnableMouse(true)
lockIndicator.text = lockIndicator:CreateFontString(nil, "OVERLAY", Theme.fonts.small)
lockIndicator.text:SetAllPoints()
lockIndicator.text:SetText(L.WINDOW_LOCKED)
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

-- Each summary slot pairs a reusable Theme status indicator with its own
-- count/label FontString; only the label text and slot width change on
-- refresh, no child frames are created per refresh.
local function createSummarySlot(anchorPoint, xOffset, labelColor)
    local slot = CreateFrame("Frame", nil, statusBar)
    slot:SetHeight(layout.statusHeight)
    slot:SetPoint(anchorPoint, statusBar, anchorPoint, xOffset, 0)

    local indicator = Theme:CreateStatusIndicator(slot, 14)
    indicator:SetPoint("LEFT", slot, "LEFT", 0, 0)

    local label = slot:CreateFontString(nil, "OVERLAY", Theme.fonts.secondary)
    label:SetPoint("LEFT", indicator, "RIGHT", 5, 0)
    label:SetJustifyH("LEFT")
    Theme:SetFontColor(label, labelColor)

    slot.indicator = indicator
    slot.label = label
    return slot
end

local function updateSummarySlotWidth(slot)
    slot:SetWidth(math.max(slot.indicator:GetWidth(), slot.indicator:GetWidth() + 5 + slot.label:GetStringWidth()))
end

local activeSummarySlot = createSummarySlot("LEFT", 11, colors.active)
local inactiveSummarySlot = createSummarySlot("CENTER", 0, colors.inactive)
local unknownSummarySlot = createSummarySlot("RIGHT", -11, colors.unknown)

Theme:SetStatusIndicator(activeSummarySlot.indicator, "active")
Theme:SetStatusIndicator(inactiveSummarySlot.indicator, "inactive")
Theme:SetStatusIndicator(unknownSummarySlot.indicator, "unknown")

activeSummarySlot.label:SetText(RPWatcher.Localization:Format("SUMMARY_ACTIVE", 0))
inactiveSummarySlot.label:SetText(RPWatcher.Localization:Format("SUMMARY_PREVIOUS", 0))
unknownSummarySlot.label:SetText(RPWatcher.Localization:Format("SUMMARY_UNKNOWN", 0))
updateSummarySlotWidth(activeSummarySlot)
updateSummarySlotWidth(inactiveSummarySlot)
updateSummarySlotWidth(unknownSummarySlot)

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
emptyHint:SetText(L.EMPTY_TITLE)
Theme:SetFontColor(emptyHint, colors.text)

local emptyHelp = emptyState:CreateFontString(nil, "OVERLAY", Theme.fonts.muted)
emptyHelp:SetPoint("TOP", emptyHint, "BOTTOM", 0, -4)
emptyHelp:SetPoint("LEFT", 4, 0)
emptyHelp:SetPoint("RIGHT", -4, 0)
emptyHelp:SetJustifyH("CENTER")
emptyHelp:SetText(L.EMPTY_DESCRIPTION)
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
    return RPWatcher.Localization:FormatDuration(seconds)
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
        row.timeText:SetText(RPWatcher.Localization:Format("TIME_ACTIVE", elapsed))
    elseif watcher.observationStatus == RPWatcher.Scanner.STATUS_INACTIVE then
        row.timeText:SetText(RPWatcher.Localization:Format("TIME_PREVIOUS", elapsed))
    else
        row.timeText:SetText(RPWatcher.Localization:Format("TIME_UNKNOWN", elapsed))
    end
end

local function hideOwnedTooltip(owner)
    if GameTooltip:IsOwned(owner) then
        GameTooltip:Hide()
    end
end

local function getStatusTooltipText(watcher)
    if watcher.observationStatus == RPWatcher.Scanner.STATUS_ACTIVE then
        return L.STATUS_TOOLTIP_ACTIVE
    elseif watcher.observationStatus == RPWatcher.Scanner.STATUS_INACTIVE then
        return L.STATUS_TOOLTIP_PREVIOUS
    end
    return L.STATUS_TOOLTIP_UNKNOWN
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
        GameTooltip:AddLine(RPWatcher.Localization:Format("PROFILE_WOW_NAME", watcher.name or L.UNKNOWN_PLAYER_NAME), colors.text[1], colors.text[2], colors.text[3], true)
    else
        GameTooltip:AddLine(watcher.name or L.UNKNOWN_PLAYER, colors.accent[1], colors.accent[2], colors.accent[3], true)
        GameTooltip:AddLine(L.PROFILE_NO_RP_NAME, colors.secondaryText[1], colors.secondaryText[2], colors.secondaryText[3], true)
    end

    GameTooltip:AddLine(getStatusTooltipText(watcher), colors.secondaryText[1], colors.secondaryText[2], colors.secondaryText[3], true)
    if not RPWatcher.TRP3 or not RPWatcher.TRP3:IsAvailable() then
        GameTooltip:AddLine(L.TRP3_UNAVAILABLE, colors.mutedText[1], colors.mutedText[2], colors.mutedText[3], true)
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
    GameTooltip:AddLine(L.PROFILE_TOOLTIP_OPEN, colors.accent[1], colors.accent[2], colors.accent[3])
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
        print("|cff66ccffRPWatcher|r: " .. L.PROFILE_REQUESTED)
    else
        print("|cff66ccffRPWatcher|r: " .. L.PROFILE_OPEN_FAILED)
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

    row.statusIndicator = Theme:CreateStatusIndicator(row, 16)
    row.statusIndicator:SetPoint("LEFT", 8, 0)

    row.profileButton = CreateFrame("Button", nil, row, "BackdropTemplate")
    row.profileButton:SetPoint("RIGHT", -5, 0)
    row.profileButton:SetSize(layout.profileButtonWidth, 21)
    row.profileButton.row = row
    Theme:ApplyBackdrop(row.profileButton, colors.button, colors.border, 1)
    row.profileButton.label = row.profileButton:CreateFontString(nil, "OVERLAY", Theme.fonts.small)
    row.profileButton.label:SetAllPoints()
    row.profileButton.label:SetText(L.PROFILE_BUTTON)
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
    row.nameButton:SetPoint("LEFT", row.statusIndicator, "RIGHT", 4, 0)
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
    row.nameText:SetText(watcher.rpName or watcher.name or L.UNKNOWN_PLAYER)
    row.alternateBackground:SetShown((watcherIndex % 2) == 0)
    Theme:SetTextureColor(row.alternateBackground, colors.surfaceAlternate, currentBackgroundAlpha * 0.35)
    row.hoverBackground:Hide()
    Theme:SetBackdropBackground(row.profileButton, colors.button)

    local profileAvailable = RPWatcher.Settings:IsProfileButtonEnabled()
        and not watcher.isTest
        and watcher.hasTRP3Profile == true
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
    row.nameButton:SetPoint("LEFT", row.statusIndicator, "RIGHT", 4, 0)
    row.nameButton:SetPoint("RIGHT", row.timeText, "LEFT", -9, 0)

    if watcher.observationStatus == RPWatcher.Scanner.STATUS_ACTIVE then
        Theme:SetStatusIndicator(row.statusIndicator, "active")
        Theme:SetTextureColor(row.statusAccent, colors.active)
        Theme:SetTextureColor(row.baseBackground, colors.activeRow, currentBackgroundAlpha)
    elseif watcher.observationStatus == RPWatcher.Scanner.STATUS_INACTIVE then
        Theme:SetStatusIndicator(row.statusIndicator, "inactive")
        Theme:SetTextureColor(row.statusAccent, colors.inactive)
        Theme:SetTextureColor(row.baseBackground, colors.inactiveRow, currentBackgroundAlpha)
    else
        Theme:SetStatusIndicator(row.statusIndicator, "unknown")
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

-- Defensive guard (Hotfix 1.1.1): while a data refresh is pending
-- (listNeedsRefresh == true), currentWatchers is a stale/prior snapshot and
-- must never be rendered against. Any synchronous event that can fire before
-- renderWatcherList() has run (e.g. OnSizeChanged from a scrollFrame
-- SetShown) returns here without rendering instead of observing a
-- half-updated state.
local function refreshVisibleRows(now)
    if listNeedsRefresh or not frame:IsShown() or not currentWatchers then
        return
    end

    -- The renderable row count is derived from the actual snapshot
    -- (#currentWatchers), not from the separately computed watcherCount,
    -- which only drives the status summary, empty-state, and auto-hide.
    local watcherListCount = #currentWatchers
    local firstWatcherIndex = math.floor(scrollFrame:GetVerticalScroll() / ROW_STRIDE) + 1
    local visibleCapacity = math.max(1, math.ceil(scrollFrame:GetHeight() / ROW_STRIDE) + 1)
    local rowsNeeded = math.max(0, math.min(visibleCapacity, watcherListCount - firstWatcherIndex + 1))
    for poolIndex = 1, rowsNeeded do
        local watcherIndex = firstWatcherIndex + poolIndex - 1
        local row = acquireRow(poolIndex)
        local watcher = currentWatchers[watcherIndex]
        if watcher then
            row:ClearAllPoints()
            row:SetPoint("TOPLEFT", 0, -((watcherIndex - 1) * ROW_STRIDE))
            row:SetPoint("TOPRIGHT", 0, -((watcherIndex - 1) * ROW_STRIDE))
            updateRow(row, watcher, now, watcherIndex)
        else
            -- Defensive fallback only; the reordered refresh above should
            -- make this unreachable in practice. Never pass a nil watcher
            -- into updateRow() (the reported UI.lua:385 crash).
            hideRow(row)
        end
    end
    for poolIndex = rowsNeeded + 1, #rows do
        hideRow(rows[poolIndex])
    end
end

local function renderWatcherList()
    -- Snapshot first, then mark it current, THEN render: refreshVisibleRows()
    -- itself now refuses to run while listNeedsRefresh is true, so this order
    -- is required for its own call below to have any effect.
    currentWatchers = RPWatcher.Scanner:GetSortedWatchers()
    listNeedsRefresh = false

    local contentHeight = math.max(1, #currentWatchers * ROW_STRIDE)
    scrollChild:SetHeight(contentHeight)
    scrollFrame:UpdateScrollChildRect()

    local maximumScroll = math.max(0, contentHeight - scrollFrame:GetHeight())
    if scrollFrame:GetVerticalScroll() > maximumScroll then
        scrollFrame:SetVerticalScroll(maximumScroll)
    end

    refreshVisibleRows(GetTime())
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
    showSimpleTooltip(self, L.WINDOW_LOCKED_TOOLTIP)
end)
lockIndicator:SetScript("OnLeave", hideOwnedTooltip)

resizeHandle:SetScript("OnEnter", function(self)
    showSimpleTooltip(self, L.WINDOW_RESIZE_TOOLTIP)
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

-- Pure decision function (no frame/DB access) so /rpw selftest can exercise
-- every combination without touching the real window, RPWatcherDB, or
-- combat state. combatSuppressed always wins: a combat-hidden window never
-- shows regardless of the other three inputs.
local function computeActualVisibility(manuallyShown, autoHideEnabled, watcherCount, isCombatSuppressed)
    if isCombatSuppressed then
        return false
    end
    return manuallyShown and (not autoHideEnabled or watcherCount > 0) and true or false
end

function UI:UpdateActualVisibility()
    local shouldShow = computeActualVisibility(
        self:IsManuallyShown(),
        RPWatcher.Settings:IsAutoHideEnabled(),
        watcherCount,
        combatSuppressed
    )

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

-- Only PLAYER_REGEN_DISABLED/ENABLED (below) and OnSettingChanged("hideInCombat")
-- call this; it never runs on a ticker or OnUpdate.
function UI:SetCombatSuppressed(shouldSuppress)
    shouldSuppress = shouldSuppress and true or false
    if combatSuppressed == shouldSuppress then
        return
    end
    combatSuppressed = shouldSuppress
    self:UpdateActualVisibility()
end

-- Bounded, event-triggered sync (addon load, option toggled) rather than a
-- permanent poll, per AGENTS.md: UnitAffectingCombat("player") is read here
-- and nowhere else in this file.
function UI:SyncCombatState()
    local shouldSuppress = RPWatcher.Settings:IsHideInCombatEnabled() and UnitAffectingCombat("player")
    combatSuppressed = shouldSuppress and true or false
    self:UpdateActualVisibility()
end

-- Dedicated frame, separate from the visible window's OnDragStart/OnDragStop
-- scripts: PLAYER_REGEN_DISABLED only actually suppresses when hideInCombat
-- is enabled; PLAYER_REGEN_ENABLED always clears the suppression.
local combatEventFrame = CreateFrame("Frame")
combatEventFrame:RegisterEvent("PLAYER_REGEN_DISABLED")
combatEventFrame:RegisterEvent("PLAYER_REGEN_ENABLED")
combatEventFrame:SetScript("OnEvent", function(_, event)
    if event == "PLAYER_REGEN_DISABLED" then
        UI:SetCombatSuppressed(RPWatcher.Settings and RPWatcher.Settings:IsHideInCombatEnabled())
    elseif event == "PLAYER_REGEN_ENABLED" then
        UI:SetCombatSuppressed(false)
    end
end)

function UI:Initialize()
    if RPWatcher.Scanner then
        RPWatcher.Scanner:SetChangeCallback(function()
            UI:RefreshWatcherList()
        end)
    end
    self:SyncCombatState()
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

    activeSummarySlot.label:SetText(RPWatcher.Localization:Format("SUMMARY_ACTIVE", activeCount))
    inactiveSummarySlot.label:SetText(RPWatcher.Localization:Format("SUMMARY_PREVIOUS", inactiveCount))
    unknownSummarySlot.label:SetText(RPWatcher.Localization:Format("SUMMARY_UNKNOWN", unknownCount))
    updateSummarySlotWidth(activeSummarySlot)
    updateSummarySlotWidth(inactiveSummarySlot)
    updateSummarySlotWidth(unknownSummarySlot)

    -- Hotfix 1.1.1: refresh the actual window/list snapshot BEFORE toggling
    -- emptyState/scrollFrame visibility below. scrollFrame:SetShown(true) can
    -- synchronously fire OnSizeChanged -> refreshVisibleRows while still
    -- inside this function (e.g. via a synchronous TRP3 profile callback
    -- during watcher creation); by this point currentWatchers must already be
    -- current and listNeedsRefresh already false, or that handler must safely
    -- decline to render (see refreshVisibleRows' own guard).
    self:UpdateActualVisibility()

    emptyState:SetShown(watcherCount == 0)
    scrollFrame:SetShown(watcherCount > 0)
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
    elseif settingName == "hideInCombat" then
        self:SyncCombatState()
    elseif settingName == "unknownRetentionSeconds" then
        return
    elseif settingName == "showMinimapButton" then
        return
    else
        self:ApplySettings()
    end
end

function UI:RestoreState()
    self:ApplySettings()
end

-- 1.2.0 selftest for /rpw selftest. computeActualVisibility is pure (no
-- frame/DB/combat access), so these cases run without touching the real
-- window, RPWatcherDB, or actual combat state. Case numbers refer to the
-- 1.2.0 task's "Combat" list; case 18 (Scanner/Timer keep running in combat)
-- is a static guarantee -- no combat check was added to Scanner.lua -- and
-- isn't runtime-tested here.
function UI:RunSelfTest()
    local results = {}
    local function check(nameKey, actual, expected)
        results[#results + 1] = {
            name = L[nameKey],
            passed = actual == expected,
            detail = RPWatcher.Localization:Format("SELFTEST_DETAIL_EXPECTED", tostring(actual), tostring(expected)),
        }
    end

    check("SELFTEST_COMBAT_1",
        computeActualVisibility(true, false, 1, true), false)
    check("SELFTEST_COMBAT_2",
        computeActualVisibility(false, false, 1, false), false)
    check("SELFTEST_COMBAT_3",
        computeActualVisibility(true, false, 1, false), true)
    check("SELFTEST_COMBAT_4",
        computeActualVisibility(false, false, 0, false), false)
    check("SELFTEST_COMBAT_5",
        computeActualVisibility(true, true, 0, false), false)
    check("SELFTEST_COMBAT_6",
        computeActualVisibility(true, true, 0, true), false)
    check("SELFTEST_UI_STRATA",
        frame:GetFrameStrata(), "LOW")

    return results
end

-- Public module surface. The main frame remains private.
UI.ListArea = listArea
UI.EmptyHint = emptyHint
