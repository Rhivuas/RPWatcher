local _, RPWatcher = ...

local Theme = {}
RPWatcher.Theme = Theme

-- The palette follows the restrained dark surfaces and warm gold accents used
-- by current WoW dialogs and Total RP 3, while depending only on Blizzard's
-- confirmed WHITE8X8 texture and standard font objects.
Theme.colors = {
    background = { 0.035, 0.031, 0.040, 1.00 },
    titleBar = { 0.075, 0.062, 0.070, 1.00 },
    surface = { 0.022, 0.022, 0.028, 1.00 },
    surfaceAlternate = { 0.045, 0.041, 0.050, 1.00 },
    border = { 0.300, 0.255, 0.190, 1.00 },
    divider = { 0.190, 0.165, 0.145, 1.00 },
    accent = { 0.950, 0.720, 0.160, 1.00 },
    text = { 0.940, 0.910, 0.840, 1.00 },
    secondaryText = { 0.690, 0.675, 0.650, 1.00 },
    mutedText = { 0.500, 0.495, 0.500, 1.00 },
    active = { 0.320, 0.820, 0.420, 1.00 },
    inactive = { 0.560, 0.565, 0.590, 1.00 },
    unknown = { 0.850, 0.680, 0.280, 1.00 },
    activeRow = { 0.055, 0.105, 0.070, 0.92 },
    inactiveRow = { 0.040, 0.040, 0.047, 0.88 },
    unknownRow = { 0.075, 0.060, 0.040, 0.88 },
    hover = { 0.180, 0.135, 0.075, 0.62 },
    button = { 0.105, 0.085, 0.070, 0.96 },
    buttonHover = { 0.190, 0.135, 0.065, 1.00 },
    buttonPressed = { 0.075, 0.060, 0.052, 1.00 },
}

Theme.layout = {
    outerPadding = 10,
    innerPadding = 8,
    titleHeight = 28,
    statusHeight = 34,
    rowHeight = 30,
    rowGap = 2,
    profileButtonWidth = 52,
}

Theme.fonts = {
    display = "GameFontNormalHuge",
    title = "GameFontNormalLarge",
    body = "GameFontHighlight",
    label = "GameFontNormal",
    secondary = "GameFontHighlightSmall",
    small = "GameFontNormalSmall",
    muted = "GameFontDisableSmall",
}

Theme.texture = "Interface\\Buttons\\WHITE8X8"

local function unpackColor(color, alphaMultiplier)
    local alpha = color[4] or 1
    if alphaMultiplier then
        alpha = alpha * alphaMultiplier
    end
    return color[1], color[2], color[3], alpha
end

function Theme:SetTextureColor(texture, color, alphaMultiplier)
    if texture and color then
        texture:SetColorTexture(unpackColor(color, alphaMultiplier))
    end
end

function Theme:SetFontColor(fontString, color, alphaMultiplier)
    if fontString and color then
        fontString:SetTextColor(unpackColor(color, alphaMultiplier))
    end
end

function Theme:CreateColorTexture(parent, layer, color, alphaMultiplier)
    local texture = parent:CreateTexture(nil, layer or "BACKGROUND")
    self:SetTextureColor(texture, color, alphaMultiplier)
    return texture
end

function Theme:ApplyBackdrop(frame, backgroundColor, borderColor, backgroundAlpha)
    if not frame or type(frame.SetBackdrop) ~= "function" then
        return
    end

    frame:SetBackdrop({
        bgFile = self.texture,
        edgeFile = self.texture,
        edgeSize = 1,
    })

    local background = backgroundColor or self.colors.background
    local border = borderColor or self.colors.border
    frame:SetBackdropColor(unpackColor(background, backgroundAlpha))
    frame:SetBackdropBorderColor(unpackColor(border))
end

function Theme:SetBackdropBackground(frame, color, alphaMultiplier)
    if frame and type(frame.SetBackdropColor) == "function" then
        frame:SetBackdropColor(unpackColor(color, alphaMultiplier))
    end
end

function Theme:SetBackdropBorder(frame, color, alphaMultiplier)
    if frame and type(frame.SetBackdropBorderColor) == "function" then
        frame:SetBackdropBorderColor(unpackColor(color, alphaMultiplier))
    end
end

-- Status indicators (1.1.0 fix). The first ingame test confirmed the client's
-- bundled font renders "▲" (U+25B2) and "●" (U+25CF) as a missing-glyph
-- replacement box (a diamond with a question mark) rather than the intended
-- shapes, so no non-ASCII glyph is used for status anymore. Aktuell/Vorher
-- are real Frame/Texture objects; Unbekannt stays a plain ASCII "?" FontString,
-- which the same live test rendered correctly.
local STATUS_INDICATOR_SIZE = 16
local ARROW_ROW_COUNT = 7
local STATUS_ICON_TEXTURE = "Interface\\AddOns\\RPWatcher\\Media\\RPWatcherIcon"
-- Crop visually verified against release/assets/RPWatcherIcon_512.png: isolates
-- the eye lozenge, excluding the corner-bracket frame and the three status dots.
local EYE_TEXCOORD = { 0.15, 0.85, 0.28, 0.66 }

local function buildEyeIndicator(parent, size)
    local eye = parent:CreateTexture(nil, "ARTWORK")
    eye:SetSize(size, size)
    eye:SetPoint("CENTER")
    eye:SetTexture(STATUS_ICON_TEXTURE)
    eye:SetTexCoord(EYE_TEXCOORD[1], EYE_TEXCOORD[2], EYE_TEXCOORD[3], EYE_TEXCOORD[4])
    return eye
end

-- Compact left-pointing "history" arrow, built from stacked bars of the
-- project's already-confirmed solid-color WHITE8X8 texture (see
-- Theme:CreateColorTexture below) instead of a Unicode arrow glyph or a
-- rotated texture.
local function buildArrowIndicator(parent, size)
    local arrow = CreateFrame("Frame", nil, parent)
    arrow:SetAllPoints(parent)
    arrow.bars = {}

    local rowHeight = size / ARROW_ROW_COUNT
    local mid = (ARROW_ROW_COUNT - 1) / 2
    for rowIndex = 0, ARROW_ROW_COUNT - 1 do
        local distance = math.abs(rowIndex - mid)
        local inset = mid > 0 and (distance / mid) * (size - 4) or 0
        local bar = Theme:CreateColorTexture(arrow, "ARTWORK", Theme.colors.inactive)
        bar:SetPoint("TOPLEFT", arrow, "TOPLEFT", inset, -(rowIndex * rowHeight))
        bar:SetSize(math.max(2, size - inset), math.max(1, rowHeight - 1))
        arrow.bars[#arrow.bars + 1] = bar
    end

    return arrow
end

-- Creates one reusable status indicator. Callers create this once per row (or
-- once per status-summary slot) and call SetStatusIndicator on status change;
-- no child frames are created on refresh.
function Theme:CreateStatusIndicator(parent, size)
    size = size or STATUS_INDICATOR_SIZE

    local indicator = CreateFrame("Frame", nil, parent)
    indicator:SetSize(size, size)

    indicator.eye = buildEyeIndicator(indicator, size)
    indicator.arrow = buildArrowIndicator(indicator, size)

    indicator.unknown = indicator:CreateFontString(nil, "OVERLAY", self.fonts.title)
    indicator.unknown:SetAllPoints()
    indicator.unknown:SetJustifyH("CENTER")
    indicator.unknown:SetJustifyV("MIDDLE")
    indicator.unknown:SetText("?")

    indicator.eye:Hide()
    indicator.arrow:Hide()
    indicator.unknown:Hide()

    return indicator
end

-- status is one of "active", "inactive", "unknown" (same keys already used by
-- Theme.colors). Hides all variants first, then shows exactly one.
function Theme:SetStatusIndicator(indicator, status)
    if not indicator then
        return
    end

    indicator.eye:Hide()
    indicator.arrow:Hide()
    indicator.unknown:Hide()

    if status == "active" then
        local color = self.colors.active
        indicator.eye:SetVertexColor(color[1], color[2], color[3], color[4] or 1)
        indicator.eye:Show()
    elseif status == "inactive" then
        for _, bar in ipairs(indicator.arrow.bars) do
            self:SetTextureColor(bar, self.colors.inactive)
        end
        indicator.arrow:Show()
    else
        self:SetFontColor(indicator.unknown, self.colors.unknown)
        indicator.unknown:Show()
    end
end
