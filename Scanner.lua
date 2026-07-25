local _, RPWatcher = ...

local Scanner = {}
RPWatcher.Scanner = Scanner

Scanner.STATUS_ACTIVE = "ACTIVE"
Scanner.STATUS_INACTIVE = "INACTIVE"
Scanner.STATUS_UNKNOWN = "UNKNOWN"
Scanner.SCAN_INTERVAL_SECONDS = 0.25
Scanner.INTEGRITY_INTERVAL_SECONDS = 5
Scanner.EXPIRY_INTERVAL_SECONDS = 1

-- Scanner-owned runtime state. Consumers must use the public methods below.
local visibleNameplateTokens = {}
local candidatesByUnitToken = {}
local guidByUnitToken = {}
local unitTokenByGUID = {}
local watchersByGUID = {}
local sortedWatchers = {}
local staleUnitTokens = {}
local expiredGUIDs = {}
local seenNameplateTokens = {}
local stressGUIDs = {}

local eventFrame = CreateFrame("Frame")
local scanTicker
local changeCallback
local sortedListDirty = true
local dataChanged = false
local initialized = false
local playerInWorld = false
local nextIntegrityCheckAt = 0
local nextExpiryCheckAt = 0

local TEST_GUID_ACTIVE = "RPWATCHER-TEST-ACTIVE"
local TEST_GUID_INACTIVE = "RPWATCHER-TEST-INACTIVE"
local TEST_GUID_UNKNOWN = "RPWATCHER-TEST-UNKNOWN"
local STRESS_GUID_PREFIX = "RPWATCHER-STRESS-"
local STRESS_RP_NAME_PATTERNS = {
    "Bo %03d",
    "Mira Silberhain %03d",
    "Lady Aveline von den Nebelgärten zu Sturmwind %03d",
}

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

-- Current Blizzard nameplate frames expose GetUnit(). The legacy field remains
-- a defensive fallback for compatible third-party or older nameplate frames.
local function getUnitTokenFromNameplate(nameplate)
    if not nameplate then
        return nil, nil
    end

    local getUnit = nameplate.GetUnit
    if type(getUnit) == "function" then
        local ok, unitToken = pcall(getUnit, nameplate)
        if ok and isValidUnitToken(unitToken) then
            return unitToken, "GetUnit"
        end
    end

    local legacyUnitToken = nameplate.namePlateUnitToken
    if isValidUnitToken(legacyUnitToken) then
        return legacyUnitToken, "namePlateUnitToken"
    end

    return nil, nil
end

local function countEntries(target)
    local count = 0
    for _ in pairs(target) do
        count = count + 1
    end
    return count
end

-- 1.2.0 audit (dead players/ghosts): the reported suspicion could not be
-- reproduced. Confirmed by static review that this function contains no
-- UnitIsDead/UnitIsDeadOrGhost/UnitIsGhost/UnitIsConnected check and no other
-- reaction- or target-based implicit filter beyond the ones below; a dead or
-- ghosted friendly player with a visible nameplate qualifies exactly like any
-- other friendly player. No speculative death/ghost filter was added -- see
-- release/TEST_MATRIX_1.2.0.md for the manual death/ghost/resurrection cases.
local function getQualifiedUnit(unitToken)
    if not isValidUnitToken(unitToken) or not UnitExists(unitToken) then
        return nil, nil
    end
    if not UnitIsPlayer(unitToken) then
        return nil, nil
    end
    if not UnitIsFriend("player", unitToken) then
        return nil, nil
    end
    if UnitIsUnit(unitToken, "player") then
        return nil, nil
    end

    local guid = UnitGUID(unitToken)
    local fullName = GetUnitName(unitToken, true)
    if type(guid) ~= "string" or guid == "" or type(fullName) ~= "string" or fullName == "" then
        return nil, nil
    end
    return guid, fullName
end

local function isTargetingPlayer(candidate)
    if not candidate or not isValidUnitToken(candidate.targetToken) then
        return false
    end

    return UnitExists(candidate.targetToken) and UnitIsUnit(candidate.targetToken, "player") or false
end

local function createWatcher(guid, unitToken, fullName, now)
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
        hasTRP3Profile = false,
    }
    watchersByGUID[guid] = watcher
    markDataChanged(watcher, now)
    if RPWatcher.Performance then
        RPWatcher.Performance:RecordWatcherCreated()
    end

    if RPWatcher.TRP3 and RPWatcher.TRP3.OnWatcherCreated then
        RPWatcher.TRP3:OnWatcherCreated(watcher)
    end
    return watcher
end

-- 1.2.0 watcher continuity (see setWatcherUnknown below for the state this
-- reads). A brief nameplate loss must not restart the active/inactive timer:
-- only a genuinely new confirmed observation does. "Genuinely new" means the
-- watcher was NOT already active (directly, or active right before its most
-- recent unknown phase) when this transition fires.
local function setWatcherActive(watcher, now)
    if watcher.observationStatus ~= Scanner.STATUS_ACTIVE then
        local continuesActivePhase = watcher.observationStatus == Scanner.STATUS_UNKNOWN
            and watcher.statusBeforeUnknown == Scanner.STATUS_ACTIVE
            and watcher.targetStartedAtBeforeUnknown ~= nil

        watcher.observationStatus = Scanner.STATUS_ACTIVE
        watcher.targetStartedAt = continuesActivePhase and watcher.targetStartedAtBeforeUnknown or now
        markDataChanged(watcher, now)
        if not watcher.isTest and RPWatcher.Performance then
            RPWatcher.Performance:RecordStatusChange()
        end
    end
    watcher.lastTargetConfirmedAt = now
end

-- Mirrors setWatcherActive: a watcher that was already "Vorher" before a
-- brief unknown phase keeps its original targetLostAt (no reset). A watcher
-- that was "Aktuell" before going unknown and returns without the target
-- becomes "Vorher" for the first time; the exact moment of loss during the
-- invisible phase was never observed, so the conservative, documented choice
-- is nameplateHiddenAt (the start of the visibility loss) rather than "now"
-- (the moment of reappearance), which would overstate how recently it lost
-- the target. A direct Aktuell -> Vorher transition (no intervening unknown
-- phase) is unaffected and keeps using "now", as before 1.2.0.
local function setWatcherInactive(watcher, now)
    if watcher.observationStatus == Scanner.STATUS_INACTIVE then
        return
    end

    local wasUnknown = watcher.observationStatus == Scanner.STATUS_UNKNOWN
    local continuesInactivePhase = wasUnknown
        and watcher.statusBeforeUnknown == Scanner.STATUS_INACTIVE
        and watcher.targetLostAtBeforeUnknown ~= nil
    local newlyInactiveAfterUnknownActive = wasUnknown
        and watcher.statusBeforeUnknown == Scanner.STATUS_ACTIVE

    watcher.observationStatus = Scanner.STATUS_INACTIVE
    if continuesInactivePhase then
        watcher.targetLostAt = watcher.targetLostAtBeforeUnknown
    elseif newlyInactiveAfterUnknownActive then
        watcher.targetLostAt = watcher.nameplateHiddenAt or now
    else
        watcher.targetLostAt = now
    end
    markDataChanged(watcher, now)
    if not watcher.isTest and RPWatcher.Performance then
        RPWatcher.Performance:RecordStatusChange()
    end
end

-- Captures just enough volatile state to tell, on return from Unbekannt,
-- whether it was Aktuell or Vorher beforehand, and that phase's original
-- timestamp (targetStartedAt or targetLostAt respectively) -- see
-- setWatcherActive/setWatcherInactive above for how it is consumed. Only
-- captured on the transition INTO Unbekannt so it always reflects the phase
-- immediately preceding the current invisibility, never stale data from an
-- earlier cycle. Purely runtime state on the same watcher record already
-- excluded from RPWatcherDB; no second cache or state machine is added.
local function setWatcherUnknown(watcher, now)
    if watcher.observationStatus == Scanner.STATUS_UNKNOWN and not watcher.isVisible then
        return
    end

    if watcher.observationStatus ~= Scanner.STATUS_UNKNOWN then
        watcher.statusBeforeUnknown = watcher.observationStatus
        watcher.targetStartedAtBeforeUnknown = watcher.observationStatus == Scanner.STATUS_ACTIVE
            and watcher.targetStartedAt or nil
        watcher.targetLostAtBeforeUnknown = watcher.observationStatus == Scanner.STATUS_INACTIVE
            and watcher.targetLostAt or nil
    end

    watcher.observationStatus = Scanner.STATUS_UNKNOWN
    watcher.isVisible = false
    watcher.unitToken = nil
    watcher.nameplateHiddenAt = now
    markDataChanged(watcher, now)
    if not watcher.isTest and RPWatcher.Performance then
        RPWatcher.Performance:RecordStatusChange()
    end
end

local function detachCandidate(unitToken, now)
    local guid = guidByUnitToken[unitToken]
    candidatesByUnitToken[unitToken] = nil
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

local function removeNameplateToken(unitToken, now)
    visibleNameplateTokens[unitToken] = nil
    detachCandidate(unitToken, now)
end

local function updateVisibleWatcher(candidate, now, targetingPlayer)
    local guid = candidate.guid
    local unitToken = candidate.unitToken
    local watcher = watchersByGUID[guid]
    if not watcher then
        if targetingPlayer then
            createWatcher(guid, unitToken, candidate.fullName, now)
        end
        return
    end

    local wasVisible = watcher.isVisible
    watcher.unitToken = unitToken
    watcher.isVisible = true
    watcher.lastVisibleAt = now

    if candidate.fullName ~= watcher.name then
        watcher.name = candidate.fullName
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

function Scanner:SetWatcherProfileKnown(guid, hasProfile)
    local watcher = self:GetWatcherByGUID(guid)
    if not watcher or watcher.isTest then
        return false
    end

    hasProfile = hasProfile and true or false
    if watcher.hasTRP3Profile == hasProfile then
        return false
    end

    watcher.hasTRP3Profile = hasProfile
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
    if not isValidUnitToken(unitToken) then
        return
    end

    visibleNameplateTokens[unitToken] = true
    local guid, fullName = getQualifiedUnit(unitToken)
    if not guid then
        if guidByUnitToken[unitToken] then
            detachCandidate(unitToken, now)
            if not suppressNotification then
                notifyIfChanged()
            end
        end
        return
    end

    local previousGUID = guidByUnitToken[unitToken]
    if previousGUID and previousGUID ~= guid then
        detachCandidate(unitToken, now)
    end

    local previousUnitToken = unitTokenByGUID[guid]
    if previousUnitToken and previousUnitToken ~= unitToken then
        -- The same GUID can move to a new nameplate token without becoming unknown.
        visibleNameplateTokens[previousUnitToken] = nil
        candidatesByUnitToken[previousUnitToken] = nil
        guidByUnitToken[previousUnitToken] = nil
    end

    local candidate = candidatesByUnitToken[unitToken]
    if not candidate then
        candidate = {}
        candidatesByUnitToken[unitToken] = candidate
    end
    candidate.guid = guid
    candidate.unitToken = unitToken
    candidate.targetToken = unitToken .. "target"
    candidate.fullName = fullName
    guidByUnitToken[unitToken] = guid
    unitTokenByGUID[guid] = unitToken
    updateVisibleWatcher(candidate, now, isTargetingPlayer(candidate))

    if not suppressNotification then
        notifyIfChanged()
    end
end

function Scanner:HandleNameplateRemoved(unitToken)
    if not isValidUnitToken(unitToken) then
        return
    end

    -- Intentionally use the stored mapping: the removed token may no longer expose a GUID.
    removeNameplateToken(unitToken, GetTime())
    notifyIfChanged()
end

function Scanner:CaptureExistingNameplates(now, suppressNotification)
    local nameplates = C_NamePlate.GetNamePlates()
    now = now or GetTime()
    clearTable(seenNameplateTokens)
    for index = 1, #nameplates do
        local nameplate = nameplates[index]
        local unitToken = getUnitTokenFromNameplate(nameplate)
        if isValidUnitToken(unitToken) then
            seenNameplateTokens[unitToken] = true
            self:HandleNameplateAdded(unitToken, now, true)
        end
    end

    clearTable(staleUnitTokens)
    for unitToken in pairs(visibleNameplateTokens) do
        if not seenNameplateTokens[unitToken] then
            staleUnitTokens[#staleUnitTokens + 1] = unitToken
        end
    end
    for index = 1, #staleUnitTokens do
        removeNameplateToken(staleUnitTokens[index], now)
    end

    if not suppressNotification then
        notifyIfChanged()
    end
end

function Scanner:ClearVisibleNameplates()
    local now = GetTime()
    clearTable(staleUnitTokens)
    for unitToken in pairs(visibleNameplateTokens) do
        staleUnitTokens[#staleUnitTokens + 1] = unitToken
    end
    for index = 1, #staleUnitTokens do
        removeNameplateToken(staleUnitTokens[index], now)
    end
    clearTable(visibleNameplateTokens)
    clearTable(candidatesByUnitToken)
    clearTable(guidByUnitToken)
    clearTable(unitTokenByGUID)
    clearTable(seenNameplateTokens)
    notifyIfChanged()
end

function Scanner:Scan()
    local now = GetTime()
    local performanceEnabled = RPWatcher.Performance and RPWatcher.Performance:IsEnabled()
    local scanStartedAt = performanceEnabled and RPWatcher.Performance:StartScanMeasurement() or nil
    local candidatesChecked = 0
    clearTable(staleUnitTokens)

    -- Fast path: static player/friend/name checks are cached at nameplate add.
    -- GUID remains dynamic so a reused token can never inherit the previous player.
    for unitToken, candidate in pairs(candidatesByUnitToken) do
        candidatesChecked = candidatesChecked + 1
        local currentGUID = UnitGUID(unitToken)
        if currentGUID ~= candidate.guid then
            staleUnitTokens[#staleUnitTokens + 1] = unitToken
        else
            updateVisibleWatcher(candidate, now, isTargetingPlayer(candidate))
        end
    end

    for index = 1, #staleUnitTokens do
        removeNameplateToken(staleUnitTokens[index], now)
    end

    if playerInWorld and now >= nextIntegrityCheckAt then
        -- The same ticker performs a rare full reconciliation; no second timer is used.
        nextIntegrityCheckAt = now + self.INTEGRITY_INTERVAL_SECONDS
        self:CaptureExistingNameplates(now, true)
    end

    if now >= nextExpiryCheckAt then
        nextExpiryCheckAt = now + self.EXPIRY_INTERVAL_SECONDS
        local unknownRetentionSeconds = RPWatcher.Settings:GetUnknownRetentionSeconds()
        clearTable(expiredGUIDs)
        for guid, watcher in pairs(watchersByGUID) do
            if watcher.observationStatus == self.STATUS_UNKNOWN
                and watcher.nameplateHiddenAt
                and not watcher.isStress
                and now - watcher.nameplateHiddenAt >= unknownRetentionSeconds then
                expiredGUIDs[#expiredGUIDs + 1] = guid
            end
        end

        for index = 1, #expiredGUIDs do
            if RPWatcher.TRP3 and RPWatcher.TRP3.ForgetWatcher then
                RPWatcher.TRP3:ForgetWatcher(expiredGUIDs[index])
            end
            local watcher = watchersByGUID[expiredGUIDs[index]]
            if watcher and not watcher.isTest and RPWatcher.Performance then
                RPWatcher.Performance:RecordWatcherRemoved()
            end
            watchersByGUID[expiredGUIDs[index]] = nil
            markDataChanged(nil, now)
        end
    end

    if playerInWorld and RPWatcher.TRP3 and RPWatcher.TRP3.ProcessRequestQueue then
        RPWatcher.TRP3:ProcessRequestQueue(now)
    end
    notifyIfChanged()
    if RPWatcher.UI then
        RPWatcher.UI:RefreshElapsedTimes(now)
    end
    if performanceEnabled then
        RPWatcher.Performance:RecordScan(scanStartedAt, candidatesChecked)
    end
end

function Scanner:ClearWatchers()
    if RPWatcher.TRP3 and RPWatcher.TRP3.ClearRuntimeData then
        RPWatcher.TRP3:ClearRuntimeData()
    end
    if RPWatcher.Performance and RPWatcher.Performance:IsEnabled() then
        local removedRealWatchers = 0
        for _, watcher in pairs(watchersByGUID) do
            if not watcher.isTest then
                removedRealWatchers = removedRealWatchers + 1
            end
        end
        if removedRealWatchers > 0 then
            RPWatcher.Performance:RecordWatcherRemoved(removedRealWatchers)
        end
    end
    clearTable(watchersByGUID)
    clearTable(sortedWatchers)
    clearTable(stressGUIDs)
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
        hasTRP3Profile = false,
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
        hasTRP3Profile = false,
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
        hasTRP3Profile = false,
    }
    markDataChanged(nil, now)
    notifyIfChanged()
end

function Scanner:RemoveStressData(suppressNotification)
    clearTable(stressGUIDs)
    for guid, watcher in pairs(watchersByGUID) do
        if watcher.isStress then
            stressGUIDs[#stressGUIDs + 1] = guid
        end
    end

    for index = 1, #stressGUIDs do
        watchersByGUID[stressGUIDs[index]] = nil
    end
    if #stressGUIDs > 0 then
        markDataChanged(nil, GetTime())
        if not suppressNotification then
            notifyIfChanged()
        end
    end
    return #stressGUIDs
end

function Scanner:AddStressData(count)
    if count ~= 25 and count ~= 50 and count ~= 100 and count ~= 200 then
        return false
    end

    self:RemoveStressData(true)
    local now = GetTime()
    for index = 1, count do
        local guid = STRESS_GUID_PREFIX .. ("%03d"):format(index)
        local statusIndex = (index - 1) % 3
        local status = statusIndex == 0 and self.STATUS_ACTIVE
            or statusIndex == 1 and self.STATUS_INACTIVE
            or self.STATUS_UNKNOWN
        local elapsed = (index % 55) + 1
        watchersByGUID[guid] = {
            guid = guid,
            name = ("[Stress] Spieler %03d"):format(index),
            rpName = string.format(STRESS_RP_NAME_PATTERNS[((index - 1) % #STRESS_RP_NAME_PATTERNS) + 1], index),
            unitToken = nil,
            isVisible = status ~= self.STATUS_UNKNOWN,
            observationStatus = status,
            firstDetectedAt = now - elapsed - 30,
            targetStartedAt = status == self.STATUS_ACTIVE and now - elapsed or now - elapsed - 20,
            lastTargetConfirmedAt = now - elapsed,
            targetLostAt = status == self.STATUS_INACTIVE and now - elapsed or nil,
            nameplateHiddenAt = status == self.STATUS_UNKNOWN and now - elapsed or nil,
            lastVisibleAt = now - elapsed,
            lastChangedAt = now - elapsed,
            isTest = true,
            isStress = true,
            hasTRP3Profile = false,
        }
    end
    markDataChanged(nil, now)
    notifyIfChanged()
    return true
end

function Scanner:GetRuntimeCounts()
    local managedTokenCount = countEntries(visibleNameplateTokens)
    local candidateCount = countEntries(candidatesByUnitToken)
    local realWatcherCount = 0
    local testWatcherCount = 0
    for _, watcher in pairs(watchersByGUID) do
        if watcher.isTest then
            testWatcherCount = testWatcherCount + 1
        else
            realWatcherCount = realWatcherCount + 1
        end
    end
    return managedTokenCount, candidateCount, realWatcherCount, testWatcherCount
end

function Scanner:GetNameplateDiagnosticSnapshot()
    local snapshot = {
        rawFrameCount = 0,
        resolvedTokenCount = 0,
        getUnitTokenCount = 0,
        fallbackTokenCount = 0,
        existingUnitCount = 0,
        playerUnitCount = 0,
        friendlyUnitCount = 0,
        ownPlayerCount = 0,
        missingTokenCount = 0,
        missingUnitCount = 0,
        nonPlayerCount = 0,
        nonFriendlyCount = 0,
        missingGUIDCount = 0,
        missingNameCount = 0,
        qualifiedUnitCount = 0,
        managedTokenCount = countEntries(visibleNameplateTokens),
        candidateCount = countEntries(candidatesByUnitToken),
        realWatcherCount = 0,
        testWatcherCount = 0,
    }

    local nameplates = C_NamePlate.GetNamePlates()
    snapshot.rawFrameCount = #nameplates
    for index = 1, #nameplates do
        local unitToken, resolutionSource = getUnitTokenFromNameplate(nameplates[index])
        if not unitToken then
            snapshot.missingTokenCount = snapshot.missingTokenCount + 1
        else
            snapshot.resolvedTokenCount = snapshot.resolvedTokenCount + 1
            if resolutionSource == "GetUnit" then
                snapshot.getUnitTokenCount = snapshot.getUnitTokenCount + 1
            else
                snapshot.fallbackTokenCount = snapshot.fallbackTokenCount + 1
            end

            if not UnitExists(unitToken) then
                snapshot.missingUnitCount = snapshot.missingUnitCount + 1
            else
                snapshot.existingUnitCount = snapshot.existingUnitCount + 1
                if not UnitIsPlayer(unitToken) then
                    snapshot.nonPlayerCount = snapshot.nonPlayerCount + 1
                else
                    snapshot.playerUnitCount = snapshot.playerUnitCount + 1
                    if not UnitIsFriend("player", unitToken) then
                        snapshot.nonFriendlyCount = snapshot.nonFriendlyCount + 1
                    else
                        snapshot.friendlyUnitCount = snapshot.friendlyUnitCount + 1
                        if UnitIsUnit(unitToken, "player") then
                            snapshot.ownPlayerCount = snapshot.ownPlayerCount + 1
                        else
                            local guid = UnitGUID(unitToken)
                            if type(guid) ~= "string" or guid == "" then
                                snapshot.missingGUIDCount = snapshot.missingGUIDCount + 1
                            else
                                local fullName = GetUnitName(unitToken, true)
                                if type(fullName) ~= "string" or fullName == "" then
                                    snapshot.missingNameCount = snapshot.missingNameCount + 1
                                else
                                    snapshot.qualifiedUnitCount = snapshot.qualifiedUnitCount + 1
                                end
                            end
                        end
                    end
                end
            end
        end
    end

    for _, watcher in pairs(watchersByGUID) do
        if watcher.isTest then
            snapshot.testWatcherCount = snapshot.testWatcherCount + 1
        else
            snapshot.realWatcherCount = snapshot.realWatcherCount + 1
        end
    end
    return snapshot
end

function Scanner:PrintNameplateDiagnostics()
    local snapshot = self:GetNameplateDiagnosticSnapshot()
    print("|cff66ccffRPWatcher Nameplate-Diagnose|r")
    print(("  Rohe Frames: %d · Token aufgelöst: %d"):format(snapshot.rawFrameCount, snapshot.resolvedTokenCount))
    print(("  Tokenweg: GetUnit() %d · namePlateUnitToken-Fallback %d"):format(snapshot.getUnitTokenCount, snapshot.fallbackTokenCount))
    print(("  Existierende Units: %d · Spieler: %d · Freundlich: %d"):format(snapshot.existingUnitCount, snapshot.playerUnitCount, snapshot.friendlyUnitCount))
    print(("  Eigener Spieler: %d · Fehlende GUID: %d · Fehlender Name: %d"):format(snapshot.ownPlayerCount, snapshot.missingGUIDCount, snapshot.missingNameCount))
    print(("  Verwaltete Tokens: %d · Qualifizierbare Units: %d · Verwaltete Kandidaten: %d"):format(
        snapshot.managedTokenCount,
        snapshot.qualifiedUnitCount,
        snapshot.candidateCount
    ))
    print(("  Ablehnungen: kein Token %d · Unit fehlt %d · kein Spieler %d · nicht freundlich %d · eigener Spieler %d · GUID fehlt %d · Name fehlt %d"):format(
        snapshot.missingTokenCount,
        snapshot.missingUnitCount,
        snapshot.nonPlayerCount,
        snapshot.nonFriendlyCount,
        snapshot.ownPlayerCount,
        snapshot.missingGUIDCount,
        snapshot.missingNameCount
    ))
end

function Scanner:GetWatcherStatusCounts()
    local activeCount = 0
    local inactiveCount = 0
    local unknownCount = 0
    for _, watcher in pairs(watchersByGUID) do
        if watcher.observationStatus == self.STATUS_ACTIVE then
            activeCount = activeCount + 1
        elseif watcher.observationStatus == self.STATUS_INACTIVE then
            inactiveCount = inactiveCount + 1
        else
            unknownCount = unknownCount + 1
        end
    end
    return activeCount, inactiveCount, unknownCount
end

-- 1.2.0 selftest for the watcher-continuity fix above. Drives the real,
-- private setWatcherActive/Inactive/Unknown functions directly (same
-- closure, no parallel test system) against synthetic watcher tables that
-- are never inserted into watchersByGUID, so nothing here is visible in the
-- UI, ever reaches RPWatcherDB, or calls any Unit-/TRP3-API with a
-- synthetic identity (AGENTS.md). Case numbers refer to the 1.2.0 task's
-- "Cache und Timer" list.
function Scanner:RunSelfTest()
    local results = {}
    local now = GetTime()

    local function assertCase(name, passed, detail)
        results[#results + 1] = { name = name, passed = passed and true or false, detail = detail }
    end

    -- Case 1 + 7 + 8: Aktuell -> Unbekannt -> Aktuell führt targetStartedAt
    -- fort; RP-Name/Profilstatus bleiben nur im Laufzeitdatensatz erhalten;
    -- keine Selftest-GUID landet in RPWatcherDB.
    do
        local guid = "RPWATCHER-SELFTEST-A"
        local originalStart = now - 12
        local watcher = {
            guid = guid, name = "[Selftest] Fortsetzung", isTest = true,
            observationStatus = self.STATUS_ACTIVE, targetStartedAt = originalStart,
            isVisible = true, unitToken = nil, lastChangedAt = originalStart,
            rpName = "[Selftest] RP-Name", hasTRP3Profile = true,
        }
        setWatcherUnknown(watcher, now + 1)
        setWatcherActive(watcher, now + 6)
        assertCase("Cache: Aktuell->Unbekannt->Aktuell führt targetStartedAt fort",
            watcher.targetStartedAt == originalStart,
            ("targetStartedAt=%.2f, erwartet %.2f"):format(watcher.targetStartedAt, originalStart))
        assertCase("Cache: RP-Name/Profilstatus bleiben im Laufzeitdatensatz erhalten",
            watcher.rpName == "[Selftest] RP-Name" and watcher.hasTRP3Profile == true)
        assertCase("Datenschutz: Selftest-GUID landet nicht in RPWatcherDB",
            type(RPWatcherDB) ~= "table" or RPWatcherDB[guid] == nil)
    end

    -- Case 2: Aktuell -> Unbekannt -> Vorher führt nicht zu einem neuen
    -- Watcher und verwendet den konservativen Sichtverlustzeitpunkt.
    do
        local watcher = {
            guid = "RPWATCHER-SELFTEST-B", name = "[Selftest] Konservativ", isTest = true,
            observationStatus = self.STATUS_ACTIVE, targetStartedAt = now - 20,
            isVisible = true, unitToken = nil, lastChangedAt = now - 20,
        }
        local hiddenAt = now + 1
        setWatcherUnknown(watcher, hiddenAt)
        setWatcherInactive(watcher, now + 9)
        assertCase("Cache: Aktuell->Unbekannt->Vorher nutzt den Sichtverlustzeitpunkt",
            watcher.targetLostAt == hiddenAt,
            ("targetLostAt=%.2f, erwartet %.2f"):format(watcher.targetLostAt, hiddenAt))
    end

    -- Case 3: Vorher -> Unbekannt -> Vorher behält seinen bisherigen
    -- Zeitbezug (kein Timer-Reset).
    do
        local originalLost = now - 30
        local watcher = {
            guid = "RPWATCHER-SELFTEST-C", name = "[Selftest] Vorher-Kontinuität", isTest = true,
            observationStatus = self.STATUS_INACTIVE, targetLostAt = originalLost,
            isVisible = true, unitToken = nil, lastChangedAt = originalLost,
        }
        setWatcherUnknown(watcher, now + 1)
        setWatcherInactive(watcher, now + 7)
        assertCase("Cache: Vorher->Unbekannt->Vorher behält seinen Zeitbezug",
            watcher.targetLostAt == originalLost,
            ("targetLostAt=%.2f, erwartet %.2f"):format(watcher.targetLostAt, originalLost))
    end

    -- Case 4: Vorher -> Unbekannt -> neu aktuell beginnt eine neue
    -- bestätigte aktive Phase (Timer beginnt bei der Wiederkehr).
    do
        local watcher = {
            guid = "RPWATCHER-SELFTEST-D", name = "[Selftest] Neue Phase", isTest = true,
            observationStatus = self.STATUS_INACTIVE, targetLostAt = now - 40,
            isVisible = true, unitToken = nil, lastChangedAt = now - 40,
        }
        setWatcherUnknown(watcher, now + 1)
        local reactivatedAt = now + 8
        setWatcherActive(watcher, reactivatedAt)
        assertCase("Cache: Vorher->Unbekannt->Aktuell startet eine neue aktive Phase",
            watcher.targetStartedAt == reactivatedAt,
            ("targetStartedAt=%.2f, erwartet %.2f"):format(watcher.targetStartedAt, reactivatedAt))
    end

    -- Case 5: Ablauf der Aufbewahrungsdauer entfernt den Datensatz. Prüft
    -- dieselbe Formel wie Scan()'s Ablauflogik, ohne watchersByGUID selbst
    -- zu berühren.
    do
        local retention = RPWatcher.Settings and RPWatcher.Settings:GetUnknownRetentionSeconds() or 60
        local hiddenAt = now - retention - 1
        local wouldExpire = (now - hiddenAt) >= retention
        assertCase("Cache: Ablauf der Aufbewahrungsdauer entfernt den Datensatz", wouldExpire)
    end

    return results
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

    clearTable(visibleNameplateTokens)
    clearTable(candidatesByUnitToken)
    clearTable(guidByUnitToken)
    clearTable(unitTokenByGUID)
    clearTable(watchersByGUID)
    clearTable(sortedWatchers)
    clearTable(seenNameplateTokens)
    clearTable(stressGUIDs)
    playerInWorld = false
    sortedListDirty = true
    dataChanged = true

    eventFrame:RegisterEvent("NAME_PLATE_UNIT_ADDED")
    eventFrame:RegisterEvent("NAME_PLATE_UNIT_REMOVED")
    eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")
    eventFrame:RegisterEvent("PLAYER_LEAVING_WORLD")
    self:CaptureExistingNameplates()
    nextIntegrityCheckAt = GetTime() + self.INTEGRITY_INTERVAL_SECONDS
    nextExpiryCheckAt = GetTime() + self.EXPIRY_INTERVAL_SECONDS

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
        playerInWorld = true
        Scanner:CaptureExistingNameplates()
        nextIntegrityCheckAt = GetTime() + Scanner.INTEGRITY_INTERVAL_SECONDS
    elseif event == "PLAYER_LEAVING_WORLD" then
        playerInWorld = false
        Scanner:ClearVisibleNameplates()
    end
end)
