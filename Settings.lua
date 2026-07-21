local _, RPWatcher = ...

local SettingsModule = {}
RPWatcher.Settings = SettingsModule

SettingsModule.SCHEMA_VERSION = 2

local MIN_WIDTH = 320
local MIN_HEIGHT = 170
local MAX_WIDTH = 750
local MAX_HEIGHT = 700
local RETENTION_VALUES = { 15, 30, 60, 120, 300 }

local DEFAULTS = {
    schemaVersion = SettingsModule.SCHEMA_VERSION,
    window = {
        shown = true,
        point = "CENTER",
        relativePoint = "CENTER",
        x = 0,
        y = 0,
        width = 430,
        height = 260,
        scale = 1,
        backgroundAlpha = 0.90,
        locked = false,
    },
    unknownRetentionSeconds = 60,
    autoHideWhenEmpty = false,
    showTRP3ProfileButton = true,
}

local VALID_POINTS = {
    TOPLEFT = true,
    TOP = true,
    TOPRIGHT = true,
    LEFT = true,
    CENTER = true,
    RIGHT = true,
    BOTTOMLEFT = true,
    BOTTOM = true,
    BOTTOMRIGHT = true,
}

local optionsPanel
local optionsCategory
local panelControls = {}
local refreshingPanel = false

local function clamp(value, minimum, maximum)
    return math.max(minimum, math.min(maximum, value))
end

local function isFiniteNumber(value)
    return type(value) == "number" and value == value and value > -math.huge and value < math.huge
end

local function roundToStep(value, step)
    return math.floor((value / step) + 0.5) * step
end

local function copyWindowDefaults(target)
    for key, value in pairs(DEFAULTS.window) do
        target[key] = value
    end
end

local function isAllowedRetention(value)
    for index = 1, #RETENTION_VALUES do
        if RETENTION_VALUES[index] == value then
            return true
        end
    end
    return false
end

local function validateDatabase(database)
    if type(database.window) ~= "table" then
        database.window = {}
    end

    local window = database.window
    window.shown = type(window.shown) == "boolean" and window.shown or DEFAULTS.window.shown
    window.point = VALID_POINTS[window.point] and window.point or DEFAULTS.window.point
    window.relativePoint = VALID_POINTS[window.relativePoint] and window.relativePoint or DEFAULTS.window.relativePoint
    window.x = isFiniteNumber(window.x) and clamp(window.x, -10000, 10000) or DEFAULTS.window.x
    window.y = isFiniteNumber(window.y) and clamp(window.y, -10000, 10000) or DEFAULTS.window.y
    window.width = isFiniteNumber(window.width) and clamp(window.width, MIN_WIDTH, MAX_WIDTH) or DEFAULTS.window.width
    window.height = isFiniteNumber(window.height) and clamp(window.height, MIN_HEIGHT, MAX_HEIGHT) or DEFAULTS.window.height
    window.scale = isFiniteNumber(window.scale) and clamp(roundToStep(window.scale, 0.05), 0.80, 1.30) or DEFAULTS.window.scale
    window.backgroundAlpha = isFiniteNumber(window.backgroundAlpha) and clamp(window.backgroundAlpha, 0.50, 1.00) or DEFAULTS.window.backgroundAlpha
    window.locked = type(window.locked) == "boolean" and window.locked or DEFAULTS.window.locked

    database.unknownRetentionSeconds = isAllowedRetention(database.unknownRetentionSeconds)
        and database.unknownRetentionSeconds or DEFAULTS.unknownRetentionSeconds
    database.autoHideWhenEmpty = type(database.autoHideWhenEmpty) == "boolean"
        and database.autoHideWhenEmpty or DEFAULTS.autoHideWhenEmpty
    database.showTRP3ProfileButton = type(database.showTRP3ProfileButton) == "boolean"
        and database.showTRP3ProfileButton or DEFAULTS.showTRP3ProfileButton
    database.schemaVersion = SettingsModule.SCHEMA_VERSION
end

local function notifySettingChanged(settingName)
    if RPWatcher.UI and RPWatcher.UI.OnSettingChanged then
        RPWatcher.UI:OnSettingChanged(settingName)
    end
end

local function createCheckbox(parent, label, x, y, onClick)
    local checkbox = CreateFrame("CheckButton", nil, parent, "UICheckButtonTemplate")
    checkbox:SetPoint("TOPLEFT", x, y)
    checkbox:SetSize(26, 26)

    local text = checkbox:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    text:SetPoint("LEFT", checkbox, "RIGHT", 4, 0)
    text:SetText(label)
    checkbox.label = text
    checkbox:SetScript("OnClick", onClick)
    return checkbox
end

local function createSlider(parent, frameName, label, x, y, minimum, maximum, step, onValueChanged)
    local labelText = parent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    labelText:SetPoint("TOPLEFT", x, y)
    labelText:SetText(label)

    local valueText = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    valueText:SetPoint("LEFT", labelText, "RIGHT", 8, 0)

    local slider = CreateFrame("Slider", frameName, parent, "OptionsSliderTemplate")
    slider:SetPoint("TOPLEFT", labelText, "BOTTOMLEFT", 4, -12)
    slider:SetWidth(260)
    slider:SetMinMaxValues(minimum, maximum)
    slider:SetValueStep(step)
    slider:SetObeyStepOnDrag(true)
    slider:SetScript("OnValueChanged", onValueChanged)
    slider.valueText = valueText
    _G[frameName .. "Low"]:SetText(("%.2f"):format(minimum))
    _G[frameName .. "High"]:SetText(("%.2f"):format(maximum))
    _G[frameName .. "Text"]:SetText("")
    return slider
end

local function refreshOptionsPanel()
    if not optionsPanel then
        return
    end

    refreshingPanel = true
    panelControls.locked:SetChecked(SettingsModule:IsWindowLocked())
    panelControls.scale:SetValue(SettingsModule:GetWindowScale())
    panelControls.scale.valueText:SetText(("%.2f"):format(SettingsModule:GetWindowScale()))
    panelControls.alpha:SetValue(SettingsModule:GetBackgroundAlpha())
    panelControls.alpha.valueText:SetText(("%d %%"):format(math.floor(SettingsModule:GetBackgroundAlpha() * 100 + 0.5)))
    panelControls.retention:SetText(SettingsModule:GetUnknownRetentionSeconds() .. " Sekunden")
    panelControls.autoHide:SetChecked(SettingsModule:IsAutoHideEnabled())
    panelControls.profileButton:SetChecked(SettingsModule:IsProfileButtonEnabled())
    refreshingPanel = false
end

local function registerOptionsPanel()
    if optionsPanel then
        return
    end

    optionsPanel = CreateFrame("Frame", nil, UIParent)
    optionsPanel.name = "RPWatcher"

    local title = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormalHuge")
    title:SetPoint("TOPLEFT", 24, -24)
    title:SetText("RPWatcher")

    local description = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    description:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -10)
    description:SetText("Fenster und Darstellung konfigurieren.")

    panelControls.locked = createCheckbox(optionsPanel, "Fenster sperren", 20, -82, function(self)
        if not refreshingPanel then
            SettingsModule:SetWindowLocked(self:GetChecked())
        end
    end)

    panelControls.scale = createSlider(optionsPanel, "RPWatcherWindowScaleSlider", "Fensterskalierung", 24, -132, 0.80, 1.30, 0.05, function(self, value)
        value = roundToStep(value, 0.05)
        self.valueText:SetText(("%.2f"):format(value))
        if not refreshingPanel then
            SettingsModule:SetWindowScale(value)
        end
    end)

    panelControls.alpha = createSlider(optionsPanel, "RPWatcherBackgroundAlphaSlider", "Hintergrundtransparenz", 24, -205, 0.50, 1.00, 0.05, function(self, value)
        value = roundToStep(value, 0.05)
        self.valueText:SetText(("%d %%"):format(math.floor(value * 100 + 0.5)))
        if not refreshingPanel then
            SettingsModule:SetBackgroundAlpha(value)
        end
    end)

    local retentionLabel = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    retentionLabel:SetPoint("TOPLEFT", 24, -278)
    retentionLabel:SetText("Unbekannte Watcher behalten")

    panelControls.retention = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    panelControls.retention:SetPoint("TOPLEFT", retentionLabel, "BOTTOMLEFT", 0, -7)
    panelControls.retention:SetSize(150, 24)
    panelControls.retention:SetScript("OnClick", function()
        local current = SettingsModule:GetUnknownRetentionSeconds()
        local nextValue = RETENTION_VALUES[1]
        for index = 1, #RETENTION_VALUES do
            if RETENTION_VALUES[index] == current then
                nextValue = RETENTION_VALUES[(index % #RETENTION_VALUES) + 1]
                break
            end
        end
        SettingsModule:SetUnknownRetentionSeconds(nextValue)
        refreshOptionsPanel()
    end)

    local retentionHint = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    retentionHint:SetPoint("LEFT", panelControls.retention, "RIGHT", 10, 0)
    retentionHint:SetText("Klicken, um 15 / 30 / 60 / 120 / 300 Sekunden zu wählen.")

    panelControls.autoHide = createCheckbox(optionsPanel, "Fenster ausblenden, wenn die Liste leer ist", 20, -351, function(self)
        if not refreshingPanel then
            SettingsModule:SetAutoHideEnabled(self:GetChecked())
        end
    end)

    panelControls.profileButton = createCheckbox(optionsPanel, "TRP3-Profilbutton anzeigen", 20, -391, function(self)
        if not refreshingPanel then
            SettingsModule:SetProfileButtonEnabled(self:GetChecked())
        end
    end)

    panelControls.reset = CreateFrame("Button", nil, optionsPanel, "UIPanelButtonTemplate")
    panelControls.reset:SetPoint("TOPLEFT", 24, -447)
    panelControls.reset:SetSize(180, 26)
    panelControls.reset:SetText("Fenster zurücksetzen")
    panelControls.reset:SetScript("OnClick", function()
        SettingsModule:ResetWindowSettings()
        refreshOptionsPanel()
        print("|cff66ccffRPWatcher|r: Fensterposition und Darstellung wurden zurückgesetzt.")
    end)

    local resetHint = optionsPanel:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    resetHint:SetPoint("TOPLEFT", panelControls.reset, "BOTTOMLEFT", 0, -6)
    resetHint:SetText("Watcher, Sichtbarkeit, Auto-Ausblendung, Aufbewahrung und Profilbutton bleiben erhalten.")

    optionsPanel:SetScript("OnShow", refreshOptionsPanel)

    if type(Settings) == "table"
        and type(Settings.RegisterCanvasLayoutCategory) == "function"
        and type(Settings.RegisterAddOnCategory) == "function" then
        optionsCategory = Settings.RegisterCanvasLayoutCategory(optionsPanel, optionsPanel.name)
        Settings.RegisterAddOnCategory(optionsCategory)
    end
end

function SettingsModule:Initialize()
    if type(RPWatcherDB) ~= "table" then
        RPWatcherDB = {}
    end
    validateDatabase(RPWatcherDB)

    registerOptionsPanel()
end

function SettingsModule:GetWindowState()
    return RPWatcherDB and RPWatcherDB.window
end

function SettingsModule:IsWindowManuallyShown()
    local window = self:GetWindowState()
    return window and window.shown ~= false or false
end

function SettingsModule:SetWindowManuallyShown(isShown)
    self:GetWindowState().shown = isShown and true or false
    notifySettingChanged("visibility")
end

function SettingsModule:SaveWindowPosition(point, relativePoint, x, y)
    local window = self:GetWindowState()
    window.point = VALID_POINTS[point] and point or DEFAULTS.window.point
    window.relativePoint = VALID_POINTS[relativePoint] and relativePoint or DEFAULTS.window.relativePoint
    window.x = isFiniteNumber(x) and clamp(x, -10000, 10000) or DEFAULTS.window.x
    window.y = isFiniteNumber(y) and clamp(y, -10000, 10000) or DEFAULTS.window.y
end

function SettingsModule:SaveWindowSize(width, height)
    local window = self:GetWindowState()
    window.width = isFiniteNumber(width) and clamp(width, MIN_WIDTH, MAX_WIDTH) or DEFAULTS.window.width
    window.height = isFiniteNumber(height) and clamp(height, MIN_HEIGHT, MAX_HEIGHT) or DEFAULTS.window.height
end

function SettingsModule:IsWindowLocked()
    return self:GetWindowState().locked
end

function SettingsModule:SetWindowLocked(isLocked)
    self:GetWindowState().locked = isLocked and true or false
    notifySettingChanged("locked")
    refreshOptionsPanel()
end

function SettingsModule:GetWindowScale()
    return self:GetWindowState().scale
end

function SettingsModule:SetWindowScale(value)
    if not isFiniteNumber(value) then
        return false
    end
    self:GetWindowState().scale = clamp(roundToStep(value, 0.05), 0.80, 1.30)
    notifySettingChanged("scale")
    return true
end

function SettingsModule:GetBackgroundAlpha()
    return self:GetWindowState().backgroundAlpha
end

function SettingsModule:SetBackgroundAlpha(value)
    if not isFiniteNumber(value) then
        return false
    end
    self:GetWindowState().backgroundAlpha = clamp(value, 0.50, 1.00)
    notifySettingChanged("backgroundAlpha")
    return true
end

function SettingsModule:GetUnknownRetentionSeconds()
    return RPWatcherDB.unknownRetentionSeconds
end

function SettingsModule:SetUnknownRetentionSeconds(value)
    if not isAllowedRetention(value) then
        return false
    end
    RPWatcherDB.unknownRetentionSeconds = value
    notifySettingChanged("unknownRetentionSeconds")
    return true
end

function SettingsModule:IsAutoHideEnabled()
    return RPWatcherDB.autoHideWhenEmpty
end

function SettingsModule:SetAutoHideEnabled(isEnabled)
    RPWatcherDB.autoHideWhenEmpty = isEnabled and true or false
    notifySettingChanged("autoHideWhenEmpty")
    refreshOptionsPanel()
end

function SettingsModule:IsProfileButtonEnabled()
    return RPWatcherDB.showTRP3ProfileButton
end

function SettingsModule:SetProfileButtonEnabled(isEnabled)
    RPWatcherDB.showTRP3ProfileButton = isEnabled and true or false
    notifySettingChanged("showTRP3ProfileButton")
    refreshOptionsPanel()
end

function SettingsModule:ResetWindowSettings()
    local shown = self:IsWindowManuallyShown()
    copyWindowDefaults(self:GetWindowState())
    self:GetWindowState().shown = shown
    notifySettingChanged("windowReset")
end

function SettingsModule:OpenOptions()
    if not optionsCategory or type(Settings) ~= "table" or type(Settings.OpenToCategory) ~= "function" then
        return false
    end

    local categoryID = type(optionsCategory.GetID) == "function" and optionsCategory:GetID() or optionsCategory.ID
    if categoryID == nil then
        return false
    end

    local opened = pcall(Settings.OpenToCategory, categoryID)
    return opened
end

function SettingsModule:GetWindowResizeBounds()
    return MIN_WIDTH, MIN_HEIGHT, MAX_WIDTH, MAX_HEIGHT
end
