local addonName, RPWatcher = ...

RPWatcher = RPWatcher or {}

local Core = {}
RPWatcher.Core = Core

local L = RPWatcher.L

function Core:GetWindowState()
    return RPWatcher.Settings and RPWatcher.Settings:GetWindowState()
end

function Core:SaveWindowVisibility(isShown)
    if RPWatcher.Settings then
        RPWatcher.Settings:SetWindowManuallyShown(isShown)
    end
end

function Core:SaveWindowPosition(point, relativePoint, x, y)
    if RPWatcher.Settings then
        RPWatcher.Settings:SaveWindowPosition(point, relativePoint, x, y)
    end
end

function Core:ToggleWindow()
    if RPWatcher.UI then
        RPWatcher.UI:ToggleManualVisibility()
    end
end

function Core:PrintHelp()
    print("|cff66ccffRPWatcher|r " .. L.HELP_HEADER)
    print("  " .. L.HELP_TOGGLE)
    print("  " .. L.HELP_TEST)
    print("  " .. L.HELP_CLEAR)
    print("  " .. L.HELP_HELP)
    print("  " .. L.HELP_TRP3)
    print("  " .. L.HELP_REFRESH)
    print("  " .. L.HELP_OPTIONS)
    print("  " .. L.HELP_LOCK)
    print("  " .. L.HELP_UNLOCK)
    print("  " .. L.HELP_RESET)
    print("  " .. L.HELP_PERF)
    print("  " .. L.HELP_PLATES)
    print("  " .. L.HELP_STRESS)
    print("  " .. L.HELP_SELFTEST)
end

-- 1.2.0: aggregates each module's own RunSelfTest() (Theme, Scanner, UI)
-- rather than introducing a separate test system, mirroring how
-- Performance:PrintReport()/Scanner:PrintNameplateDiagnostics() already
-- report on their own module's state. All cases are synthetic and
-- non-persistent; see each module's RunSelfTest for what it covers.
function Core:RunSelfTest()
    local allResults = {}
    local function collect(module)
        if module and module.RunSelfTest then
            for _, result in ipairs(module:RunSelfTest()) do
                allResults[#allResults + 1] = result
            end
        end
    end
    collect(RPWatcher.Localization)
    collect(RPWatcher.Theme)
    collect(RPWatcher.Scanner)
    collect(RPWatcher.UI)

    local passCount, failCount = 0, 0
    print("|cff66ccff" .. L.SELFTEST_HEADER .. "|r")
    for _, result in ipairs(allResults) do
        if result.passed then
            passCount = passCount + 1
            print(("  |cff33ff33%s|r %s"):format(L.SELFTEST_OK, result.name))
        else
            failCount = failCount + 1
            print(("  |cffff3333%s|r %s%s"):format(L.SELFTEST_FAIL, result.name, result.detail and (" - " .. result.detail) or ""))
        end
    end
    print("|cff66ccffRPWatcher|r " .. RPWatcher.Localization:Format("SELFTEST_SUMMARY", passCount, failCount))
end

function Core:HandleSlashCommand(message)
    local command = type(message) == "string" and message:match("^%s*(.-)%s*$") or ""
    command = command:lower()

    if command == "" then
        self:ToggleWindow()
    elseif command == "test" then
        if RPWatcher.Scanner then
            RPWatcher.Scanner:AddTestData()
        end
        if RPWatcher.UI then
            RPWatcher.UI:SetManualVisibility(true)
        end
        print("|cff66ccffRPWatcher|r: " .. L.CHAT_TEST_CREATED)
    elseif command == "clear" then
        if RPWatcher.Scanner then
            RPWatcher.Scanner:ClearWatchers()
        end
        print("|cff66ccffRPWatcher|r: " .. L.CHAT_WATCHERS_CLEARED)
    elseif command == "help" then
        self:PrintHelp()
    elseif command == "trp3" then
        if RPWatcher.TRP3 then
            RPWatcher.TRP3:PrintDiagnostics()
        end
    elseif command == "refresh" then
        if RPWatcher.TRP3 then
            local checked, requested, cooldown = RPWatcher.TRP3:RefreshAllWatchers(true)
            print("|cff66ccffRPWatcher|r: " .. RPWatcher.Localization:Format("CHAT_REFRESH_RESULT", checked, requested, cooldown))
        end
    elseif command == "options" then
        if not RPWatcher.Settings or not RPWatcher.Settings:OpenOptions() then
            print("|cff66ccffRPWatcher|r: " .. L.CHAT_OPTIONS_OPEN_FAILED)
        end
    elseif command == "lock" then
        if RPWatcher.Settings then
            RPWatcher.Settings:SetWindowLocked(true)
        end
        print("|cff66ccffRPWatcher|r: " .. L.CHAT_WINDOW_LOCKED)
    elseif command == "unlock" then
        if RPWatcher.Settings then
            RPWatcher.Settings:SetWindowLocked(false)
        end
        print("|cff66ccffRPWatcher|r: " .. L.CHAT_WINDOW_UNLOCKED)
    elseif command == "reset" then
        if RPWatcher.Settings then
            RPWatcher.Settings:ResetWindowSettings()
        end
        print("|cff66ccffRPWatcher|r: " .. L.CHAT_WINDOW_RESET)
    elseif command == "perf" or command:match("^perf%s+") then
        if RPWatcher.Performance then
            RPWatcher.Performance:HandleCommand(command:match("^perf%s*(.*)$") or "")
        end
    elseif command == "plates" then
        if RPWatcher.Scanner and RPWatcher.Scanner.PrintNameplateDiagnostics then
            RPWatcher.Scanner:PrintNameplateDiagnostics()
        end
    elseif command == "stress" or command:match("^stress%s+") then
        local argument = command:match("^stress%s*(.*)$") or ""
        if argument == "clear" then
            local removed = RPWatcher.Scanner and RPWatcher.Scanner:RemoveStressData() or 0
            print("|cff66ccffRPWatcher|r: " .. RPWatcher.Localization:Format("CHAT_STRESS_REMOVED", removed))
        else
            local count = tonumber(argument)
            if RPWatcher.Scanner and RPWatcher.Scanner:AddStressData(count) then
                if RPWatcher.UI then
                    RPWatcher.UI:SetManualVisibility(true)
                end
                print("|cff66ccffRPWatcher|r: " .. RPWatcher.Localization:Format("CHAT_STRESS_CREATED", count))
            else
                print("|cff66ccffRPWatcher|r: " .. L.CHAT_STRESS_USAGE)
            end
        end
    elseif command == "selftest" then
        self:RunSelfTest()
    else
        print("|cff66ccffRPWatcher|r: " .. L.CHAT_UNKNOWN_COMMAND)
        self:PrintHelp()
    end
end

function Core:Initialize()
    if RPWatcher.Performance then
        RPWatcher.Performance:Initialize()
    end

    if RPWatcher.Settings then
        RPWatcher.Settings:Initialize()
    end

    if RPWatcher.TRP3 then
        RPWatcher.TRP3:Initialize()
    end

    if RPWatcher.UI then
        RPWatcher.UI:Initialize()
    end

    if RPWatcher.Minimap then
        RPWatcher.Minimap:Initialize()
    end

    if RPWatcher.Scanner then
        RPWatcher.Scanner:Initialize()
    end

    if RPWatcher.UI then
        RPWatcher.UI:RestoreState()
        RPWatcher.UI:RefreshWatcherList()
    end

    print("|cff66ccff" .. addonName .. "|r " .. L.CHAT_LOADED)
end

local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("ADDON_LOADED")
eventFrame:SetScript("OnEvent", function(_, event, loadedAddonName)
    if event == "ADDON_LOADED" and loadedAddonName == addonName then
        Core:Initialize()
        eventFrame:UnregisterEvent("ADDON_LOADED")
    end
end)

SLASH_RPWATCHER1 = "/rpw"
SLASH_RPWATCHER2 = "/rpwatcher"
SlashCmdList.RPWATCHER = function(message)
    Core:HandleSlashCommand(message)
end
