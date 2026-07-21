local addonName, RPWatcher = ...

RPWatcher = RPWatcher or {}

local Core = {}
RPWatcher.Core = Core

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
    print("|cff66ccffRPWatcher|r Befehle:")
    print("  /rpw - Fenster ein- oder ausblenden")
    print("  /rpw test - drei nicht persistente Testeinträge erzeugen")
    print("  /rpw clear - alle Laufzeit-Watcher und Testdaten entfernen")
    print("  /rpw help - diese Hilfe anzeigen")
    print("  /rpw trp3 - Status der optionalen TRP3-Integration anzeigen")
    print("  /rpw refresh - RP-Namen kontrolliert aktualisieren")
    print("  /rpw options - RPWatcher-Einstellungen öffnen")
    print("  /rpw lock - Fenster sperren")
    print("  /rpw unlock - Fenster entsperren")
    print("  /rpw reset - Position und Fensterdarstellung zurücksetzen")
    print("  /rpw perf [on|off|reset|report] - Laufzeitdiagnose steuern")
    print("  /rpw stress <25|50|100|200|clear> - synthetische Lastdaten verwalten")
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
        print("|cff66ccffRPWatcher|r: Drei Testeinträge wurden erzeugt.")
    elseif command == "clear" then
        if RPWatcher.Scanner then
            RPWatcher.Scanner:ClearWatchers()
        end
        print("|cff66ccffRPWatcher|r: Alle Laufzeit-Watcher und Testdaten wurden entfernt.")
    elseif command == "help" then
        self:PrintHelp()
    elseif command == "trp3" then
        if RPWatcher.TRP3 then
            RPWatcher.TRP3:PrintDiagnostics()
        end
    elseif command == "refresh" then
        if RPWatcher.TRP3 then
            local checked, requested, cooldown = RPWatcher.TRP3:RefreshAllWatchers(true)
            print(("|cff66ccffRPWatcher|r: %d echte Watcher geprüft, %d Profile angefragt, %d durch Abklingzeit übersprungen."):format(checked, requested, cooldown))
        end
    elseif command == "options" then
        if not RPWatcher.Settings or not RPWatcher.Settings:OpenOptions() then
            print("|cff66ccffRPWatcher|r: Die Einstellungsseite konnte nicht direkt geöffnet werden. Sie ist über Optionen > AddOns > RPWatcher erreichbar.")
        end
    elseif command == "lock" then
        if RPWatcher.Settings then
            RPWatcher.Settings:SetWindowLocked(true)
        end
        print("|cff66ccffRPWatcher|r: Fenster gesperrt.")
    elseif command == "unlock" then
        if RPWatcher.Settings then
            RPWatcher.Settings:SetWindowLocked(false)
        end
        print("|cff66ccffRPWatcher|r: Fenster entsperrt.")
    elseif command == "reset" then
        if RPWatcher.Settings then
            RPWatcher.Settings:ResetWindowSettings()
        end
        print("|cff66ccffRPWatcher|r: Fensterposition und Darstellung wurden zurückgesetzt.")
    elseif command == "perf" or command:match("^perf%s+") then
        if RPWatcher.Performance then
            RPWatcher.Performance:HandleCommand(command:match("^perf%s*(.*)$") or "")
        end
    elseif command == "stress" or command:match("^stress%s+") then
        local argument = command:match("^stress%s*(.*)$") or ""
        if argument == "clear" then
            local removed = RPWatcher.Scanner and RPWatcher.Scanner:RemoveStressData() or 0
            print(("|cff66ccffRPWatcher|r: %d Stress-Testeinträge wurden entfernt."):format(removed))
        else
            local count = tonumber(argument)
            if RPWatcher.Scanner and RPWatcher.Scanner:AddStressData(count) then
                if RPWatcher.UI then
                    RPWatcher.UI:SetManualVisibility(true)
                end
                print(("|cff66ccffRPWatcher|r: %d synthetische Stress-Testeinträge wurden erzeugt."):format(count))
            else
                print("|cff66ccffRPWatcher|r: Verwendung: /rpw stress 25|50|100|200|clear")
            end
        end
    else
        print("|cff66ccffRPWatcher|r: Unbekannter Befehl.")
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

    if RPWatcher.Scanner then
        RPWatcher.Scanner:Initialize()
    end

    if RPWatcher.UI then
        RPWatcher.UI:RestoreState()
        RPWatcher.UI:RefreshWatcherList()
    end

    print("|cff66ccff" .. addonName .. "|r wurde erfolgreich geladen. /rpw blendet das Fenster ein oder aus.")
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
