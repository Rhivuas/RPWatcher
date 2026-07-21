# RPWatcher 1.0.0

RPWatcher 1.0.0 ist die erste stabile öffentliche Version des deutschsprachigen World-of-Warcraft-Retail-Addons. Sie übernimmt den vollständig getesteten Funktionsumfang der stabilen Version 1.0.0 ohne neue Kernfunktionen.

## Wichtigste Funktionen

- Erkennung freundlicher Spielercharaktere über API-verfügbare sichtbare Nameplates
- Aufnahme erst nach mindestens einem erkannten Target-Vorgang
- Grün/Aktuell, Grau/Vorher und Fragezeichen/Unbekannt als eindeutige Statuszustände
- GUID-basierte Wiedererkennung ohne doppelte Watcher
- konfigurierbare Aufbewahrung unbekannter Watcher
- optionale Total-RP-3-RP-Namen mit normalem WoW-Namen als Fallback
- lokale TRP3-Profilöffnung ohne Veränderung des aktuellen Targets
- verschiebbares, skalierbares, größenveränderbares und sperrbares Fenster
- automatische Ausblendung bei leerer Liste
- virtualisierte Liste für größere Watchermengen
- Performance-, Nameplate- und synthetische Belastungsdiagnose
- eigenes RPWatcher-Addon- und Projekticon unter MIT

## Operative Härtung

Der schnelle Target-Scan prüft zwischengespeicherte, qualifizierte Kandidaten. Ein regelmäßiger Integritätsabgleich repariert verpasste Nameplate-Ereignisse und räumt veraltete Token-Zuordnungen auf. Zonen- und Ladewechsel bereinigen temporäre Tokens, ohne unnötig Watcherzustände zu verlieren. Es existiert genau ein zentraler gedrosselter Scanner-Ticker.

Profilanfragen über Total RP 3 sind pro GUID gedrosselt und zusätzlich global begrenzt. Test- und Stressdaten lösen keine Unit- oder TRP3-Kommunikation mit künstlichen Identitäten aus.

## Datenschutz

RPWatcher besitzt keine Telemetrie, Werbung oder eigenen externen Netzwerkzugriffe. Watcher, fremde GUIDs, RP-Namen, Profilzustände, Performancewerte und Stressdaten werden nicht dauerhaft gespeichert. `RPWatcherDB` enthält ausschließlich eigene Fenster- und Benutzereinstellungen. Profiltexte werden weder gelesen noch gespeichert.

## Bekannte technische Grenzen

- RPWatcher erkennt Target-Auswahl, keine Blickrichtung oder Aufmerksamkeit.
- Nur sichtbare Nameplate-Units, die die WoW-API bereitstellt, können live geprüft werden.
- Spieler erscheinen erst, nachdem sie den Benutzer mindestens einmal im Target hatten.
- Ohne sichtbare Nameplate ist der aktuelle Target-Status unbekannt.
- Sehr kurze Target-Wechsel können zwischen zwei Scans von ungefähr 0,25 Sekunden liegen.
- RP-Namen hängen von einem verfügbaren kompatiblen RP-Profil ab; Total RP 3 bleibt optional.

## Installation

1. `RPWatcher-1.0.0.zip` entpacken.
2. Den enthaltenen Ordner `RPWatcher` nach `World of Warcraft\_retail_\Interface\AddOns\` kopieren.
3. Prüfen, dass `AddOns\RPWatcher\RPWatcher.toc` direkt existiert.
4. WoW starten und RPWatcher in der Addon-Liste aktivieren.
5. Freundliche Nameplates für die reale Erfassung aktivieren.

## Update von 0.9.0

WoW beenden und den vorhandenen Addonordner durch den Ordner aus dem neuen ZIP ersetzen. `RPWatcherDB` kann erhalten bleiben; Datenbankschema, Fensterposition und Benutzereinstellungen bleiben unverändert. Laufzeit-Watcher und RP-Namen werden grundsätzlich nicht gespeichert.

## Support

Fehlerberichte sollten RPWatcher- und WoW-Version, Total-RP-3-Version oder „deaktiviert“, Reproduktionsschritte, erwartetes und tatsächliches Verhalten sowie BugSack-Ausgaben enthalten. Bei Bedarf helfen `/rpw plates` und `/rpw perf report`. Keine Accountdaten, GUIDs oder vollständigen RP-Profile übermitteln.

## Lizenz

RPWatcher wird unter der MIT-Lizenz veröffentlicht. Copyright 2026 Mercia.
