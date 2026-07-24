# RPWatcher 1.1.0

RPWatcher 1.1.0 ist ein begrenztes UI-/UX-Verbesserungspaket auf Basis der ersten echten Nutzerrückmeldungen zur stabilen Version 1.0.0. Der Scanner-, Performance-, TRP3- und Datenschutzkern bleibt unverändert.

## Neu in 1.1.0

- Überflüssiger Untertitel „Beobachtungsübersicht“ entfernt; kompaktere Titelleiste, sauber vertikal zentrierter Titel, mehr Platz für Statusübersicht und Watcherliste.
- Drei klar unterscheidbare Statussymbole (▲ Aktuell, ● Vorher, ? Unbekannt) statt derselben Form in drei Farben. Farbe bleibt ergänzend (Grün/Grau/Gold), ist aber nicht mehr das einzige Unterscheidungsmerkmal. Zentrale Symbolzuordnung in `Theme.lua`, gemeinsam für Statusleiste und Zeilen.
- TRP3-Profilbutton erscheint jetzt ausschließlich, wenn für den echten Watcher tatsächlich ein Total-RP-3-Profil bestätigt wurde. Ein bekannter RP-Name allein aktiviert den Button nicht mehr. Kein reservierter Leerraum bei verborgenem Button.
- Neue Minimap-Schaltfläche mit dem originalen RPWatcher-Icon: Linksklick blendet das Fenster ein/aus, Rechtsklick öffnet die Einstellungen, Ziehen speichert die Position entlang des Minimap-Randes. Keine externe Bibliothek.
- Neue Einstellung „Minimap-Schaltfläche anzeigen“; Ausblenden verwirft die gespeicherte Position nicht.
- Datenbankschema kontrolliert von Version 2 auf Version 3 erhöht, um die neuen Minimap-Einstellungen zu speichern.

## Unverändert

Nameplate-Erfassung, zentrale Tokenauflösung, Target-Erkennung, der 0,25-Sekunden-Scanner, der Fünf-Sekunden-Integritätsabgleich, GUID-basierte Watcher, die Grün-/Grau-/Unbekannt-Statuslogik, Aufbewahrungslogik, Zonenwechselbehandlung, UI-Virtualisierung, Performance-Diagnose, Stress-Testdaten, TRP3-Anfrage-Cooldown und globale Drosselung, sowie sämtliche Datenschutzprinzipien bleiben unverändert. Es gibt weiterhin genau einen dauerhaften Scanner-Ticker und keine `OnUpdate`-Schleifen.

## Datenschutz

Unverändert gegenüber 1.0.0: keine Telemetrie, keine externen Netzwerkzugriffe. `RPWatcherDB` enthält weiterhin ausschließlich eigene Fenster- und Benutzereinstellungen, jetzt zusätzlich Sichtbarkeit und Position der Minimap-Schaltfläche. Die Profilverfügbarkeit eines Watchers (`hasTRP3Profile`) ist ausschließlich eine nicht persistente Laufzeitinformation und wird nicht gespeichert.

## Installation

1. `RPWatcher-1.1.0.zip` entpacken.
2. Den enthaltenen Ordner `RPWatcher` nach `World of Warcraft\_retail_\Interface\AddOns\` kopieren.
3. Prüfen, dass `AddOns\RPWatcher\RPWatcher.toc` direkt existiert.
4. WoW starten und RPWatcher in der Addon-Liste aktivieren.

## Update von 1.0.0

WoW beenden und den vorhandenen Addonordner durch den Ordner aus dem neuen ZIP ersetzen. `RPWatcherDB` kann erhalten bleiben; das Datenbankschema wird automatisch von Version 2 auf Version 3 migriert, bestehende Einstellungen bleiben vollständig erhalten. Laufzeit-Watcher, RP-Namen und Profilzustände werden grundsätzlich nicht gespeichert.

## Support

Fehlerberichte sollten RPWatcher- und WoW-Version, Total-RP-3-Version oder „deaktiviert“, Reproduktionsschritte, erwartetes und tatsächliches Verhalten sowie BugSack-Ausgaben enthalten. Bei Bedarf helfen `/rpw plates` und `/rpw perf report`. Keine Accountdaten, GUIDs oder vollständigen RP-Profile übermitteln.

## Lizenz

RPWatcher wird unter der MIT-Lizenz veröffentlicht. Copyright 2026 Mercia.
