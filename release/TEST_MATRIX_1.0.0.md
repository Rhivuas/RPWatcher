# RPWatcher 1.0.0 – finale Testmatrix

- **Zu testendes Artefakt:** `RPWatcher-1.0.0.zip`
- **SHA-256:** `________________________________________________________________`
- **Source-Commit laut Manifest:** `________________________________________`
- **WoW-Retail-Version/Build:** `________________________________________`
- **Total-RP-3-Version:** `________________ / deaktiviert`
- **Tester und Datum:** `________________________________________`

Für jeden Punkt `Bestanden`, `Nicht bestanden` oder `Nicht anwendbar` eintragen. Bei Fehlern BugSack-Ausgabe und Reproduktionsschritte referenzieren, jedoch keine Accountdaten, GUIDs oder vollständigen Profile einfügen.

## Installation

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| I-01 | Addon und zugehörige SavedVariables sichern/entfernen, ZIP neu entpacken und WoW starten. | Saubere Neuinstallation lädt ohne Lua- oder BugSack-Fehler. |  |  |  |
| I-02 | Bestehendes RPWatcher 0.9.0 mit dem ZIP aktualisieren. | Fenster- und Benutzereinstellungen bleiben erhalten; Version ist 1.0.0. |  |  |  |
| I-03 | ZIP im Explorer oder programmgesteuert öffnen. | Genau ein Wurzelordner `RPWatcher`; keine Struktur `RPWatcher/RPWatcher`. |  |  |  |
| I-04 | Installationspfad kontrollieren. | `Interface/AddOns/RPWatcher/RPWatcher.toc` liegt direkt vor. |  |  |  |
| I-05 | WoW-Addon-Liste vor dem Login öffnen. | RPWatcher erscheint mit Autor Mercia, Version 1.0.0 und ohne zwingende TRP3-Abhängigkeit. |  |  |  |
| I-06 | Retail-Client mit Interface 120007 starten. | Addon ist kompatibel und nicht als veraltet markiert. |  |  |  |
| I-07 | `Get-FileHash` für das ZIP ausführen und mit `.sha256` vergleichen. | Tatsächlicher ZIP-Hash, SHA-Datei und eingetragener Testhash stimmen exakt überein. |  |  |  |
| I-08 | Paketinhalt mit Manifest vergleichen. | Nur Allowlist-Dateien vorhanden; LICENSE und alle TOC-Lua-Dateien enthalten. |  |  |  |

## Ohne Total RP 3

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| N-01 | Total RP 3 deaktivieren und `/reload` ausführen. | RPWatcher lädt fehlerfrei; Lademeldung erscheint einmal. |  |  |  |
| N-02 | `/rpw` mehrfach verwenden und Fenster schließen. | Manuelle Sichtbarkeit funktioniert und bleibt von Auto-Ausblendung getrennt. |  |  |  |
| N-03 | Freundliche Nameplates aktivieren und einen Spieler dich targeten lassen. | Echter Watcher erscheint erst nach erkanntem Target-Vorgang. |  |  |  |
| N-04 | Sichtbaren Watcher dich weiter targeten lassen. | Status Aktuell/Grün mit laufender Zeit. |  |  |  |
| N-05 | Watcher das Target wechseln lassen. | Status Vorher/Grau beginnt beim erkannten Wechsel. |  |  |  |
| N-06 | Watcher aus Nameplate-Reichweite gehen lassen. | Status Unbekannt mit Fragezeichen; nicht fälschlich Grau. |  |  |  |
| N-07 | Dieselbe GUID innerhalb der Aufbewahrungszeit zurückkehren lassen. | Vorhandener Watcher wird ohne Duplikat wiederverwendet. |  |  |  |
| N-08 | Aufbewahrung auf 15/30/60/120/300 Sekunden ändern. | Unbekannte Watcher werden nach der jeweils gewählten Dauer entfernt. |  |  |  |
| N-09 | Alle Einstellungen ändern und `/reload` ausführen. | Einstellungen wirken sofort und bleiben erhalten. |  |  |  |
| N-10 | `/rpw test`, danach `/rpw clear` ausführen. | Drei lokale Statusdaten erscheinen; Clear entfernt alle Laufzeitdaten. |  |  |  |
| N-11 | `/rpw stress 25`, `50`, `100`, `200`, danach `stress clear`. | Liste bleibt bedienbar; Stress-Clear lässt echte und normale Testdaten unangetastet. |  |  |  |
| N-12 | `/rpw plates`, `/rpw perf report` und `/rpw trp3` ausführen. | Diagnose bleibt kompakt, namenslos und fehlerfrei; TRP3 wird als nicht verfügbar gemeldet. |  |  |  |

## Mit Total RP 3

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| T-01 | Total RP 3 aktivieren und bekannten RP-Spieler erfassen. | Gültiger RP-Name erscheint als Hauptname. |  |  |  |
| T-02 | Watcher ohne bekanntes Profil erfassen. | Vollständiger normaler WoW-Name bleibt als Fallback sichtbar. |  |  |  |
| T-03 | Neuen echten Watcher erfassen. | Profilanfrage erfolgt ausschließlich für den echten Watcher. |  |  |  |
| T-04 | Profildaten nach einer Anfrage eintreffen oder aktualisieren lassen. | Callback aktualisiert nur den betroffenen vorhandenen Watcher ohne Duplikat. |  |  |  |
| T-05 | `Profil` bei bekanntem Profil anklicken. | TRP3-Profil öffnet fehlerfrei. |  |  |  |
| T-06 | Vor und nach dem Profilklick das WoW-Target prüfen. | Profilöffnung verändert das aktuelle Target nicht. |  |  |  |
| T-07 | Nameplate eines bekannten Watchers verschwinden lassen und `Profil` testen. | Profil kann möglichst anhand der gespeicherten Identität geöffnet werden; kein Lua-Fehler. |  |  |  |
| T-08 | `/rpw refresh` mehrfach innerhalb von 30 Sekunden ausführen. | Pro-GUID-Cooldown verhindert schnelle Wiederholungsanfragen. |  |  |  |
| T-09 | Mehrere neue echte Watcher kurz nacheinander erfassen. | Globale Drosselung verarbeitet höchstens ungefähr eine RPWatcher-Anfrage pro Sekunde. |  |  |  |
| T-10 | `/rpw test` und `/rpw stress 200` bei aktivem TRP3 verwenden. | Keine Test-/Stress-Profilbuttons oder TRP3-Anfragen. |  |  |  |
| T-11 | `/rpw clear` bei wartenden Anfragen ausführen. | Warteschlange und Cooldowns werden geleert; Callback stellt keine gelöschten Watcher wieder her. |  |  |  |

## UI

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| U-01 | Fenster auf Mindestgröße 320 × 170 bringen. | Keine Überlagerung; lange Namen werden sauber abgeschnitten. |  |  |  |
| U-02 | Fenster auf Maximalgröße 750 × 700 bringen. | Liste und Scrollbereich nutzen die Größe korrekt. |  |  |  |
| U-03 | Skalierung nacheinander auf 0,80, 1,00 und 1,30 setzen. | Layout und gespeicherte Position bleiben bei allen Werten stabil. |  |  |  |
| U-04 | Transparenz auf 50, 75 und 100 Prozent setzen. | Hintergrund reagiert; Texte und Bedienelemente bleiben lesbar. |  |  |  |
| U-05 | `/rpw lock` ausführen und Verschieben/Resize versuchen. | Fenster bleibt gesperrt; Resize-Griff ist nicht aktiv. |  |  |  |
| U-06 | `/rpw unlock` ausführen, verschieben und skalieren. | Bewegung und Resize funktionieren; Werte bleiben nach Reload erhalten. |  |  |  |
| U-07 | Auto-Ausblendung mit leerer und gefüllter Liste sowie manuell geschlossenem Fenster prüfen. | Nur automatisch verborgenes Fenster erscheint bei Watchern; manuell verborgenes bleibt zu. |  |  |  |
| U-08 | Profilbutton-Einstellung aus- und einschalten. | Nur Buttonanzeige ändert sich; RP-Namen und Anfragen bleiben funktional unabhängig. |  |  |  |
| U-09 | Sehr lange synthetische RP-Namen bei kleiner Fensterbreite anzeigen. | Name, Zeittext und Profilbereich überlappen nicht; vollständiger Name steht im Tooltip. |  |  |  |
| U-10 | `/rpw stress 200` ausführen. | Virtualisierte Liste bleibt flüssig und erzeugt nicht 200 vollständige Zeilenframes. |  |  |  |
| U-11 | 200 Stress-Watcher vollständig mit Mausrad und Scrollbar durchscrollen. | Alle Bereiche sind erreichbar; Zeilen werden korrekt wiederverwendet. |  |  |  |

## Laufzeit

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| L-01 | `/reload` ausführen. | Initialisierung erfolgt einmal; kein doppelter Ticker oder Callback. |  |  |  |
| L-02 | Ausloggen und erneut einloggen. | Laufzeitdaten sind verworfen; eigene Einstellungen bleiben erhalten. |  |  |  |
| L-03 | Zonenwechsel durchführen. | Temporäre Tokens werden bereinigt und Nameplates neu aufgebaut. |  |  |  |
| L-04 | Ladebildschirm mit zuvor sichtbaren Watchern auslösen. | Keine veralteten Token-Zuordnungen oder Lua-Fehler. |  |  |  |
| L-05 | Mit bereits sichtbaren freundlichen Nameplates laden/reloaden. | Bestehende Nameplates werden über den Integritätsabgleich erfasst. |  |  |  |
| L-06 | Schnelle Remove-/Add-Folge beziehungsweise Token-Wiederverwendung beobachten. | GUID-Integrität verhindert falsche Übernahme. |  |  |  |
| L-07 | Spieler mehrfach in und aus der Nameplate-Reichweite bewegen. | Wiederkehrende GUID ohne Duplikat; Aufbewahrung korrekt. |  |  |  |
| L-08 | Mindestens fünf Minuten an einem vollen RP-Ort messen. | Stabile Erfassung, plausible Diagnosewerte und keine neuen BugSack-Fehler. |  |  |  |
| L-09 | Dasselbe bei manuell verborgenem Fenster durchführen. | Target-Erkennung läuft weiter; verborgene Zeilen werden nicht vollständig formatiert. |  |  |  |
| L-10 | Fenster nach längerer verborgener Zeit wieder anzeigen. | Statuszeiten sind sofort aktuell und Watcher vollständig vorhanden. |  |  |  |

## Datenschutz und Persistenz

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| D-01 | Nach einer Sitzung `RPWatcherDB` kontrollieren. | Datenbank enthält ausschließlich eigene Fenster- und Benutzereinstellungen. |  |  |  |
| D-02 | Nach echten Watchern die SavedVariables durchsuchen. | Keine Watcher oder Watcher-Historie gespeichert. |  |  |  |
| D-03 | SavedVariables auf fremde GUIDs prüfen. | Keine fremden GUIDs vorhanden. |  |  |  |
| D-04 | Mit bekannten RP-Namen spielen und SavedVariables prüfen. | Keine fremden RP-Namen gespeichert. |  |  |  |
| D-05 | TRP3-Profile öffnen und SavedVariables prüfen. | Keine Profiltexte oder Profildaten gespeichert. |  |  |  |
| D-06 | Performance-Diagnose aktivieren, reloaden und SavedVariables prüfen. | Keine Performancewerte gespeichert. |  |  |  |
| D-07 | Test- und Stressdaten erzeugen, reloaden und SavedVariables prüfen. | Keine Test- oder Stressdaten gespeichert. |  |  |  |

## Regression

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| R-01 | `/rpw`, `/rpwatcher`, `/rpw help` testen. | Sichtbarkeit, Alias und Hilfe funktionieren. |  |  |  |
| R-02 | `/rpw test`, `/rpw clear`, `/rpw options`, `/rpw lock`, `/rpw unlock`, `/rpw reset` testen. | Alle Befehle funktionieren mit dokumentierter Wirkung. |  |  |  |
| R-03 | `/rpw trp3` und `/rpw refresh` mit und ohne TRP3 testen. | Diagnose und Aktualisierung bleiben defensiv und gedrosselt. |  |  |  |
| R-04 | `/rpw plates` mehrfach während Nameplate-Wechseln ausführen. | Read-only-Ausgabe; Scannerzustand wird nicht verändert. |  |  |  |
| R-05 | `/rpw perf on`, `report`, `off`, `reset` testen. | Diagnosezustand ist nachvollziehbar, defensiv und nicht persistent. |  |  |  |
| R-06 | `/rpw stress 25|50|100|200|clear` und ungültige Werte testen. | Nur zulässige Werte; echte Watcher bleiben unangetastet. |  |  |  |
| R-07 | `/rpw clear` mit echten, Test- und Stress-Watchern sowie wartenden TRP3-Anfragen ausführen. | Sämtliche Laufzeitdaten werden entfernt; Einstellungen bleiben erhalten. |  |  |  |
| R-08 | Gesamten Test mit BugSack begleiten. | Keine neuen RPWatcher-Lua- oder BugSack-Fehler. |  |  |  |
| R-09 | Einen unbekannten Slash-Unterbefehl verwenden. | Hilfe erscheint ohne Lua-Fehler. |  |  |  |

## Abschlussfreigabe

- [ ] Alle Pflichtpunkte bestanden oder nachvollziehbar als nicht anwendbar markiert.
- [ ] Getesteter ZIP-Dateiname lautet exakt `RPWatcher-1.0.0.zip`.
- [ ] Eingetragene SHA-256 stimmt mit `dist/RPWatcher-1.0.0.sha256` und dem tatsächlichen ZIP überein.
- [ ] Manifest nennt den tatsächlich getesteten Source-Commit und einen sauberen Source-Tree.
- [ ] BugSack enthält keine neue RPWatcher-Meldung.
- [ ] Keine privaten Account-, GUID- oder Profildaten wurden dem Bericht beigefügt.
- [ ] Erst nach dieser Freigabe darf der Tag `v1.0.0` gesetzt werden.
