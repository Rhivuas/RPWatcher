local _, RPWatcher = ...

local Scanner = {}
RPWatcher.Scanner = Scanner

Scanner.STATUS_ACTIVE = "ACTIVE"
Scanner.STATUS_INACTIVE = "INACTIVE"
Scanner.STATUS_UNKNOWN = "UNKNOWN"
Scanner.SCAN_INTERVAL_SECONDS = 0.25

-- Scanner-owned runtime state. Consumers must use the public methods below.
local visibleUnits = {}
local guidByUnitToken = {}
local unitTokenByGUID = {}
local watchersByGUID = {}
local sortedWatchers = {}
local staleUnitTokens = {}
local expiredGUIDs = {}

local eventFrame = CreateFrame("Frame")
local scanTicker
local changeCallback
local sortedListDirty = true
local dataChanged = false
local initialized = false

local TEST_GUID_ACTIVE = "RPWATCHER-TEST-ACTIVE"
local TEST_GUID_INACTIVE = "RPWATCHER-TEST-INACTIVE"
local TEST_GUID_UNKNOWN = "RPWATCHER-TEST-UNKNOWN"

local STATUS_ORDER = {
    [Scanner.STATUS_ACTIVE] = 1,
    [Scanner.STATUS_INACTIVE] = 2,
    [Scanner.STATUS_UNKNOWN] = 3,
}

local function clearTable(target)
    for key in pairs(target) do
        target[key] = nil
    end
end

local function markDataChanged(watcher, now)
    if watcher then
        watcher.lastChangedAt = now
    end
    sortedListDirty = true
    dataChanged = true
end

local function notifyIfChanged()
    if not dataChanged then
        return
    end

    dataChanged = false
    if changeCallback then
        changeCallback()
    end
end

local function getStatusActivityTime(watcher)
    if watcher.observationStatus == Scanner.STATUS_ACTIVE then
        return watcher.targetStartedAt or watcher.lastChangedAt or 0
    elseif watcher.observationStatus == Scanner.STATUS_INACTIVE then
        return watcher.targetLostAt or watcher.lastChangedAt or 0
    end

    return watcher.nameplateHiddenAt or watcher.lastChangedAt or 0
end

local function sortWatchers(a, b)
    local aOrder = STATUS_ORDER[a.observationStatus] or 99
    local bOrder = STATUS_ORDER[b.observationStatus] or 99
    if aOrder ~= bOrder then
        return aOrder < bOrder
    end

    local aTime = getStatusActivityTime(a)
    local bTime = getStatusActivityTime(b)
    if aTime ~= bTime then
        return aTime > bTime
    end

    return (a.rpName or a.name or "") < (b.rpName or b.name or "")
end

local function isValidUnitToken(unitToken)
    return type(unitToken) == "string" and unitToken ~= ""
end

local function getQualifiedUnitGUID(unitToken)
    if not isValidUnitToken(unitToken) or not UnitExists(unitToken) then
        return nil
    end
    if not UnitIsPlayer(unitToken) then
        return nil
    end
    if not UnitIsFriend("player", unitToken) then
        return nil
    end
    if UnitIsUnit(unitToken, "player") then
        return nil
    end

    return UnitGUID(unitToken)
end

local function isTargetingPlayer(unitToken)
    if not isValidUnitToken(unitToken) then
        return false
    end

    local targetToken = unitToken .. "target"
    return UnitExists(targetToken) and UnitIsUnit(targetToken, "player") or false
end

local function createWatcher(guid, unitToken, now)
    local fullName = GetUnitName(unitToken, true)
    if type(fullName) ~= "string" or fullName == "" then
        return nil
    end

    local watcher = {
        guid = guid,
        name = fullName,
        unitToken = unitToken,
        isVisible = true,
        observationStatus = Scanner.STATUS_ACTIVE,
        firstDetectedAt = now,
        targetStartedAt = now,
        lastTargetConfirmedAt = now,
        targetLostAt = nil,
        nameplateHiddenAt = nil,
        lastVisibleAt = now,
        lastChangedAt = now,
        isTest = false,
    }
    watchersByGUID[guid] = watcher
    markDataChanged(watcher, now)

    if RPWatcher.TRP3 and RPWatcher.TRP3.OnWatcherCreated then
        RPWatcher.TRP3:OnWatcherCreated(watcher)
    end
    return watcher
end

local function setWatcherActive(watcher, now)
    if watcher.observationStatus ~= Scanner.STATUS_ACTIVE then
        watcher.observationStatus = Scanner.STATUS_ACTIVE
        watcher.targetStartedAt = now
        markDataChanged(watcher, now)
    end
    watcher.lastTargetConfirmedAt = now
end

local function setWatcherInactive(watcher, now)
    if watcher.observationStatus == Scanner.STATUS_INACTIVE then
        return
    end

    watcher.observationStatus = Scanner.STATUS_INACTIVE
    watcher.targetLostAt = now
    markDataChanged(watcher, now)
end

local function setWatcherUnknown(watcher, now)
    if watcher.observationStatus == Scanner.STATUS_UNKNOWN and not watcher.isVisible then
        return
    end

    watcher.observationStatus = Scanner.STATUS_UNKNOWN
    watcher.isVisible = false
    watcher.unitToken = nil
    watcher.nameplateHiddenAt = now
    markDataChanged(watcher, now)
end

local function detachUnitToken(unitToken, now)
    local guid = guidByUnitToken[unitToken]
    visibleUnits[unitToken] = nil
    guidByUnitToken[unitToken] = nil

    if not guid then
        return
    end
    if unitTokenByGUID[guid] == unitToken then
        unitTokenByGUID[guid] = nil
    end

    local watcher = watchersByGUID[guid]
    if watcher and watcher.unitToken == unitToken then
        setWatcherUnknown(watcher, now)
    end
end

local function updateVisibleWatcher(guid, unitToken, now, targetingPlayer)
    local watcher = watchersByGUID[guid]
    if not watcher then
        if targetingPlayer then
            createWatcher(guid, unitToken, now)
        end
        return
    end

    local wasVisible = watcher.isVisible
    watcher.unitToken = unitToken
    watcher.isVisible = true
    watcher.lastVisibleAt = now

    local fullName = GetUnitName(unitToken, true)
    if type(fullName) == "string" and fullName ~= "" and fullName ~= watcher.name then
        watcher.name = fullName
        markDataChanged(watcher, now)
    end

    if targetingPlayer then
        setWatcherActive(watcher, now)
    else
        setWatcherInactive(watcher, now)
    end

    if not wasVisible and not watcher.isTest and RPWatcher.TRP3 and RPWatcher.TRP3.OnWatcherVisible then
        RPWatcher.TRP3:OnWatcherVisible(watcher)
    end
end

function Scanner:SetChangeCallback(callback)
    changeCallback = type(callback) == "function" and callback or nil
end

function Scanner:GetSortedWatchers()
    if sortedListDirty then
        clearTable(sortedWatchers)
        for _, watcher in pairs(watchersByGUID) do
            sortedWatchers[#sortedWatchers + 1] = watcher
        end
        table.sort(sortedWatchers, sortWatchers)
        sortedListDirty = false
    end

    return sortedWatchers
end

function Scanner:GetWatcherByGUID(guid)
    return type(guid) == "string" and watchersByGUID[guid] or nil
end

function Scanner:HasWatcher(guid)
    return self:GetWatcherByGUID(guid) ~= nil
end

function Scanner:SetWatcherRPName(guid, rpName)
    local watcher = self:GetWatcherByGUID(guid)
    if not watcher or watcher.isTest then
        return false
    end

    if type(rpName) ~= "string" or rpName == "" then
        rpName = nil
    end
    if watcher.rpName == rpName then
        return false
    end

    watcher.rpName = rpName
    markDataChanged(watcher, GetTime())
    notifyIfChanged()
    return true
end

function Scanner:ForEachWatcher(callback)
    if type(callback) ~= "function" then
        return
    end
    for _, watcher in pairs(watchersByGUID) do
        callback(watcher)
    end
end

function Scanner:NotifyWatchersChanged()
    markDataChanged(nil, GetTime())
    notifyIfChanged()
end

function Scanner:HandleNameplateAdded(unitToken, now, suppressNotification)
    now = now or GetTime()
    local guid = getQualifiedUnitGUID(unitToken)
    if not guid then
        if isValidUnitToken(unitToken) and guidByUnitToken[unitToken] then
            detachUnitToken(unitToken, now)
            if not suppressNotification then
                notifyIfChanged()
            end
        end
        return
    end

    local previousGUID = guidByUnitToken[unitToken]
    if previousGUID and previousGUID ~= guid then
        detachUnitToken(unitToken, now)
    end

    local previousUnitToken = unitTokenByGUID[guid]
    if previousUnitToken and previousUnitToken ~= unitToken then
        visibleUnits[previousUnitToken] = nil
        guidByUnitToken[previousUnitToken] = nil
    end

    visibleUnits[unitToken] = true
    guidByUnitToken[unitToken] = guid
    unitTokenByGUID[guid] = unitToken
    updateVisibleWatcher(guid, unitToken, now, isTargetingPlayer(unitToken))

    if not suppressNotification then
        notifyIfChanged()
    end
end

function Scanner:HandleNameplateRemoved(unitToken)
    if not isValidUnitToken(unitToken) then
        return
    end

    -- Intentionally use the stored mapping: the removed token may no longer expose a GUID.
    detachUnitToken(unitToken, GetTime())
    notifyIfChanged()
end

function Scanner:CaptureExistingNameplates()
    local nameplates = C_NamePlate.GetNamePlates()
    local now = GetTime()
    for index = 1, #nameplates do
        local nameplate = nameplates[index]
        local unitToken = nameplate and nameplate.namePlateUnitToken
        if unitToken then
            self:HandleNameplateAdded(unitToken, now, true)
        end
    end
    notifyIfChanged()
end

function Scanner:Scan()
    local now = GetTime()
    local unknownRetentionSeconds = RPWatcher.Settings:GetUnknownRetentionSeconds()
    clearTable(staleUnitTokens)

    for unitToken in pairs(visibleUnits) do
        local storedGUID = guidByUnitToken[unitToken]
        local currentGUID = getQualifiedUnitGUID(unitToken)
        if not storedGUID or currentGUID ~= storedGUID then
            staleUnitTokens[#staleUnitTokens + 1] = unitToken
        else
            updateVisibleWatcher(storedGUID, unitToken, now, isTargetingPlayer(unitToken))
        end
    end

    for index = 1, #staleUnitTokens do
        detachUnitToken(staleUnitTokens[index], now)
    end

    clearTable(expiredGUIDs)
    for guid, watcher in pairs(watchersByGUID) do
        if watcher.observationStatus == self.STATUS_UNKNOWN
            and watcher.nameplateHiddenAt
            and now - watcher.nameplateHiddenAt >= unknownRetentionSeconds then
            expiredGUIDs[#expiredGUIDs + 1] = guid
        end
    end

    for index = 1, #expiredGUIDs do
        if RPWatcher.TRP3 and RPWatcher.TRP3.ForgetWatcher then
            RPWatcher.TRP3:ForgetWatcher(expiredGUIDs[index])
        end
        watchersByGUID[expiredGUIDs[index]] = nil
        markDataChanged(nil, now)
    end

    notifyIfChanged()
    if RPWatcher.UI then
        RPWatcher.UI:RefreshElapsedTimes(now)
    end
end

function Scanner:ClearWatchers()
    if RPWatcher.TRP3 and RPWatcher.TRP3.ClearRuntimeData then
        RPWatcher.TRP3:ClearRuntimeData()
    end
    clearTable(watchersByGUID)
    clearTable(sortedWatchers)
    sortedListDirty = true
    dataChanged = true
    notifyIfChanged()
end

function Scanner:AddTestData()
    local now = GetTime()
    watchersByGUID[TEST_GUID_ACTIVE] = {
        guid = TEST_GUID_ACTIVE,
        name = "[Test] Aktuell",
        unitToken = nil,
        isVisible = true,
        observationStatus = self.STATUS_ACTIVE,
        firstDetectedAt = now - 12,
        targetStartedAt = now - 12,
        lastTargetConfirmedAt = now,
        targetLostAt = nil,
        nameplateHiddenAt = nil,
        lastVisibleAt = now,
        lastChangedAt = now - 12,
        isTest = true,
        rpName = "[Test] Lady Aktuell",
    }
    watchersByGUID[TEST_GUID_INACTIVE] = {
        guid = TEST_GUID_INACTIVE,
        name = "[Test] Vorher",
        unitToken = nil,
        isVisible = true,
        observationStatus = self.STATUS_INACTIVE,
        firstDetectedAt = now - 30,
        targetStartedAt = now - 30,
        lastTargetConfirmedAt = now - 8,
        targetLostAt = now - 8,
        nameplateHiddenAt = nil,
        lastVisibleAt = now,
        lastChangedAt = now - 8,
        isTest = true,
        rpName = "[Test] Lord Vorher",
    }
    watchersByGUID[TEST_GUID_UNKNOWN] = {
        guid = TEST_GUID_UNKNOWN,
        name = "[Test] Unbekannt",
        unitToken = nil,
        isVisible = false,
        observationStatus = self.STATUS_UNKNOWN,
        firstDetectedAt = now - 45,
        targetStartedAt = now - 45,
        lastTargetConfirmedAt = now - 2,
        targetLostAt = nil,
        nameplateHiddenAt = now - 2,
        lastVisibleAt = now - 2,
        lastChangedAt = now - 2,
        isTest = true,
    }
    markDataChanged(nil, now)
    notifyIfChanged()
end

function Scanner:Shutdown()
    if scanTicker then
        scanTicker:Cancel()
        scanTicker = nil
    end
    eventFrame:UnregisterAllEvents()
    initialized = false
end

function Scanner:Initialize()
    if initialized then
        self:Shutdown()
    end

    clearTable(visibleUnits)
    clearTable(guidByUnitToken)
    clearTable(unitTokenByGUID)
    clearTable(watchersByGUID)
    clearTable(sortedWatchers)
    sortedListDirty = true
    dataChanged = true

    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    self:CaptureExistingNameplates()

    scanTicker = C_Timer.NewTicker(self.SCAN_INTERVAL_SECONDS, function()
        Scanner:Scan()
    end)
    initialized = true
    notifyIfChanged()
end

eventFrame:SetScript("OnEvent", function(_, event, unitToken)
    if event == "NAME_PLATE_UNIT_ADDED" then
        Scanner:HandleNameplateAdded(unitToken)
    elseif event == "NAME_PLATE_UNIT_REMOVED" then
        Scanner:HandleNameplateRemoved(unitToken)
    elseif event == "PLAYER_ENTERING_WORLD" then
        Scanner:CaptureExistingNameplates()
    end
end)
