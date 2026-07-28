# RPWatcher 1.3.0 – finale Testmatrix

- **Zu testendes Artefakt:** `RPWatcher-1.3.0.zip`
- **SHA-256:** `________________________________________________________________`
- **Source-Commit laut Manifest:** `________________________________________`
- **WoW-Retail-Version/Build:** `________________________________________`
- **Total-RP-3-Version:** `________________ / deaktiviert`
- **Tester und Datum:** `________________________________________`

Für jeden Punkt `Bestanden`, `Nicht bestanden` oder `Nicht anwendbar` eintragen. Bei Fehlern BugSack-Ausgabe und Reproduktionsschritte referenzieren, jedoch keine Accountdaten, GUIDs oder vollständigen Profile einfügen.

## Installation und Update

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| I-01 | Bestehendes RPWatcher 1.2.0 mit `RPWatcherDB` und dem 1.3.0-ZIP aktualisieren (Testschritt 1). | Update lädt fehlerfrei; Version ist 1.3.0. |  |  |  |
| I-02 | Nach dem Update Schema und alle Einstellungen kontrollieren (Testschritt 2). | Schema bleibt bei Version 4; alle bisherigen Fenster-, Anzeige-, Kampf-, TRP3- und Minimap-Einstellungen bleiben exakt wie vor dem Update erhalten. |  |  |  |
| I-03 | `/rpw selftest` unmittelbar nach dem Update ausführen (Testschritt 3). | Alle Selbsttests, einschließlich der neuen Lokalisierungsprüfungen, melden `[OK]`. |  |  |  |
| I-04 | `Get-FileHash` für das ZIP ausführen und mit `.sha256` vergleichen. | Tatsächlicher ZIP-Hash, SHA-Datei und eingetragener Testhash stimmen exakt überein. |  |  |  |

## Englische Oberfläche (Client-Sprache enUS/enGB)

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| E-01 | WoW mit englischem Client (enUS oder enGB) laden und Hauptfenster öffnen (Testschritt 4). | Fenster öffnet sich; alle sichtbaren Texte sind Englisch. |  |  |  |
| E-02 | Statusübersicht (Aktuell/Vorher/Unbekannt-Zähler) betrachten (Testschritt 5). | Zähler und Beschriftungen sind vollständig Englisch (`current`/`previous`/`unknown`). |  |  |  |
| E-03 | Fenster leeren (`/rpw clear`) und Empty State betrachten (Testschritt 6). | Empty-State-Titel und Hilfetext sind Englisch. |  |  |  |
| E-04 | `/rpw test` ausführen und die drei Testnamen prüfen (Testschritt 7). | Testnamen lauten `[Test] Current Watcher`, `[Test] Previous Watcher`, `[Test] Unknown Watcher`. |  |  |  |
| E-05 | Profilbutton und Watcher-Tooltips (Name, Status, TRP3-Hinweis) prüfen, sofern TRP3 verfügbar (Testschritt 8). | Profilbutton-Beschriftung, Tooltip-Zeilen und Statussätze sind Englisch. |  |  |  |
| E-06 | Sekunden-, Minuten- und Stundenanzeige eines Watchers beobachten (Testschritt 9). | Zeitangaben verwenden die englischen Vorlagen (`for …`, `… ago`, `not visible · …`) mit korrekten Einheiten. |  |  |  |
| E-07 | Optionsseite vollständig durchscrollen (Testschritt 10). | Alle vier Bereiche (Window, Display Behavior, Integration, Access) sind vollständig sichtbar bzw. erreichbar, kein abgeschnittener Text. |  |  |  |
| E-08 | Alle Optionsbeschriftungen und Hilfetexte lesen (Testschritt 11). | Sämtliche Beschriftungen, Slider, Checkboxen und Hilfetexte sind Englisch und layoutkonform. |  |  |  |
| E-09 | Minimap-Tooltip einblenden (Testschritt 12). | Linksklick-, Rechtsklick- und Zieh-Hinweis sind Englisch; „RPWatcher“ als Titel bleibt unverändert. |  |  |  |
| E-10 | `/rpw help` ausführen (Testschritt 13). | Vollständige Befehlsübersicht ist Englisch; Slash-Befehle selbst (`/rpw`, `test`, `clear`, …) sind unverändert. |  |  |  |
| E-11 | `/rpw trp3` ausführen (Testschritt 14). | TRP3-Diagnosekopf, Ja/Nein-Werte und Zeilenbeschriftungen sind Englisch. |  |  |  |
| E-12 | `/rpw plates` ausführen (Testschritt 15). | Nameplate-Diagnosekopf und alle Diagnosezeilen sind Englisch; Zahlenwerte unverändert. |  |  |  |
| E-13 | `/rpw perf report` ausführen (Testschritt 16). | Performance-Bericht inklusive Dauerangabe ist vollständig Englisch. |  |  |  |
| E-14 | `/rpw refresh` ausführen (Testschritt 17). | Ergebniszeile ("… real watchers checked, … profiles requested, … skipped due to cooldown.") ist Englisch, Zahlen korrekt eingesetzt. |  |  |  |
| E-15 | `/rpw stress 200` ausführen, Liste beobachten (Testschritt 18). | Stress-Namen folgen dem Muster `[Stress] Player NNN`; Liste bleibt flüssig scrollbar. |  |  |  |
| E-16 | Gesamte englische Sitzung auf verbliebene deutsche Texte kontrollieren (Testschritt 19). | Keine deutschen Laufzeittexte sichtbar (Ausnahmen: RPWatcher, Total RP 3, TRP3, Slash-Befehle, GUIDs). |  |  |  |

## Deutsche Oberfläche (Client-Sprache deDE)

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| D-01 | `/rpw selftest` auf dem deutschen Client ausführen und die Lokalisierungsergebnisse kontrollieren (Testschritt 20). | Alle Lokalisierungs-Selbsttests melden `[OK]`; Selbsttest-Meldungen selbst erscheinen auf Deutsch. |  |  |  |
| D-02 | Hauptfenster, Statusübersicht, Empty State, `/rpw test`-Namen und Optionsseite auf einem deutschen Client prüfen, sofern verfügbar (Testschritt 21). | Alle Texte entsprechen inhaltlich der bisherigen 1.2.0-Formulierung (z. B. „aktuell“/„vorher“/„unbekannt“, `[Test] Aktueller Watcher` usw.). |  |  |  |
| D-03 | Minimap-Tooltip, `/rpw help`, `/rpw trp3` und `/rpw plates` auf Deutsch gegenprüfen. | Texte sind identisch zu den vor 1.3.0 verwendeten deutschen Formulierungen. |  |  |  |

## Unbekannte Locale (Fallback)

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| F-01 | `/rpw selftest` ausführen und speziell die `BuildCatalog`-Fallback-Ergebnisse (enUS, enGB, deDE, unbekannt) kontrollieren (Testschritt 22). | Alle vier `BuildCatalog`-Selbsttests melden `[OK]`; ein unbekannter Locale-Code liefert nachweislich Englisch. |  |  |  |

## Regression – bestehende Funktionen

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| R-01 | Combat-Auto-Hide regressionsprüfen: Option aktivieren, in den Kampf gehen und wieder verlassen (Testschritt 23). | Verhalten identisch zu 1.2.0; Fenster verbirgt sich im Kampf und erscheint danach unter Berücksichtigung der übrigen Regeln wieder. |  |  |  |
| R-02 | Watcher-Timerfortführung regressionsprüfen: Nameplate kurz verlieren und zurückerhalten (Testschritt 24). | Zeitfortführung verhält sich identisch zu 1.2.0 (kein unnötiger Reset). |  |  |  |
| R-03 | Minimap-Funktion (Linksklick, Rechtsklick, Ziehen) und TRP3-Funktion (RP-Name, Profilbutton, Profilöffnung) regressionsprüfen (Testschritt 25). | Beide verhalten sich unverändert wie in 1.2.0. |  |  |  |
| R-04 | Alle bestehenden Slash-Befehle einzeln testen (`/rpw`, `/rpwatcher`, `/rpw clear`, `/rpw lock`, `/rpw unlock`, `/rpw reset`, `/rpw options`). | Alle bestehenden Befehle funktionieren unverändert; keine übersetzten Befehlsaliasnamen. |  |  |  |

## BugSack und Datenschutz

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| B-01 | Gesamten Test mit aktivem BugSack begleiten (Testschritt 26). | Keine neuen RPWatcher-Lua- oder BugSack-Fehler. |  |  |  |
| B-02 | Nach dem Test `RPWatcherDB` vollständig kontrollieren (Testschritt 27). | Enthält ausschließlich eigene Fenster-, Anzeige-, Kampf-, TRP3- und Minimap-Einstellungen; keine Watcher-, GUID-, RP-Namen- oder Profildaten. |  |  |  |
| B-03 | `RPWatcherDB` gezielt auf Locale- oder Katalogdaten kontrollieren (Testschritt 28). | Keine Felder für Sprache, Clientlocale oder Sprachkataloge vorhanden. |  |  |  |

## Abschlussfreigabe

- [ ] Alle Pflichtpunkte bestanden oder nachvollziehbar als nicht anwendbar markiert.
- [ ] Getesteter ZIP-Dateiname lautet exakt `RPWatcher-1.3.0.zip`.
- [ ] Eingetragene SHA-256 stimmt mit `dist/RPWatcher-1.3.0.sha256` und dem tatsächlichen ZIP überein.
- [ ] Manifest nennt den tatsächlich getesteten Source-Commit und einen sauberen Source-Tree.
- [ ] BugSack enthält keine neue RPWatcher-Meldung.
- [ ] Keine privaten Account-, GUID- oder Profildaten wurden dem Bericht beigefügt.
- [ ] Die veröffentlichten Tags `v1.0.0`, `v1.1.0`, `v1.1.1` und `v1.2.0` wurden nicht verändert.
