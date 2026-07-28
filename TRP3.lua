local _, RPWatcher = ...

local TRP3 = {}
RPWatcher.TRP3 = TRP3

local L = RPWatcher.L

TRP3.PROFILE_REQUEST_COOLDOWN_SECONDS = 30
TRP3.GLOBAL_REQUEST_INTERVAL_SECONDS = 1

local lastRequestAtByGUID = {}
local characterIDByGUID = {}
local guidByCharacterID = {}
local requestQueue = {}
local queuedByGUID = {}
local requestQueueHead = 1
local requestQueueTail = 0
local lastGlobalRequestAt = -math.huge
local callbackRegistration
local initialized = false

local eventFrame = CreateFrame("Frame")

local function clearTable(target)
    for key in pairs(target) do
        target[key] = nil
    end
end

local function getAPI()
    return type(_G.TRP3_API) == "table" and _G.TRP3_API or nil
end

local function getAddon()
    return type(_G.TRP3_Addon) == "table" and _G.TRP3_Addon or nil
end

local function getFunction(parent, key)
    return type(parent) == "table" and type(parent[key]) == "function" and parent[key] or nil
end

local function safeCall(func, ...)
    if type(func) ~= "function" then
        return false, nil
    end
    return pcall(func, ...)
end

local function normalizeCharacterID(characterID)
    if type(characterID) ~= "string" or characterID == "" then
        return nil
    end
    return characterID:lower()
end

local function sanitizeRPName(value)
    if type(value) ~= "string" then
        return nil
    end

    value = value:gsub("|c%x%x%x%x%x%x%x%x", "")
    value = value:gsub("|r", "")
    value = value:gsub("|T.-|t", "")
    value = value:gsub("|A.-|a", "")
    value = value:gsub("|H.-|h", "")
    value = value:gsub("|h", "")
    value = value:gsub("[\r\n]+", " ")
    value = value:match("^%s*(.-)%s*$") or ""
    if value == "" then
        return nil
    end
    return value
end

local function rememberCharacterID(guid, characterID)
    local normalizedID = normalizeCharacterID(characterID)
    if type(guid) ~= "string" or not normalizedID then
        return
    end

    local previousID = characterIDByGUID[guid]
    if previousID then
        guidByCharacterID[normalizeCharacterID(previousID)] = nil
    end

    characterIDByGUID[guid] = characterID
    guidByCharacterID[normalizedID] = guid
end

local function resolveCharacterID(watcher)
    if not watcher or watcher.isTest then
        return nil
    end

    local api = getAPI()
    local utils = api and api.utils
    local strings = utils and utils.str
    local getUnitID = getFunction(strings, "getUnitID")
    local unitToken = watcher.unitToken

    if getUnitID and type(unitToken) == "string" and unitToken ~= "" and UnitExists(unitToken) then
        local ok, characterID = safeCall(getUnitID, unitToken)
        if ok and type(characterID) == "string" and characterID ~= "" then
            rememberCharacterID(watcher.guid, characterID)
        end
    end

    return characterIDByGUID[watcher.guid]
end

local function hasKnownProfile(api, characterID)
    local register = api and api.register
    local isUnitIDKnown = getFunction(register, "isUnitIDKnown")
    local hasProfile = getFunction(register, "hasProfile")
    if not isUnitIDKnown or not hasProfile or not characterID then
        return false
    end

    local knownOK, known = safeCall(isUnitIDKnown, characterID)
    if not knownOK or not known then
        return false
    end
    local profileOK, profileID = safeCall(hasProfile, characterID)
    return profileOK and profileID and true or false
end

local function unregisterDataCallback()
    if callbackRegistration and type(callbackRegistration.Unregister) == "function" then
        pcall(callbackRegistration.Unregister, callbackRegistration)
    end
    callbackRegistration = nil
end

local function registerDataCallback()
    unregisterDataCallback()

    local api = getAPI()
    local addon = getAddon()
    local registerCallback = api and getFunction(api, "RegisterCallback")
    local events = addon and addon.Events
    local eventName = type(events) == "table" and events.REGISTER_DATA_UPDATED
    if not registerCallback or type(eventName) ~= "string" then
        return false
    end

    local ok, registration = safeCall(registerCallback, addon, eventName, function(_, characterID)
        TRP3:HandleProfileDataUpdated(characterID)
    end)
    if ok and type(registration) == "table" then
        callbackRegistration = registration
        return true
    end
    return false
end

function TRP3:IsAddOnLoaded()
    return type(C_AddOns) == "table"
        and type(C_AddOns.IsAddOnLoaded) == "function"
        and C_AddOns.IsAddOnLoaded("totalRP3") and true or false
end

function TRP3:IsAPIAvailable()
    return getAPI() ~= nil
end

function TRP3:IsRPNameFunctionAvailable()
    local api = getAPI()
    local register = api and api.register
    local utils = api and api.utils
    return getFunction(register, "getUnitRPNameWithID") ~= nil
        and getFunction(register, "isUnitIDKnown") ~= nil
        and getFunction(register, "hasProfile") ~= nil
        and getFunction(utils and utils.str, "getUnitID") ~= nil
end

function TRP3:IsProfileRequestAvailable()
    local api = getAPI()
    return getFunction(api and api.r, "sendQuery") ~= nil
end

function TRP3:IsProfileOpenAvailable()
    local api = getAPI()
    return getFunction(api and api.slash, "openProfile") ~= nil
end

function TRP3:IsAvailable()
    return self:IsAddOnLoaded() and self:IsAPIAvailable()
end

function TRP3:GetRPName(unitToken, wowFullName, guid)
    if not self:IsAvailable() or not self:IsRPNameFunctionAvailable() then
        return nil, false
    end

    local watcher = {
        guid = guid,
        unitToken = unitToken,
        isTest = false,
    }
    local characterID = resolveCharacterID(watcher)
    local api = getAPI()
    if not characterID or not hasKnownProfile(api, characterID) then
        return nil, false
    end

    local getRPName = getFunction(api.register, "getUnitRPNameWithID")
    local ok, value = safeCall(getRPName, characterID, wowFullName)
    if not ok then
        return nil, true
    end

    local rpName = sanitizeRPName(value)
    local fallbackName = sanitizeRPName(wowFullName)
    if not rpName or rpName == fallbackName then
        return nil, true
    end
    return rpName, true
end

function TRP3:RequestProfile(watcher)
    if not watcher or watcher.isTest or not self:IsAvailable() or not self:IsProfileRequestAvailable() then
        return false, "unavailable"
    end
    if not RPWatcher.Scanner or not RPWatcher.Scanner:HasWatcher(watcher.guid) then
        return false, "missing"
    end

    local characterID = resolveCharacterID(watcher)
    if not characterID then
        return false, "no-id"
    end

    local now = GetTime()
    local lastRequestAt = lastRequestAtByGUID[watcher.guid]
    if lastRequestAt and now - lastRequestAt < self.PROFILE_REQUEST_COOLDOWN_SECONDS then
        if RPWatcher.Performance then
            RPWatcher.Performance:RecordTRP3RequestSkipped()
        end
        return false, "cooldown"
    end

    if queuedByGUID[watcher.guid] then
        if RPWatcher.Performance then
            RPWatcher.Performance:RecordTRP3RequestSkipped()
        end
        return false, "queued"
    end

    requestQueueTail = requestQueueTail + 1
    requestQueue[requestQueueTail] = {
        guid = watcher.guid,
        characterID = characterID,
    }
    queuedByGUID[watcher.guid] = true
    return true, "queued"
end

function TRP3:ProcessRequestQueue(now)
    now = now or GetTime()
    if requestQueueHead > requestQueueTail or not self:IsAvailable() or not self:IsProfileRequestAvailable() then
        return false
    end
    if now - lastGlobalRequestAt < self.GLOBAL_REQUEST_INTERVAL_SECONDS then
        return false
    end

    -- RPWatcher calls the public sendQuery export directly, outside TRP3's own
    -- nameplate slot queue. Process at most one valid entry per global interval.
    while requestQueueHead <= requestQueueTail do
        local request = requestQueue[requestQueueHead]
        requestQueue[requestQueueHead] = nil
        requestQueueHead = requestQueueHead + 1
        queuedByGUID[request.guid] = nil

        local watcher = RPWatcher.Scanner and RPWatcher.Scanner:GetWatcherByGUID(request.guid)
        if watcher and not watcher.isTest then
            local lastRequestAt = lastRequestAtByGUID[request.guid]
            if lastRequestAt and now - lastRequestAt < self.PROFILE_REQUEST_COOLDOWN_SECONDS then
                if RPWatcher.Performance then
                    RPWatcher.Performance:RecordTRP3RequestSkipped()
                end
            else
                lastRequestAtByGUID[request.guid] = now
                lastGlobalRequestAt = now
                local api = getAPI()
                local sendQuery = getFunction(api and api.r, "sendQuery")
                local ok = safeCall(sendQuery, request.characterID)
                if ok and RPWatcher.Performance then
                    RPWatcher.Performance:RecordTRP3RequestSent()
                elseif not ok and RPWatcher.Performance then
                    RPWatcher.Performance:RecordTRP3RequestSkipped()
                end
                if requestQueueHead > requestQueueTail then
                    clearTable(requestQueue)
                    requestQueueHead = 1
                    requestQueueTail = 0
                end
                return ok and true or false
            end
        end
    end

    clearTable(requestQueue)
    requestQueueHead = 1
    requestQueueTail = 0
    return false
end

function TRP3:RefreshWatcher(watcher, requestIfMissing)
    if not watcher or watcher.isTest or not RPWatcher.Scanner then
        return false, "ignored"
    end

    local rpName, profileKnown = self:GetRPName(watcher.unitToken, watcher.name, watcher.guid)
    if profileKnown then
        RPWatcher.Scanner:SetWatcherRPName(watcher.guid, rpName)
    end
    RPWatcher.Scanner:SetWatcherProfileKnown(watcher.guid, profileKnown and true or false)

    if rpName then
        return true, "name-found"
    elseif requestIfMissing then
        return self:RequestProfile(watcher)
    end
    return false, "no-name"
end

function TRP3:OnWatcherCreated(watcher)
    if watcher and not watcher.isTest then
        self:RefreshWatcher(watcher, true)
    end
end

function TRP3:OnWatcherVisible(watcher)
    if watcher and not watcher.isTest and not watcher.rpName then
        self:RefreshWatcher(watcher, true)
    end
end

function TRP3:HandleProfileDataUpdated(characterID)
    local normalizedID = normalizeCharacterID(characterID)
    if not normalizedID then
        return
    end

    local guid = guidByCharacterID[normalizedID]
    if not guid or not RPWatcher.Scanner then
        return
    end

    local watcher = RPWatcher.Scanner:GetWatcherByGUID(guid)
    if watcher and not watcher.isTest then
        self:RefreshWatcher(watcher, false)
    end
end

function TRP3:RefreshAllWatchers(sendRequests)
    local checked = 0
    local requested = 0
    local cooldown = 0
    if not RPWatcher.Scanner then
        return checked, requested, cooldown
    end

    RPWatcher.Scanner:ForEachWatcher(function(watcher)
        if not watcher.isTest then
            checked = checked + 1
            self:RefreshWatcher(watcher, false)
            if sendRequests then
                local sent, reason = self:RequestProfile(watcher)
                if sent then
                    requested = requested + 1
                elseif reason == "cooldown" then
                    cooldown = cooldown + 1
                end
            end
        end
    end)

    if RPWatcher.UI then
        RPWatcher.UI:RefreshWatcherList()
    end
    return checked, requested, cooldown
end

function TRP3:OpenProfile(watcher)
    if not watcher or watcher.isTest or not self:IsAvailable() or not self:IsProfileOpenAvailable() then
        return false, "unavailable"
    end
    if not RPWatcher.Scanner or not RPWatcher.Scanner:HasWatcher(watcher.guid) then
        return false, "missing"
    end

    local api = getAPI()
    local characterID = resolveCharacterID(watcher)
    if characterID and not hasKnownProfile(api, characterID) then
        local sent, reason = self:RequestProfile(watcher)
        return false, sent and "requested" or reason
    end

    local argument = characterID or watcher.name
    if type(argument) ~= "string" or argument == "" then
        return false, "missing"
    end

    if not characterID then
        local now = GetTime()
        local lastRequestAt = lastRequestAtByGUID[watcher.guid]
        if lastRequestAt and now - lastRequestAt < self.PROFILE_REQUEST_COOLDOWN_SECONDS then
            return false, "cooldown"
        end
        lastRequestAtByGUID[watcher.guid] = now
    end

    -- Verified in Total RP 3 3.3.7: UnitPopups and /trp3 open both use this API export.
    local openProfile = getFunction(api and api.slash, "openProfile")
    local ok = safeCall(openProfile, argument)
    return ok and true or false, ok and "opened" or "failed"
end

function TRP3:GetWatcherNameCounts()
    local withRPName = 0
    local withoutRPName = 0
    if RPWatcher.Scanner then
        RPWatcher.Scanner:ForEachWatcher(function(watcher)
            if not watcher.isTest then
                if type(watcher.rpName) == "string" and watcher.rpName ~= "" then
                    withRPName = withRPName + 1
                else
                    withoutRPName = withoutRPName + 1
                end
            end
        end)
    end
    return withRPName, withoutRPName
end

function TRP3:PrintDiagnostics()
    local withRPName, withoutRPName = self:GetWatcherNameCounts()
    local function yesNo(value)
        return value and L.COMMON_YES or L.COMMON_NO
    end

    local Localization = RPWatcher.Localization
    print("|cff66ccffRPWatcher|r " .. L.TRP3_DIAG_HEADER)
    print(Localization:Format("TRP3_DIAG_LOADED", yesNo(self:IsAddOnLoaded())))
    print(Localization:Format("TRP3_DIAG_API_AVAILABLE", yesNo(self:IsAPIAvailable())))
    print(Localization:Format("TRP3_DIAG_NAME_FUNCTION", yesNo(self:IsRPNameFunctionAvailable())))
    print(Localization:Format("TRP3_DIAG_PROFILE_REQUEST", yesNo(self:IsProfileRequestAvailable())))
    print(Localization:Format("TRP3_DIAG_PROFILE_OPEN", yesNo(self:IsProfileOpenAvailable())))
    print(Localization:Format("TRP3_DIAG_WITH_RPNAME", withRPName))
    print(Localization:Format("TRP3_DIAG_WITHOUT_RPNAME", withoutRPName))
end

function TRP3:ForgetWatcher(guid)
    local characterID = characterIDByGUID[guid]
    if characterID then
        guidByCharacterID[normalizeCharacterID(characterID)] = nil
    end
    characterIDByGUID[guid] = nil
    lastRequestAtByGUID[guid] = nil
    queuedByGUID[guid] = nil
end

function TRP3:ClearRuntimeData()
    clearTable(lastRequestAtByGUID)
    clearTable(characterIDByGUID)
    clearTable(guidByCharacterID)
    clearTable(requestQueue)
    clearTable(queuedByGUID)
    requestQueueHead = 1
    requestQueueTail = 0
    lastGlobalRequestAt = -math.huge
end

function TRP3:HandleAvailabilityChanged()
    if self:IsAvailable() then
        registerDataCallback()
        self:RefreshAllWatchers(true)
    end
    if RPWatcher.Scanner then
        RPWatcher.Scanner:NotifyWatchersChanged()
    end
end

function TRP3:Shutdown()
    unregisterDataCallback()
    eventFrame:UnregisterAllEvents()
    initialized = false
end

function TRP3:Initialize()
    if initialized then
        self:Shutdown()
    end

    self:ClearRuntimeData()
    eventFrame:RegisterEvent("ADDON_LOADED")
    eventFrame:RegisterEvent("PLAYER_LOGIN")
    if self:IsAvailable() then
        registerDataCallback()
    end
    initialized = true
end

eventFrame:SetScript("OnEvent", function(_, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == "totalRP3" then
        TRP3:HandleAvailabilityChanged()
    elseif event == "PLAYER_LOGIN" then
        eventFrame:UnregisterEvent("PLAYER_LOGIN")
        TRP3:HandleAvailabilityChanged()
    end
end)
