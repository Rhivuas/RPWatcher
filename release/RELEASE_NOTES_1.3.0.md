# RPWatcher 1.3.0

RPWatcher 1.3.0 ist ein Lokalisierungsupdate auf Basis der stabilen Version 1.2.0. Scanner-, Cache-, Kampf-Sichtbarkeits-, TRP3- und Datenschutzkern bleiben in ihrer Kernlogik unverändert.

## Neu in 1.3.0

- **Vollständige englische Benutzeroberfläche:** Hauptfenster, Statusübersicht, Tooltips, Optionsseite, Minimap-Tooltip, Slash-Hilfe, Diagnosebefehle und `/rpw selftest` sind jetzt vollständig auf Englisch verfügbar.
- **Deutsche Oberfläche bleibt vollständig erhalten:** Alle bisherigen deutschen Texte sind unverändert inhaltlich vorhanden, jetzt über einen zentralen deutschen Sprachkatalog statt fest eingebetteter Texte.
- **Automatische Sprachauswahl anhand des WoW-Clients:** RPWatcher liest `GetLocale()` beim Laden. Ein deutscher Client (`deDE`) zeigt die deutsche Oberfläche; `enUS`, `enGB` und jede andere beziehungsweise noch nicht unterstützte Sprache zeigen Englisch als vollständigen Fallback.
- **Keine neue Spracheinstellung nötig:** Es gibt keine manuelle Sprachauswahl, keinen Sprach-Slash-Befehl und keine gespeicherte Spracheinstellung. Die Sprache wird bei jedem Addonladen automatisch neu bestimmt.
- **Erweiterter Selbsttest:** `/rpw selftest` prüft jetzt zusätzlich die Lokalisierungskataloge: vorhandene enUS-/deDE-Kataloge, vollständiger und identischer Schlüsselsatz, keine leeren Werte, identische Formatplatzhalter zwischen beiden Sprachen sowie korrektes Fallbackverhalten für enUS, enGB, deDE und unbekannte Locales.

## Unverändert

Nameplate-Erfassung, zentrale Tokenauflösung, Target-Erkennung, der 0,25-Sekunden-Scanner, der Fünf-Sekunden-Integritätsabgleich, GUID-basierte Watcherverwaltung, die 1.2.0-Watcher-Zeitfortführung bei kurzem Sichtverlust, Aufbewahrungslogik, Zonenwechselbehandlung, UI-Virtualisierung, die 1.1.1-nil-Absicherung, Kampf-Auto-Ausblendung, Frame-Strata LOW, Performance-Diagnose, Stress-Testdaten, die Minimap-Schaltfläche samt Drag-Verhalten, der TRP3-Profilbutton, TRP3-Anfrage-Cooldown und globale Drosselung sowie sämtliche Datenschutzprinzipien bleiben unverändert. Es gibt weiterhin genau einen dauerhaften Scanner-Ticker und kein zusätzliches permanentes `OnUpdate`.

## Datenschutz

Unverändert gegenüber 1.2.0: keine Telemetrie, keine externen Netzwerkzugriffe. `RPWatcherDB` enthält weiterhin ausschließlich eigene Fenster- und Benutzereinstellungen; das Datenbankschema bleibt bei Version 4. Die Sprachauswahl wird nicht gespeichert, nicht in `RPWatcherDB` geschrieben und beeinflusst keine technische Logik, Statusprüfung oder API-Nutzung. Total RP 3 bleibt vollständig optional.

## Installation

1. `RPWatcher-1.3.0.zip` entpacken.
2. Den enthaltenen Ordner `RPWatcher` nach `World of Warcraft\_retail_\Interface\AddOns\` kopieren.
3. Prüfen, dass `AddOns\RPWatcher\RPWatcher.toc` direkt existiert.
4. WoW starten und RPWatcher in der Addon-Liste aktivieren.

## Update von 1.2.0

WoW beenden und den vorhandenen Addonordner durch den Ordner aus dem neuen ZIP ersetzen. `RPWatcherDB` bleibt vollständig erhalten; das Datenbankschema bleibt unverändert bei Version 4. Bestehende Fenster-, Anzeige-, Kampf-, TRP3- und Minimap-Einstellungen bleiben vollständig erhalten. Die Oberflächensprache wird beim ersten Laden automatisch anhand des WoW-Clients bestimmt; es ist keine zusätzliche Einstellung nötig.

## Support

Fehlerberichte sollten RPWatcher- und WoW-Version, Total-RP-3-Version oder „deaktiviert“, Client-Sprache, Reproduktionsschritte, erwartetes und tatsächliches Verhalten sowie BugSack-Ausgaben enthalten. Bei Bedarf helfen `/rpw plates`, `/rpw perf report` und `/rpw selftest`. Keine Accountdaten, GUIDs oder vollständigen RP-Profile übermitteln.

## Lizenz

RPWatcher wird unter der MIT-Lizenz veröffentlicht. Copyright 2026 Mercia.
