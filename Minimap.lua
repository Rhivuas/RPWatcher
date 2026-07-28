local _, RPWatcher = ...

-- Minimap button module for RPWatcher, added in 1.1.0. Encapsulated on purpose
-- (see AGENTS.md): quick-access UI only, no scanner or TRP3 logic here, no
-- external library (Ace3/LibStub/LibDBIcon/LibDataBroker).
--
-- Texture and technique confirmation: no local Retail client install was
-- available to inspect FrameXML directly. Instead this module reuses the
-- exact numeric texture IDs and positioning technique (angle-based position,
-- GetMinimapShape-aware clamping, transient drag OnUpdate) found in the
-- locally available totalRP3 3.3.7 reference sources, specifically its
-- bundled LibDBIcon-1.0 (Libs/LibDBIcon-1.0/LibDBIcon-1.0.lua) and TRP3's own
-- UI/Main.xml. Only the confirmed technique and Blizzard texture file IDs are
-- reused here; no TRP3 code, art asset, or file was copied. RPWatcher's own
-- icon (Media/RPWatcherIcon.tga) is used for the button face.
--
-- 1.1.0 fix: this module used to declare its own module table as
-- `local Minimap = {}`, which shadowed the real global WoW minimap frame
-- (`_G.Minimap`) for the rest of the file. Every subsequent "Minimap:GetWidth()"
-- etc. call silently resolved against the empty module table instead of the
-- real frame, so isMinimapAvailable() always returned false, createButton()
-- always bailed out silently, and no button (and no error) ever appeared.
-- The module table is now named MinimapModule; the real frame is always
-- fetched through getMinimapFrame() and never aliased to a bare "Minimap".
local MinimapModule = {}
RPWatcher.Minimap = MinimapModule

local L = RPWatcher.L

local BORDER_TEXTURE = 136430    -- Interface\Minimap\MiniMap-TrackingBorder
local BACKGROUND_TEXTURE = 136467 -- Interface\Minimap\UI-Minimap-Background
local HIGHLIGHT_TEXTURE = 136477  -- Interface\Minimap\UI-Minimap-ZoomButton-Highlight
local ICON_TEXTURE = "Interface\\AddOns\\RPWatcher\\Media\\RPWatcherIcon"
local BUTTON_SIZE = 31
local DEFAULT_ANGLE = 225
local RADIUS_MARGIN = 5
local RETRY_EVENT = "PLAYER_ENTERING_WORLD"

local button
local retryFrame

-- Always fetches the real global minimap frame; never assign this to a local
-- named "Minimap" (see the fix note above) so it can't shadow _G.Minimap.
local function getMinimapFrame()
    local frame = _G.Minimap
    if not frame or type(frame.GetWidth) ~= "function" then
        return nil
    end
    return frame
end

-- Confirmed technique: angle-based position around the minimap, clamped to
-- the circular edge for a round minimap and defensively to the inscribed
-- square for any other GetMinimapShape() result (no external shape library).
local function computeOffset(minimapFrame, angleDegrees)
    local radians = math.rad(angleDegrees or DEFAULT_ANGLE)
    local x, y = math.cos(radians), math.sin(radians)
    local width = (minimapFrame:GetWidth() / 2) + RADIUS_MARGIN
    local height = (minimapFrame:GetHeight() / 2) + RADIUS_MARGIN
    local shape = (type(GetMinimapShape) == "function") and GetMinimapShape() or "ROUND"

    if shape == "ROUND" then
        return x * width, y * height
    end

    local diagonalWidth = math.sqrt(2 * width ^ 2) - 10
    local diagonalHeight = math.sqrt(2 * height ^ 2) - 10
    x = math.max(-width, math.min(x * diagonalWidth, width))
    y = math.max(-height, math.min(y * diagonalHeight, height))
    return x, y
end

local function updateButtonPosition()
    if not button then
        return
    end
    local minimapFrame = getMinimapFrame()
    if not minimapFrame then
        return
    end

    local angle = RPWatcher.Settings and RPWatcher.Settings:GetMinimapAngle() or DEFAULT_ANGLE
    local x, y = computeOffset(minimapFrame, angle)
    button:ClearAllPoints()
    button:SetPoint("CENTER", minimapFrame, "CENTER", x, y)
end

local function onDragUpdate(self)
    local minimapFrame = getMinimapFrame()
    if not minimapFrame then
        return
    end

    local centerX, centerY = minimapFrame:GetCenter()
    if not centerX then
        return
    end

    local cursorX, cursorY = GetCursorPosition()
    local scale = minimapFrame:GetEffectiveScale()
    cursorX, cursorY = cursorX / scale, cursorY / scale

    local angle = math.deg(math.atan2(cursorY - centerY, cursorX - centerX)) % 360
    if RPWatcher.Settings then
        RPWatcher.Settings:SetMinimapAngle(angle)
    end
    updateButtonPosition()
end

local function onDragStart(self)
    self:LockHighlight()
    self:SetScript("OnUpdate", onDragUpdate)
end

local function onDragStop(self)
    self:SetScript("OnUpdate", nil)
    self:UnlockHighlight()
    updateButtonPosition()
end

local function onClick(self, mouseButton)
    if mouseButton == "LeftButton" then
        if RPWatcher.UI then
            RPWatcher.UI:ToggleManualVisibility()
        end
    elseif mouseButton == "RightButton" then
        if not RPWatcher.Settings or not RPWatcher.Settings:OpenOptions() then
            print("|cff66ccffRPWatcher|r: " .. L.CHAT_OPTIONS_OPEN_FAILED)
        end
    end
end

local function onEnter(self)
    GameTooltip:SetOwner(self, "ANCHOR_LEFT")
    GameTooltip:AddLine("RPWatcher")
    GameTooltip:AddLine(L.MINIMAP_TOOLTIP_LEFT_CLICK, 0.9, 0.9, 0.9, true)
    GameTooltip:AddLine(L.MINIMAP_TOOLTIP_RIGHT_CLICK, 0.9, 0.9, 0.9, true)
    GameTooltip:AddLine(L.MINIMAP_TOOLTIP_DRAG, 0.9, 0.9, 0.9, true)
    GameTooltip:Show()
end

local function onLeave(self)
    if GameTooltip:IsOwned(self) then
        GameTooltip:Hide()
    end
end

local function createButton()
    if button then
        return button
    end

    local minimapFrame = getMinimapFrame()
    if not minimapFrame then
        return nil
    end

    button = CreateFrame("Button", "RPWatcherMinimapButton", minimapFrame)
    button:SetSize(BUTTON_SIZE, BUTTON_SIZE)
    button:SetFrameStrata("MEDIUM")
    button:SetFrameLevel(minimapFrame:GetFrameLevel() + 5)
    button:RegisterForDrag("LeftButton")
    button:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    button:SetHighlightTexture(HIGHLIGHT_TEXTURE)

    local background = button:CreateTexture(nil, "BACKGROUND")
    background:SetTexture(BACKGROUND_TEXTURE)
    background:SetSize(24, 24)
    background:SetPoint("CENTER", 0, 0)
    button.background = background

    local icon = button:CreateTexture(nil, "ARTWORK")
    icon:SetTexture(ICON_TEXTURE)
    icon:SetSize(18, 18)
    icon:SetPoint("CENTER")
    button.icon = icon

    local border = button:CreateTexture(nil, "OVERLAY")
    border:SetTexture(BORDER_TEXTURE)
    border:SetSize(50, 50)
    border:SetPoint("TOPLEFT", 0, 0)
    button.border = border

    button:SetScript("OnDragStart", onDragStart)
    button:SetScript("OnDragStop", onDragStop)
    button:SetScript("OnClick", onClick)
    button:SetScript("OnEnter", onEnter)
    button:SetScript("OnLeave", onLeave)

    return button
end

local function applyVisibility()
    if not button or not RPWatcher.Settings then
        return
    end
    button:SetShown(RPWatcher.Settings:IsMinimapButtonEnabled() and true or false)
end

-- Defensive one-shot retry: only used if the real minimap frame is not yet
-- available on the first Initialize() call. Registers a single event, creates
-- the button on the next firing, then unregisters itself. No ticker, no
-- OnUpdate, and createButton()'s own "if button then return button end" guard
-- prevents a duplicate button even if this somehow fired more than once.
local function scheduleRetry()
    if retryFrame then
        return
    end
    retryFrame = CreateFrame("Frame")
    retryFrame:RegisterEvent(RETRY_EVENT)
    retryFrame:SetScript("OnEvent", function(self)
        self:UnregisterEvent(RETRY_EVENT)
        createButton()
        if button then
            updateButtonPosition()
            applyVisibility()
        end
    end)
end

function MinimapModule:Initialize()
    if not RPWatcher.Settings then
        return
    end

    createButton()
    if not button then
        scheduleRetry()
        return
    end

    updateButtonPosition()
    applyVisibility()
end

function MinimapModule:OnSettingChanged(settingName)
    if settingName ~= "showMinimapButton" then
        return
    end

    if not button then
        if RPWatcher.Settings and RPWatcher.Settings:IsMinimapButtonEnabled() then
            createButton()
            if button then
                updateButtonPosition()
            end
        end
        return
    end

    updateButtonPosition()
    applyVisibility()
end
