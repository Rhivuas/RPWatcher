local _, RPWatcher = ...

local Performance = {}
RPWatcher.Performance = Performance

local L = RPWatcher.L

local enabled = false
local startedAt
local stoppedAt

local metrics = {
    scanCount = 0,
    totalScanMilliseconds = 0,
    maximumScanMilliseconds = 0,
    candidatesChecked = 0,
    statusChanges = 0,
    watchersCreated = 0,
    watchersRemoved = 0,
    uiDataUpdates = 0,
    uiTimeUpdates = 0,
    trp3RequestsSent = 0,
    trp3RequestsSkipped = 0,
}

local function resetMetrics()
    metrics.scanCount = 0
    metrics.totalScanMilliseconds = 0
    metrics.maximumScanMilliseconds = 0
    metrics.candidatesChecked = 0
    metrics.statusChanges = 0
    metrics.watchersCreated = 0
    metrics.watchersRemoved = 0
    metrics.uiDataUpdates = 0
    metrics.uiTimeUpdates = 0
    metrics.trp3RequestsSent = 0
    metrics.trp3RequestsSkipped = 0

    if enabled then
        startedAt = GetTime()
        stoppedAt = nil
    else
        startedAt = nil
        stoppedAt = nil
    end
end

local function formatDuration(seconds)
    seconds = math.max(0, seconds or 0)
    if seconds < 60 then
        return RPWatcher.Localization:Format("PERF_DURATION_SECONDS", seconds)
    end

    local minutes = math.floor(seconds / 60)
    local remainingSeconds = math.floor(seconds % 60)
    if minutes < 60 then
        return RPWatcher.Localization:Format("PERF_DURATION_MINUTES_SECONDS", minutes, remainingSeconds)
    end

    local hours = math.floor(minutes / 60)
    return RPWatcher.Localization:Format("PERF_DURATION_HOURS_MINUTES", hours, minutes % 60)
end

function Performance:Initialize()
    enabled = false
    resetMetrics()
end

function Performance:IsEnabled()
    return enabled
end

function Performance:StartScanMeasurement()
    return debugprofilestop()
end

function Performance:RecordScan(startMilliseconds, candidatesChecked)
    if not enabled then
        return
    end

    local elapsed = debugprofilestop() - startMilliseconds
    metrics.scanCount = metrics.scanCount + 1
    metrics.totalScanMilliseconds = metrics.totalScanMilliseconds + elapsed
    metrics.maximumScanMilliseconds = math.max(metrics.maximumScanMilliseconds, elapsed)
    metrics.candidatesChecked = metrics.candidatesChecked + (candidatesChecked or 0)
end

function Performance:RecordStatusChange()
    if enabled then
        metrics.statusChanges = metrics.statusChanges + 1
    end
end

function Performance:RecordWatcherCreated()
    if enabled then
        metrics.watchersCreated = metrics.watchersCreated + 1
    end
end

function Performance:RecordWatcherRemoved(count)
    if enabled then
        metrics.watchersRemoved = metrics.watchersRemoved + (count or 1)
    end
end

function Performance:RecordUIDataUpdate()
    if enabled then
        metrics.uiDataUpdates = metrics.uiDataUpdates + 1
    end
end

function Performance:RecordUITimeUpdate()
    if enabled then
        metrics.uiTimeUpdates = metrics.uiTimeUpdates + 1
    end
end

function Performance:RecordTRP3RequestSent()
    if enabled then
        metrics.trp3RequestsSent = metrics.trp3RequestsSent + 1
    end
end

function Performance:RecordTRP3RequestSkipped()
    if enabled then
        metrics.trp3RequestsSkipped = metrics.trp3RequestsSkipped + 1
    end
end

function Performance:Reset()
    resetMetrics()
end

function Performance:SetEnabled(shouldEnable)
    shouldEnable = shouldEnable and true or false
    if shouldEnable then
        enabled = true
        resetMetrics()
    elseif enabled then
        stoppedAt = GetTime()
        enabled = false
    end
end

function Performance:GetDuration()
    if not startedAt then
        return 0
    end
    return math.max(0, (enabled and GetTime() or stoppedAt or startedAt) - startedAt)
end

function Performance:PrintHelp()
    print("  " .. L.PERF_HELP_ON)
    print("  " .. L.PERF_HELP_OFF)
    print("  " .. L.PERF_HELP_RESET)
    print("  " .. L.PERF_HELP_REPORT)
end

function Performance:PrintReport()
    local rawFrames, resolvedTokens, managedTokens, candidates = 0, 0, 0, 0
    local realWatchers, testWatchers = 0, 0
    if RPWatcher.Scanner and RPWatcher.Scanner.GetNameplateDiagnosticSnapshot then
        local snapshot = RPWatcher.Scanner:GetNameplateDiagnosticSnapshot()
        rawFrames = snapshot.rawFrameCount
        resolvedTokens = snapshot.resolvedTokenCount
        managedTokens = snapshot.managedTokenCount
        candidates = snapshot.candidateCount
        realWatchers = snapshot.realWatcherCount
        testWatchers = snapshot.testWatcherCount
    end

    local average = metrics.scanCount > 0 and metrics.totalScanMilliseconds / metrics.scanCount or 0
    local Localization = RPWatcher.Localization
    print("|cff66ccff" .. L.PERF_REPORT_HEADER .. "|r")
    print("  " .. Localization:Format("PERF_STATUS_LINE", enabled and L.PERF_STATUS_ON or L.PERF_STATUS_OFF, formatDuration(self:GetDuration())))
    print("  " .. Localization:Format("PERF_SCANS_LINE", metrics.scanCount, metrics.candidatesChecked))
    print("  " .. Localization:Format("PERF_SCANTIME_LINE", metrics.totalScanMilliseconds, average, metrics.maximumScanMilliseconds))
    print("  " .. Localization:Format("PERF_RAWFRAMES_LINE", rawFrames, resolvedTokens))
    print("  " .. Localization:Format("PERF_MANAGEDTOKENS_LINE", managedTokens, candidates))
    print("  " .. Localization:Format("PERF_WATCHERS_LINE", realWatchers, testWatchers))
    print("  " .. Localization:Format("PERF_CHANGES_LINE", metrics.statusChanges, metrics.watchersCreated, metrics.watchersRemoved))
    print("  " .. Localization:Format("PERF_UIUPDATES_LINE", metrics.uiDataUpdates, metrics.uiTimeUpdates))
    print("  " .. Localization:Format("PERF_TRP3REQUESTS_LINE", metrics.trp3RequestsSent, metrics.trp3RequestsSkipped))
end

function Performance:HandleCommand(argument)
    argument = type(argument) == "string" and argument:match("^%s*(.-)%s*$"):lower() or ""
    if argument == "" then
        print("|cff66ccffRPWatcher|r: " .. (enabled and L.PERF_COMMAND_STATUS_ACTIVE or L.PERF_COMMAND_STATUS_DISABLED))
        self:PrintHelp()
    elseif argument == "on" then
        if type(debugprofilestop) ~= "function" then
            print("|cff66ccffRPWatcher|r: " .. L.PERF_UNAVAILABLE)
            return
        end
        self:SetEnabled(true)
        print("|cff66ccffRPWatcher|r: " .. L.PERF_ENABLED)
    elseif argument == "off" then
        self:SetEnabled(false)
        print("|cff66ccffRPWatcher|r: " .. L.PERF_DISABLED_KEEP)
    elseif argument == "reset" then
        self:Reset()
        print("|cff66ccffRPWatcher|r: " .. L.PERF_RESET_DONE)
    elseif argument == "report" then
        self:PrintReport()
    else
        print("|cff66ccffRPWatcher|r: " .. L.PERF_UNKNOWN_COMMAND)
        self:PrintHelp()
    end
end
