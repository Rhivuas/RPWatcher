# Datenschutz bei RPWatcher

Stand: Version 0.9.0 Release Candidate

RPWatcher ist ein lokal im World-of-Warcraft-Client ausgeführtes Addon.

## Keine externen Dienste

- RPWatcher baut keine eigenständigen externen Netzwerkverbindungen auf.
- Es gibt keine Telemetrie.
- Es gibt keine Analyse-, Tracking- oder Werbedienste.
- RPWatcher übermittelt keine Daten an den Autor oder andere externe Anbieter.

## Nicht dauerhaft gespeicherte Daten

RPWatcher speichert nicht dauerhaft:

- Watcher oder eine Watcher-Historie,
- fremde Spieler-GUIDs,
- fremde RP-Namen,
- Total-RP-3-Profiltexte,
- Target-Historien,
- Performance-Messwerte,
- Stress- oder Testdaten,
- TRP3-Anfragewarteschlangen.

Diese Informationen existieren nur während der aktuellen Spielsitzung im Arbeitsspeicher und werden durch Reload, Logout oder Neustart verworfen.

## SavedVariables

`RPWatcherDB` enthält ausschließlich eigene Addon-, Fenster- und Benutzereinstellungen:

- manuell gewünschte Fenstersichtbarkeit,
- Fensterposition und -größe,
- Skalierung und Hintergrundtransparenz,
- Sperrstatus,
- Aufbewahrungsdauer unbekannter Watcher,
- Auto-Ausblendung,
- Anzeigeeinstellung des TRP3-Profilbuttons,
- Datenbankschema-Version.

Es werden keine fremden Charakter- oder Profildaten in `RPWatcherDB` geschrieben.

## Optionale Total-RP-3-Integration

Ist Total RP 3 installiert, verwendet RPWatcher ausschließlich dessen lokale Addon-Integration im Spiel, um einen Anzeigenamen anzufragen oder ein Profilfenster zu öffnen. Die eigentliche Ingame-Addonkommunikation wird von Total RP 3 über die von WoW bereitgestellten Mechanismen durchgeführt.

RPWatcher liest nur den für die Anzeige benötigten RP-Namen und speichert keine Profiltexte. Test- und Stressdaten lösen keine Total-RP-3-Kommunikation aus.

## Fehlerberichte

Für Support werden keine Accountdaten, GUIDs oder vollständigen RP-Profile benötigt. Diagnoseausgaben von `/rpw plates` und `/rpw perf report` enthalten keine Namens- oder GUID-Listen.
