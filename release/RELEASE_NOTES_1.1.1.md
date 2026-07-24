# RPWatcher 1.1.1

RPWatcher 1.1.1 ist ein reiner Hotfix ohne neue Funktion. Alle Funktionen aus 1.1.0 bleiben vollständig enthalten.

## Hotfix in 1.1.1

- Ein Lua-Laufzeitfehler in der virtualisierten Watcher-Liste wurde behoben. Betroffen war insbesondere der erste Watcher nach einer leeren Liste: die Liste konnte in diesem Moment kurzzeitig einen nicht vorhandenen Eintrag rendern wollen und einen Fehler auslösen.
- Synchrone Total-RP-3-Profilaktualisierungen konnten diesen Fehler sichtbar machen, waren aber nicht dessen Ursache.
- Es geht dabei kein gespeicherter Wert verloren. Fenster-, Benutzer- und Minimap-Einstellungen bleiben vollständig erhalten.
- Scanner-, Total-RP-3- und Datenschutzfunktion sind unverändert.

## Unverändert

Nameplate-Erfassung, zentrale Tokenauflösung, Target-Erkennung, der 0,25-Sekunden-Scanner, der Fünf-Sekunden-Integritätsabgleich, GUID-basierte Watcher, die Statuslogik, Aufbewahrungslogik, Zonenwechselbehandlung, UI-Virtualisierung, Performance-Diagnose, Stress-Testdaten, TRP3-Anfrage-Cooldown und globale Drosselung, die Minimap-Schaltfläche, der TRP3-Profilbutton sowie sämtliche Datenschutzprinzipien bleiben unverändert. Es gibt weiterhin genau einen dauerhaften Scanner-Ticker und kein dauerhaftes `OnUpdate`.

## Datenschutz

Unverändert gegenüber 1.1.0: keine Telemetrie, keine externen Netzwerkzugriffe. `RPWatcherDB` enthält weiterhin ausschließlich eigene Fenster- und Benutzereinstellungen.

## Installation

1. `RPWatcher-1.1.1.zip` entpacken.
2. Den enthaltenen Ordner `RPWatcher` nach `World of Warcraft\_retail_\Interface\AddOns\` kopieren.
3. Prüfen, dass `AddOns\RPWatcher\RPWatcher.toc` direkt existiert.
4. WoW starten und RPWatcher in der Addon-Liste aktivieren.

## Update von 1.1.0

WoW beenden und den vorhandenen Addonordner durch den Ordner aus dem neuen ZIP ersetzen. `RPWatcherDB` bleibt vollständig erhalten; das Datenbankschema ändert sich nicht (weiterhin Version 3).

## Support

Fehlerberichte sollten RPWatcher- und WoW-Version, Total-RP-3-Version oder „deaktiviert“, Reproduktionsschritte, erwartetes und tatsächliches Verhalten sowie BugSack-Ausgaben enthalten. Bei Bedarf helfen `/rpw plates` und `/rpw perf report`. Keine Accountdaten, GUIDs oder vollständigen RP-Profile übermitteln.

## Lizenz

RPWatcher wird unter der MIT-Lizenz veröffentlicht. Copyright 2026 Mercia.
