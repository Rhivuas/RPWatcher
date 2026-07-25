# RPWatcher 1.2.0

RPWatcher 1.2.0 ist ein Funktionsupdate auf Basis der stabilen Version 1.1.1. Scanner-, TRP3- und Datenschutzkern bleiben in ihrer Kernlogik unverändert.

## Neu in 1.2.0

- **Fenster bleibt hinter anderen Fenstern:** Das RPWatcher-Hauptfenster verwendet jetzt eine niedrige Frame-Ebene. Es ist weiterhin über der normalen Spielwelt sichtbar, tritt aber nicht mehr störend vor Charakterfenster, Weltkarte, Taschen oder andere Blizzard- und Addonfenster. Es hebt sich durch Anklicken, Öffnen oder Datenaktualisierungen nicht mehr selbst an.
- **Intuitivere Statusfarben:** Die Farben von „Vorher“ und „Unbekannt“ wurden getauscht. „Vorher“ ist jetzt gold/gelb, „Unbekannt“ ist jetzt grau; „Aktuell“ bleibt grün. Die Symbole (Augen-Symbol, Verlaufspfeil, ASCII-Fragezeichen) sind unverändert und bleiben zusammen mit dem Text weiterhin ein von der Farbe unabhängiges Unterscheidungsmerkmal.
- **Kurze Sichtverluste setzen den Timer nicht mehr unnötig zurück:** Verschwindet die Nameplate eines bereits erfassten Spielers kurz (zum Beispiel durch Wegdrehen der Kamera) und erscheint innerhalb der eingestellten Aufbewahrungsdauer wieder, wird ein bestehender „seit …“- oder „zuletzt vor …“-Zeitbezug nach Möglichkeit fortgeführt statt neu zu beginnen. Kehrt ein zuvor aktueller Spieler ohne fortbestehendes Target zurück, wird der Verlustzeitpunkt konservativ auf den Beginn des Sichtverlusts gesetzt. Der Watcher-Cache bleibt dabei vollständig im Arbeitsspeicher; es ändert sich nichts am Datenschutzprinzip.
- **Neue Option „Im Kampf automatisch ausblenden“** (standardmäßig deaktiviert): Nur die tatsächliche Anzeige des Hauptfensters wird während eines Kampfes unterdrückt. Scanner, Watcher-Zeitmessung und die optionale TRP3-Integration laufen im Kampf unverändert weiter, es findet kein Datenreset statt. Der gespeicherte manuelle Sichtbarkeitswunsch bleibt von der Kampf-Unterdrückung unberührt und wird nach Kampfende unter Berücksichtigung der Auto-Ausblendung bei leerer Liste neu ausgewertet.
- **Überarbeitete Optionsseite:** Die Einstellungsseite ist jetzt klar in die vier Bereiche Fenster, Anzeigeverhalten, Integration und Zugriff gegliedert, mit konsistenten Abständen und robuster Darstellung bei verschiedenen UI-Skalierungen. „Unbekannte Watcher behalten“ heißt jetzt „Unsichtbare Watcher behalten“ und enthält einen kurzen Hilfetext zur neuen Zeitfortführung. „Fenster zurücksetzen“ setzt weiterhin ausschließlich Fensterposition, -größe, -skalierung, -transparenz und -sperrstatus zurück.
- **Neuer Diagnosebefehl `/rpw selftest`:** führt nicht persistente interne Prüfungen für Watcher-Zeitfortführung, Statusfarben und die Kampf-Sichtbarkeitslogik aus und gibt das Ergebnis als kompakten Bericht im Chat aus.
- **Tote Spieler und Geister geprüft, nicht spekulativ verändert:** Der gemeldete Verdacht zu toten Spielern konnte nicht reproduziert werden. Eine statische Prüfung der Spielerqualifizierung ergab keinen Tote-Spieler- oder Geister-Ausschluss; es wurde daher kein spekulativer Filter ergänzt. Die entsprechenden Fälle sind Teil der manuellen Testmatrix.
- Datenbankschema kontrolliert von Version 3 auf Version 4 erhöht, um die neue Kampf-Option zu speichern; bestehende 1.1.1-Einstellungen bleiben vollständig erhalten.

## Unverändert

Nameplate-Erfassung, zentrale Tokenauflösung, Target-Erkennung, der 0,25-Sekunden-Scanner, der Fünf-Sekunden-Integritätsabgleich, GUID-basierte Watcherverwaltung, Aufbewahrungslogik, Zonenwechselbehandlung, UI-Virtualisierung, die 1.1.1-nil-Absicherung, Performance-Diagnose, Stress-Testdaten, die Minimap-Schaltfläche samt Drag-Verhalten, der TRP3-Profilbutton, TRP3-Anfrage-Cooldown und globale Drosselung sowie sämtliche Datenschutzprinzipien bleiben unverändert. Es gibt weiterhin genau einen dauerhaften Scanner-Ticker und kein zusätzliches permanentes `OnUpdate`.

## Datenschutz

Unverändert gegenüber 1.1.1: keine Telemetrie, keine externen Netzwerkzugriffe. `RPWatcherDB` enthält weiterhin ausschließlich eigene Fenster- und Benutzereinstellungen, jetzt zusätzlich den Kampf-Auto-Ausblenden-Schalter. Der erweiterte Watcher-Laufzeitcache (einschließlich der neuen Zeitfortführung) bleibt vollständig im Arbeitsspeicher und wird bei Reload oder Logout verworfen; es werden weiterhin keine fremden GUIDs, Namen, RP-Namen oder Profildaten gespeichert. Total RP 3 bleibt vollständig optional.

## Installation

1. `RPWatcher-1.2.0.zip` entpacken.
2. Den enthaltenen Ordner `RPWatcher` nach `World of Warcraft\_retail_\Interface\AddOns\` kopieren.
3. Prüfen, dass `AddOns\RPWatcher\RPWatcher.toc` direkt existiert.
4. WoW starten und RPWatcher in der Addon-Liste aktivieren.

## Update von 1.1.1

WoW beenden und den vorhandenen Addonordner durch den Ordner aus dem neuen ZIP ersetzen. `RPWatcherDB` bleibt erhalten; das Datenbankschema wird automatisch von Version 3 auf Version 4 migriert. Bestehende Fenster-, Anzeige-, TRP3- und Minimap-Einstellungen bleiben vollständig erhalten; die neue Kampf-Option erhält automatisch den Standardwert „aus“.

## Support

Fehlerberichte sollten RPWatcher- und WoW-Version, Total-RP-3-Version oder „deaktiviert“, Reproduktionsschritte, erwartetes und tatsächliches Verhalten sowie BugSack-Ausgaben enthalten. Bei Bedarf helfen `/rpw plates`, `/rpw perf report` und `/rpw selftest`. Keine Accountdaten, GUIDs oder vollständigen RP-Profile übermitteln.

## Lizenz

RPWatcher wird unter der MIT-Lizenz veröffentlicht. Copyright 2026 Mercia.
