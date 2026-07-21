# RPWatcher

## Sehr kurze Zusammenfassung

Zeigt freundliche Spieler, die dich über eine sichtbare Nameplate aktuell oder zuvor im Target hatten – optional mit Total-RP-3-RP-Namen und Profilöffnung.

## Beschreibung

RPWatcher ist ein deutschsprachiges World-of-Warcraft-Retail-Addon für Rollenspielerinnen und Rollenspieler. Es beobachtet ausschließlich freundliche Spielercharaktere mit aktuell API-verfügbarer sichtbarer Nameplate. Sobald ein Spieler dich mindestens einmal im Target hatte, erscheint er in einer übersichtlichen, virtualisierten Liste.

RPWatcher unterscheidet drei Zustände: aktuell im Target, zuvor im Target und unbekannt, wenn die Nameplate nicht mehr sichtbar ist. Laufende Zeitangaben zeigen, wie lange der aktuelle Vorgang besteht beziehungsweise wie lange der letzte Wechsel zurückliegt.

Die Oberfläche ist dunkel, kompakt und an moderne WoW-/TRP3-Dialoge angelehnt. Fensterposition, Größe, Skalierung, Transparenz und Sperrstatus sind einstellbar. Eine optionale Total-RP-3-Integration ergänzt bekannte RP-Namen und eine lokale Profilöffnung.

## Features

- freundliche Spieler mit sichtbarer Nameplate als einzige Erfassungsquelle
- Aufnahme erst nach einem bestätigten Target-Vorgang
- GUID-basierte Wiedererkennung ohne Duplikate
- Grün/Aktuell, Grau/Vorher und Fragezeichen/Unbekannt
- konfigurierbare Aufbewahrung unbekannter Watcher
- skalierbares, verschiebbares und sperrbares Fenster
- automatische Ausblendung bei leerer Liste
- virtualisierte Liste für größere Watchermengen
- optionale Total-RP-3-RP-Namen und Profilöffnung
- gedrosselte Profilanfragen
- nicht persistente Nameplate-, Performance- und Stresstestdiagnose

## Technische Grenzen

RPWatcher erkennt Target-Auswahl – keine Blickrichtung. Nur von der WoW-API bereitgestellte sichtbare Nameplate-Units können live geprüft werden. Sehr kurze Target-Wechsel können zwischen zwei Scans liegen. Ohne sichtbare Nameplate bleibt der tatsächliche Target-Status unbekannt.

## Total RP 3

Total RP 3 ist optional und wird nicht mitgeliefert. Ohne Total RP 3 verwendet RPWatcher den vollständigen normalen WoW-Namen und bleibt vollständig funktionsfähig.

## Datenschutz

Keine Telemetrie, Werbung oder externen Dienste. Watcher, fremde GUIDs, RP-Namen, Profile und Diagnosewerte werden nicht dauerhaft gespeichert. `RPWatcherDB` enthält nur eigene Fenster- und Benutzereinstellungen.

## Installation

Den Ordner `RPWatcher` aus `RPWatcher-1.0.0.zip` nach `World of Warcraft\_retail_\Interface\AddOns\` kopieren und das Spiel neu starten. Freundliche Nameplates müssen für reale Erfassung aktiviert sein.

## Support

Fehlerberichte sollten Versionen, Reproduktionsschritte, Erwartung, tatsächliches Verhalten, BugSack-Ausgabe und bei Bedarf `/rpw plates` beziehungsweise `/rpw perf report` enthalten. Keine Accountdaten, GUIDs oder vollständigen RP-Profile einsenden.

## Lizenz

MIT License. Copyright 2026 Mercia.
