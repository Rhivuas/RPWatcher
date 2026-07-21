# RPWatcher 0.9.0 – Release-Candidate-Testmatrix

- **Zu testendes Artefakt:** `RPWatcher-0.9.0.zip`
- **SHA-256:** `________________________________________`
- **WoW-Retail-Build:** `________________`
- **Total-RP-3-Version:** `________________ / deaktiviert`
- **Tester und Datum:** `________________________________________`

Für jeden Punkt `Bestanden`, `Nicht bestanden` oder `Nicht anwendbar` eintragen. Bei Fehlern BugSack-Ausgabe und Reproduktionsschritte referenzieren, jedoch keine Accountdaten, GUIDs oder vollständigen Profile einfügen.

## Installation

| ID | Testschritt | Erwartung | Ergebnis | Status | Notizen |
|---|---|---|---|---|---|
| I-01 | Addon und SavedVariables entfernen, ZIP neu entpacken und WoW starten. | Saubere Neuinstallation lädt ohne Lua-/BugSack-Fehler. |  |  |  |
| I-02 | Bestehendes RPWatcher 0.6.0 mit dem ZIP aktualisieren. | Fenster- und Benutzereinstellungen bleiben erhalten; Version ist 0.9.0. |  |  |  |
| I-03 | ZIP programmgesteuert oder im Explorer öffnen. | Genau ein Wurzelordner `RPWatcher`; keine Doppelverschachtelung. |  |  |  |
| I-04 | WoW-Addon-Liste vor dem Login öffnen. | RPWatcher erscheint mit Autor Mercia, Version 0.9.0 und ohne fehlende Abhängigkeit. |  |  |  |
| I-05 | Retail-Client mit Interface 120007 starten. | Addon ist kompatibel und nicht als veraltet markiert. |  |  |  |
| I-06 | Paketinhalt mit Manifest vergleichen. | Nur Allowlist-Dateien vorhanden; LICENSE und alle TOC-Lua-Dateien enthalten. |  |  |  |

## Ohne Total RP 3

| ID | Testschritt | Erwartung | Ergebnis | Status | Notizen |
|---|---|---|---|---|---|
| N-01 | Total RP 3 deaktivieren und `/reload` ausführen. | RPWatcher startet fehlerfrei; Chat-Lademeldung erscheint einmal. |  |  |  |
| N-02 | Freundliche Nameplates aktivieren und einen Spieler dich targeten lassen. | Echter Watcher erscheint erst nach Target-Erkennung. |  |  |  |
| N-03 | Grün → Grau → Nameplate weg durchlaufen. | Aktuell, Vorher und Unbekannt mit korrekten Zeiten. |  |  |  |
| N-04 | `/rpw options` öffnen und Einstellungen ändern. | Änderungen wirken sofort und überstehen `/reload`. |  |  |  |
| N-05 | `/rpw test`, danach `/rpw clear`. | Drei Teststatus erscheinen; Clear entfernt alle Laufzeitdaten. |  |  |  |
| N-06 | `/rpw stress 25`, `100`, `200`, danach `stress clear`. | Liste bleibt bedienbar; Stress-Clear lässt normale Test-/Echtdaten unangetastet. |  |  |  |
| N-07 | `/rpw trp3` ausführen. | Diagnose meldet TRP3 als nicht verfügbar, ohne Fehler. |  |  |  |
| N-08 | `/rpw plates` und `/rpw perf report` ausführen. | Kompakte Diagnose ohne Namen, GUIDs oder Fehler. |  |  |  |

## Mit Total RP 3

| ID | Testschritt | Erwartung | Ergebnis | Status | Notizen |
|---|---|---|---|---|---|
| T-01 | Total RP 3 3.3.7 aktivieren und bekannten RP-Spieler erfassen. | Gültiger RP-Name erscheint als Hauptname. |  |  |  |
| T-02 | Watcher ohne bekanntes Profil erfassen. | Vollständiger normaler WoW-Name bleibt als Fallback. |  |  |  |
| T-03 | Neuen echten Watcher erfassen und Anfrage beobachten. | Profilanfrage erfolgt nur für echten Watcher. |  |  |  |
| T-04 | Profil nach Anfrage eintreffen beziehungsweise aktualisieren lassen. | Callback aktualisiert betroffenen vorhandenen Watcher, ohne Duplikat. |  |  |  |
| T-05 | `Profil` bei bekanntem Profil anklicken. | TRP3-Profil öffnet; aktuelles Target bleibt unverändert. |  |  |  |
| T-06 | Mehrere neue Watcher kurz nacheinander erfassen und Performancebericht prüfen. | Höchstens ungefähr eine RPWatcher-Anfrage pro Sekunde; 30-Sekunden-GUID-Cooldown bleibt aktiv. |  |  |  |
| T-07 | Nameplate eines bekannten Watchers verschwinden lassen und `Profil` testen. | Profil kann möglichst über gespeicherte Identität geöffnet werden; kein Fehler. |  |  |  |
| T-08 | `/rpw test` und `/rpw stress 200` bei aktivem TRP3 verwenden. | Keine Test-/Stress-Profilbuttons oder TRP3-Anfragen. |  |  |  |
| T-09 | `/rpw clear` bei wartenden Anfragen ausführen. | Warteschlange/Cooldowns werden geleert; Callback stellt keinen gelöschten Watcher wieder her. |  |  |  |
| T-10 | Total RP 3 nach RPWatcher laden beziehungsweise neu aktivieren. | Integration registriert sich einmal und aktualisiert ohne Lua-Fehler. |  |  |  |

## UI

| ID | Testschritt | Erwartung | Ergebnis | Status | Notizen |
|---|---|---|---|---|---|
| U-01 | Fenster auf Mindestgröße 320 × 170 bringen. | Keine Überlagerung; Namen werden bei Bedarf abgeschnitten. |  |  |  |
| U-02 | Fenster auf Maximalgröße 750 × 700 bringen. | Liste und Scrollbereich nutzen die Größe korrekt. |  |  |  |
| U-03 | Skalierung 0,80 testen. | Darstellung und gespeicherte Position bleiben stabil. |  |  |  |
| U-04 | Skalierung 1,00 testen. | Standarddarstellung korrekt. |  |  |  |
| U-05 | Skalierung 1,30 testen. | Keine unkontrollierte Positionsverschiebung. |  |  |  |
| U-06 | Transparenz 50 Prozent testen. | Hintergründe transparenter; Texte und Bedienelemente lesbar. |  |  |  |
| U-07 | Transparenz 75 Prozent testen. | Mittlere Transparenz korrekt. |  |  |  |
| U-08 | Transparenz 100 Prozent testen. | Hintergründe vollständig deckend; Rahmen sichtbar. |  |  |  |
| U-09 | `/rpw lock`, Verschieben und Resize versuchen. | Sperrindikator sichtbar; Bewegung und Resize blockiert. |  |  |  |
| U-10 | `/rpw unlock`, verschieben und skalieren. | Griff sichtbar; neue Position und Größe werden gespeichert. |  |  |  |
| U-11 | Auto-Ausblendung mit leerer und gefüllter Liste prüfen. | Nur automatisch verborgenes Fenster erscheint bei Watcher; manuell verborgenes bleibt zu. |  |  |  |
| U-12 | Profilbutton-Einstellung aus/ein schalten. | Nur Buttonanzeige ändert sich; RP-Namen bleiben erhalten. |  |  |  |
| U-13 | `/rpw stress 200` vollständig durchscrollen. | Sichtbare Zeilen werden korrekt wiederverwendet; keine 200 vollständigen Zeilenframes/kein Ruckeln. |  |  |  |
| U-14 | Sehr lange Stress-RP-Namen überfahren. | Zeile überlappt nicht; vollständiger Name im Tooltip. |  |  |  |
| U-15 | Fenster mit laufenden Zeiten verbergen und später zeigen. | Verborgene Zeilen werden nicht laufend formatiert; Zeiten sind beim Anzeigen aktuell. |  |  |  |

## Laufzeit

| ID | Testschritt | Erwartung | Ergebnis | Status | Notizen |
|---|---|---|---|---|---|
| L-01 | `/reload` mit bereits sichtbaren Nameplates. | Vorhandene Nameplates werden erfasst; kein doppelter Ticker. |  |  |  |
| L-02 | Frischer Login. | Initialisierung und Callback-Registrierung jeweils einmal. |  |  |  |
| L-03 | Logout und erneuter Login. | Laufzeit-Watcher verworfen; eigene Einstellungen erhalten. |  |  |  |
| L-04 | Zonenwechsel durchführen. | Temporäre Tokens bereinigt und vorhandene Nameplates neu aufgebaut. |  |  |  |
| L-05 | Ladebildschirm mit zuvor sichtbarem Watcher. | Kein veralteter Token; Watcher gegebenenfalls Unbekannt. |  |  |  |
| L-06 | Spieler mehrfach in/out der Nameplate-Reichweite bewegen. | Wiederkehrende GUID ohne Duplikat; Unbekannt-Aufbewahrung korrekt. |  |  |  |
| L-07 | Schnelle Remove-/Add-Folge beziehungsweise Token-Wiederverwendung beobachten. | Gespeicherte Remove-Zuordnung und GUID-Integrität verhindern falsche Übernahme. |  |  |  |
| L-08 | Mindestens fünf Minuten an einem Großereignis messen. | Stabile Erfassung, keine Fehler, plausible Kandidatenprüfungen und Scanzeit. |  |  |  |
| L-09 | Großereignis bei manuell verborgenem Fenster messen. | Target-Erkennung läuft weiter; UI-Zeitaktualisierungen bleiben weitgehend aus. |  |  |  |
| L-10 | Aufbewahrung während vorhandener unbekannter Watcher ändern. | Neuer Wert gilt unmittelbar ohne zusätzlichen Timer. |  |  |  |

## Regression

| ID | Testschritt | Erwartung | Ergebnis | Status | Notizen |
|---|---|---|---|---|---|
| R-01 | `/rpw`, `/rpwatcher`, `/rpw help` testen. | Sichtbarkeit und Hilfe korrekt. |  |  |  |
| R-02 | `/rpw test`, `clear`, `options`, `lock`, `unlock`, `reset` testen. | Alle Befehle funktionieren ohne Fehler und mit dokumentierter Wirkung. |  |  |  |
| R-03 | `/rpw trp3` und `/rpw refresh` testen. | Diagnose/Aktualisierung defensiv und gedrosselt. |  |  |  |
| R-04 | `/rpw plates` mehrfach während Integritätsabgleichen ausführen. | Read-only-Ausgabe; Kandidaten bleiben stabil. |  |  |  |
| R-05 | `/rpw perf on`, `report`, `off`, `reset` testen. | Zustand defensiv, nicht persistent und nachvollziehbar. |  |  |  |
| R-06 | `/rpw stress 25|50|100|200|clear` und ungültige Werte testen. | Nur erlaubte Werte; keine echten Watcher verändert. |  |  |  |
| R-07 | `/rpw clear` mit echten, Test- und Stress-Watchern ausführen. | Sämtliche Laufzeit-Watcher und RPWatcher-Anfragen entfernt; Settings erhalten. |  |  |  |
| R-08 | Gesamten Test mit BugSack begleiten. | Keine neuen Lua-/BugSack-Fehler. |  |  |  |
| R-09 | SavedVariables nach Sitzung kontrollieren. | Keine fremden GUIDs, Namen, Profile, Diagnose- oder Stressdaten gespeichert. |  |  |  |
| R-10 | Unbekannten Slash-Unterbefehl verwenden. | Hilfe erscheint; kein Lua-Fehler. |  |  |  |

## Abschlussfreigabe

- [ ] Alle Pflichtpunkte bestanden oder nachvollziehbar als nicht anwendbar markiert.
- [ ] Getesteter ZIP-Dateiname stimmt exakt.
- [ ] Eingetragene SHA-256 stimmt mit `dist/RPWatcher-0.9.0.sha256` überein.
- [ ] BugSack enthält keine neue RPWatcher-Meldung.
- [ ] Kein fremdes Profil oder private Identität wurde dem Bericht beigefügt.
- [ ] Erst nach dieser Freigabe darf ein Tag `v0.9.0` erwogen werden.
