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
    titleHeight = 38,
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
