local _, RPWatcher = ...

local Performance = {}
RPWatcher.Performance = Performance

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
        return ("%.1f Sek."):format(seconds)
    end

    local minutes = math.floor(seconds / 60)
    local remainingSeconds = math.floor(seconds % 60)
    if minutes < 60 then
        return ("%d Min. %d Sek."):format(minutes, remainingSeconds)
    end

    local hours = math.floor(minutes / 60)
    return ("%d Std. %d Min."):format(hours, minutes % 60)
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
    print("  /rpw perf on - Messwerte zurücksetzen und Messung aktivieren")
    print("  /rpw perf off - Messung anhalten und Werte behalten")
    print("  /rpw perf reset - Messwerte zurücksetzen")
    print("  /rpw perf report - kompakten Bericht ausgeben")
end

function Performance:PrintReport()
    local nameplates, candidates, realWatchers, testWatchers = 0, 0, 0, 0
    if RPWatcher.Scanner and RPWatcher.Scanner.GetRuntimeCounts then
        nameplates, candidates, realWatchers, testWatchers = RPWatcher.Scanner:GetRuntimeCounts()
    end

    local average = metrics.scanCount > 0 and metrics.totalScanMilliseconds / metrics.scanCount or 0
    print("|cff66ccffRPWatcher Performance|r")
    print("  Messung: " .. (enabled and "an" or "aus") .. " · Dauer: " .. formatDuration(self:GetDuration()))
    print(("  Scans: %d · Kandidaten geprüft: %d"):format(metrics.scanCount, metrics.candidatesChecked))
    print(("  Scanzeit gesamt: %.3f ms · Ø: %.3f ms · Maximum: %.3f ms"):format(metrics.totalScanMilliseconds, average, metrics.maximumScanMilliseconds))
    print(("  Nameplates: %d · Kandidaten: %d"):format(nameplates, candidates))
    print(("  Watcher: %d echt · %d Test/Stress"):format(realWatchers, testWatchers))
    print(("  Statuswechsel: %d · erzeugt: %d · entfernt: %d"):format(metrics.statusChanges, metrics.watchersCreated, metrics.watchersRemoved))
    print(("  UI-Aktualisierungen: %d Daten · %d Zeit"):format(metrics.uiDataUpdates, metrics.uiTimeUpdates))
    print(("  TRP3-Anfragen: %d versendet · %d übersprungen/gedrosselt"):format(metrics.trp3RequestsSent, metrics.trp3RequestsSkipped))
end

function Performance:HandleCommand(argument)
    argument = type(argument) == "string" and argument:match("^%s*(.-)%s*$"):lower() or ""
    if argument == "" then
        print("|cff66ccffRPWatcher|r: Performance-Messung ist " .. (enabled and "aktiv." or "deaktiviert."))
        self:PrintHelp()
    elseif argument == "on" then
        if type(debugprofilestop) ~= "function" then
            print("|cff66ccffRPWatcher|r: Die Performance-Messfunktion ist nicht verfügbar.")
            return
        end
        self:SetEnabled(true)
        print("|cff66ccffRPWatcher|r: Performance-Messung aktiviert und zurückgesetzt.")
    elseif argument == "off" then
        self:SetEnabled(false)
        print("|cff66ccffRPWatcher|r: Performance-Messung deaktiviert; Messwerte bleiben erhalten.")
    elseif argument == "reset" then
        self:Reset()
        print("|cff66ccffRPWatcher|r: Performance-Messwerte wurden zurückgesetzt.")
    elseif argument == "report" then
        self:PrintReport()
    else
        print("|cff66ccffRPWatcher|r: Unbekannter perf-Befehl.")
        self:PrintHelp()
    end
end
