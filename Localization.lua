local _, RPWatcher = ...

local Localization = {}
RPWatcher.Localization = Localization

-- Extracts string.format conversion specifiers from a template, in order,
-- as their conversion letter only (e.g. "d", "s", "f"). A literal "%%" never
-- matches here because the pattern requires a letter immediately after the
-- optional flags/width/precision, and "%" is not a letter -- so escaped
-- percent signs are correctly never counted as placeholders.
local function extractPlaceholders(text)
    local placeholders = {}
    if type(text) ~= "string" then
        return placeholders
    end
    for conversion in text:gmatch("%%[%-%+ #0]*%d*%.?%d*(%a)") do
        placeholders[#placeholders + 1] = conversion
    end
    return placeholders
end

local function placeholdersEqual(a, b)
    if #a ~= #b then
        return false
    end
    for index = 1, #a do
        if a[index] ~= b[index] then
            return false
        end
    end
    return true
end

-- Copies the full enUS base, then overlays the requested locale's known
-- keys on top. enGB normalizes to enUS; any locale without its own overlay
-- table (including one that is simply unknown) stays pure English. A missing
-- or empty overlay value never overwrites the English base, so partially
-- translated locales still return usable text for every key.
function Localization:BuildCatalog(locale)
    local base = RPWatcher.LocaleData and RPWatcher.LocaleData.enUS or {}
    local catalog = {}
    for key, value in pairs(base) do
        catalog[key] = value
    end

    local normalized = locale
    if normalized == "enGB" then
        normalized = "enUS"
    end

    if normalized ~= "enUS" then
        local overlay = RPWatcher.LocaleData and RPWatcher.LocaleData[normalized]
        if type(overlay) == "table" then
            for key, value in pairs(overlay) do
                if type(value) == "string" and value ~= "" then
                    catalog[key] = value
                end
            end
        end
    end

    return catalog
end

-- deDE -> German; enUS, enGB, and every other (including not yet supported)
-- client locale -> English.
function Localization:NormalizeLocale(locale)
    if locale == "deDE" then
        return "deDE"
    end
    return "enUS"
end

function Localization:GetActiveLocale()
    return self:NormalizeLocale(GetLocale())
end

-- A key missing even from the active catalog falls back to the key name
-- itself: a recognizable, harmless stand-in rather than a nil string or a
-- Lua error.
function Localization:Get(key)
    local value = RPWatcher.L and RPWatcher.L[key]
    if type(value) == "string" then
        return value
    end
    return key
end

-- Safe string.format wrapper: never throws on a malformed template or
-- mismatched arguments. On failure it falls back to the raw template text
-- (still readable, just unformatted) instead of crashing the addon.
function Localization:Format(key, ...)
    local template = self:Get(key)
    if select("#", ...) == 0 then
        return template
    end

    local ok, result = pcall(string.format, template, ...)
    if ok then
        return result
    end
    return template
end

function Localization:FormatDuration(seconds)
    seconds = math.max(0, math.floor(seconds or 0))
    if seconds < 60 then
        return self:Format("DURATION_SECONDS", seconds)
    end

    local minutes = math.floor(seconds / 60)
    local remainingSeconds = seconds % 60
    if minutes < 60 then
        if remainingSeconds > 0 then
            return self:Format("DURATION_MINUTES_SECONDS", minutes, remainingSeconds)
        end
        return self:Format("DURATION_MINUTES", minutes)
    end

    local hours = math.floor(minutes / 60)
    local remainingMinutes = minutes % 60
    if remainingMinutes > 0 then
        return self:Format("DURATION_HOURS_MINUTES", hours, remainingMinutes)
    end
    return self:Format("DURATION_HOURS", hours)
end

-- Builds the active catalog immediately at file load, before Core.lua or any
-- other module runs -- see the TOC load order. RPWatcher.L is created exactly
-- once here and must never be replaced by a new table afterward (modules are
-- free to keep a local `local L = RPWatcher.L` reference).
RPWatcher.L = Localization:BuildCatalog(Localization:GetActiveLocale())

-- Non-persistent, read-only checks for /rpw selftest. Never touches
-- RPWatcherDB, never replaces RPWatcher.L, and never changes the active UI
-- language.
function Localization:RunSelfTest()
    local results = {}
    local function check(nameKey, passed, detail)
        results[#results + 1] = {
            name = self:Get(nameKey),
            passed = passed and true or false,
            detail = detail,
        }
    end

    local enUS = RPWatcher.LocaleData and RPWatcher.LocaleData.enUS
    local deDE = RPWatcher.LocaleData and RPWatcher.LocaleData.deDE

    check("L_SELFTEST_ENUS_PRESENT", type(enUS) == "table")
    check("L_SELFTEST_DEDE_PRESENT", type(deDE) == "table")

    local enUSKeyCount = 0
    if type(enUS) == "table" then
        for _ in pairs(enUS) do
            enUSKeyCount = enUSKeyCount + 1
        end
    end
    check("L_SELFTEST_ENUS_KEYSET", enUSKeyCount >= 100, tostring(enUSKeyCount))

    local enUSNoNilKey, enUSNoEmptyValue = true, true
    if type(enUS) == "table" then
        for key, value in pairs(enUS) do
            if type(key) ~= "string" or key == "" then
                enUSNoNilKey = false
            end
            if type(value) ~= "string" or value == "" then
                enUSNoEmptyValue = false
            end
        end
    end
    check("L_SELFTEST_ENUS_NO_NIL_KEY", enUSNoNilKey)
    check("L_SELFTEST_ENUS_NO_EMPTY_VALUE", enUSNoEmptyValue)

    local deDENoNilKey, deDENoEmptyValue = true, true
    if type(deDE) == "table" then
        for key, value in pairs(deDE) do
            if type(key) ~= "string" or key == "" then
                deDENoNilKey = false
            end
            if type(value) ~= "string" or value == "" then
                deDENoEmptyValue = false
            end
        end
    end
    check("L_SELFTEST_DEDE_NO_NIL_KEY", deDENoNilKey)
    check("L_SELFTEST_DEDE_NO_EMPTY_VALUE", deDENoEmptyValue)

    local enUSKeysInDeDE, missingInDeDE = true, {}
    local deDEKeysInEnUS, extraInDeDE = true, {}
    if type(enUS) == "table" and type(deDE) == "table" then
        for key in pairs(enUS) do
            if deDE[key] == nil then
                enUSKeysInDeDE = false
                missingInDeDE[#missingInDeDE + 1] = key
            end
        end
        for key in pairs(deDE) do
            if enUS[key] == nil then
                deDEKeysInEnUS = false
                extraInDeDE[#extraInDeDE + 1] = key
            end
        end
    end
    check("L_SELFTEST_ENUS_KEYS_IN_DEDE", enUSKeysInDeDE, #missingInDeDE > 0 and table.concat(missingInDeDE, ", ") or nil)
    check("L_SELFTEST_DEDE_KEYS_IN_ENUS", deDEKeysInEnUS, #extraInDeDE > 0 and table.concat(extraInDeDE, ", ") or nil)
    check("L_SELFTEST_NO_STRAY_KEYS", enUSKeysInDeDE and deDEKeysInEnUS)

    local placeholdersOK, orderTypeOK, mismatchDetail = true, true, nil
    if type(enUS) == "table" and type(deDE) == "table" then
        for key, enValue in pairs(enUS) do
            local deValue = deDE[key]
            if type(deValue) == "string" then
                local enPlaceholders = extractPlaceholders(enValue)
                local dePlaceholders = extractPlaceholders(deValue)
                if #enPlaceholders ~= #dePlaceholders then
                    placeholdersOK = false
                    mismatchDetail = key
                elseif not placeholdersEqual(enPlaceholders, dePlaceholders) then
                    orderTypeOK = false
                    mismatchDetail = key
                end
            end
        end
    end
    check("L_SELFTEST_PLACEHOLDERS_MATCH", placeholdersOK, mismatchDetail)
    check("L_SELFTEST_PLACEHOLDER_ORDER", orderTypeOK, mismatchDetail)

    local escapedPlaceholders = extractPlaceholders("100%% done")
    check("L_SELFTEST_ESCAPED_PERCENT", #escapedPlaceholders == 0, tostring(#escapedPlaceholders))

    local enUSBuilt = self:BuildCatalog("enUS")
    local enGBBuilt = self:BuildCatalog("enGB")
    local deDEBuilt = self:BuildCatalog("deDE")
    local unknownBuilt = self:BuildCatalog("frFR")

    check("L_SELFTEST_BUILD_ENUS", type(enUS) == "table" and enUSBuilt.HELP_HEADER == enUS.HELP_HEADER)
    check("L_SELFTEST_BUILD_ENGB", type(enUS) == "table" and enGBBuilt.HELP_HEADER == enUS.HELP_HEADER)
    check("L_SELFTEST_BUILD_DEDE", type(deDE) == "table" and deDEBuilt.HELP_HEADER == deDE.HELP_HEADER)
    check("L_SELFTEST_BUILD_UNKNOWN", type(enUS) == "table" and unknownBuilt.HELP_HEADER == enUS.HELP_HEADER)

    local activeCatalogComplete = true
    if type(enUS) == "table" then
        for key in pairs(enUS) do
            if not RPWatcher.L or RPWatcher.L[key] == nil then
                activeCatalogComplete = false
            end
        end
    end
    check("L_SELFTEST_ACTIVE_CATALOG_COMPLETE", activeCatalogComplete)

    local durationSeconds = self:FormatDuration(5)
    local durationMinutes = self:FormatDuration(125)
    local durationHours = self:FormatDuration(7384)
    check("L_SELFTEST_FORMAT_DURATION",
        type(durationSeconds) == "string" and durationSeconds ~= ""
            and type(durationMinutes) == "string" and durationMinutes ~= ""
            and type(durationHours) == "string" and durationHours ~= "")

    local dbClean = true
    if type(RPWatcherDB) == "table"
        and (RPWatcherDB.locale ~= nil or RPWatcherDB.LocaleData ~= nil or RPWatcherDB.language ~= nil) then
        dbClean = false
    end
    check("L_SELFTEST_NO_DB_STORAGE", dbClean)

    return results
end
