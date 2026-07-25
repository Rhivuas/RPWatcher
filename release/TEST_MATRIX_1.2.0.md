# RPWatcher 1.2.0 – finale Testmatrix

- **Zu testendes Artefakt:** `RPWatcher-1.2.0.zip`
- **SHA-256:** `________________________________________________________________`
- **Source-Commit laut Manifest:** `________________________________________`
- **WoW-Retail-Version/Build:** `________________________________________`
- **Total-RP-3-Version:** `________________ / deaktiviert`
- **Tester und Datum:** `________________________________________`

Für jeden Punkt `Bestanden`, `Nicht bestanden` oder `Nicht anwendbar` eintragen. Bei Fehlern BugSack-Ausgabe und Reproduktionsschritte referenzieren, jedoch keine Accountdaten, GUIDs oder vollständigen Profile einfügen.

## Installation und Update

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| I-01 | Bestehendes RPWatcher 1.1.1 mit `RPWatcherDB` und dem 1.2.0-ZIP aktualisieren (Testschritt 1). | Update lädt fehlerfrei; Version ist 1.2.0. |  |  |  |
| I-02 | Nach dem Update alle bisherigen Fenster-, Anzeige-, TRP3- und Minimap-Einstellungen kontrollieren (Testschritt 2). | Position, Größe, Skalierung, Transparenz, Sperrstatus, Aufbewahrungsdauer, Auto-Ausblendung bei leerer Liste, TRP3-Profilbutton-Anzeige, Minimap-Sichtbarkeit und -Position bleiben exakt wie vor dem Update; Datenbankschema wechselt verlustfrei von 3 auf 4. |  |  |  |
| I-03 | Neue Kampf-Option nach dem Update prüfen (Testschritt 3). | „Im Kampf automatisch ausblenden“ ist vorhanden und standardmäßig deaktiviert. |  |  |  |
| I-04 | `Get-FileHash` für das ZIP ausführen und mit `.sha256` vergleichen. | Tatsächlicher ZIP-Hash, SHA-Datei und eingetragener Testhash stimmen exakt überein. |  |  |  |

## Fenster-Ebene (Strata)

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| S-01 | RPWatcher-Hauptfenster öffnen, danach Charakterfenster, Weltkarte, Taschen und ein weiteres Addonfenster nacheinander öffnen und über RPWatcher positionieren (Testschritt 4). | Alle genannten Fenster überdecken RPWatcher; RPWatcher hebt sich nicht selbst davor. |  |  |  |
| S-02 | RPWatcher-Fenster anklicken, verschieben und Daten aktualisieren lassen (`/rpw test`), während ein Blizzard-Fenster darüber liegt. | RPWatcher bleibt dahinter; es hebt sich durch keine dieser Aktionen an. |  |  |  |
| S-03 | Minimap-Schaltfläche, Tooltips, Dropdowns und die Blizzard-Optionsseite von RPWatcher gegenprüfen. | Alle bleiben unabhängig von der neuen Fenster-Ebene voll funktionsfähig. |  |  |  |

## Statusfarben

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| C-01 | `/rpw test` ausführen und alle drei Zeilen sowie die Statusleiste betrachten (Testschritt 5). | Aktuell ist grün mit Augen-Symbol, Vorher ist gold/gelb mit Verlaufspfeil, Unbekannt ist grau mit ASCII-Fragezeichen `?`. Formen sind wie zuvor klar unterscheidbar. |  |  |  |
| C-02 | `/rpw stress 200` ausführen und mehrere Zeilen jedes Status betrachten. | Farbzuordnung ist über alle Zeilen, Zeilenhintergründe und den linken Statusakzent hinweg konsistent gold/grau/grün. |  |  |  |
| C-03 | Kontrast auf dunklem Hintergrund prüfen, ggf. Screenshot anfertigen. | Alle drei Farben und Symbole bleiben gut lesbar; keine Ersatzglyphen. |  |  |  |

## Watcher-Zeitfortführung bei kurzem Sichtverlust

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| T-01 | Von einem freundlichen Spieler mit sichtbarer Nameplate ins Target genommen werden, Kamera wegdrehen bis die Nameplate verschwindet, innerhalb von 30 Sekunden zurückdrehen, Spieler hat dich weiterhin im Target (Testschritte 6–7). | Status wechselt Aktuell → Unbekannt → Aktuell; der „seit …“-Zeitbezug läuft ab dem ursprünglichen Beobachtungsbeginn weiter, kein Timer-Reset. |  |  |  |
| T-02 | Denselben Vorgang mit einem bereits „Vorher“ angezeigten Watcher durchführen: Nameplate kurz verlieren und ohne erneuten Targetwechsel zurückerhalten (Testschritt 8). | Status wechselt Vorher → Unbekannt → Vorher; der „zuletzt vor …“-Zeitbezug bleibt unverändert, kein Timer-Reset. |  |  |  |
| T-03 | Aktuellen Watcher: Nameplate verlieren, bei Rückkehr hat der Spieler dich nicht mehr im Target (Testschritt 9). | Status wechselt zu Vorher; der Zeitbezug basiert konservativ auf dem Beginn des Sichtverlusts, nicht auf dem Zeitpunkt der Wiederkehr. |  |  |  |
| T-04 | Vorher-Watcher: Nameplate verlieren, bei Rückkehr sieht der Spieler dich erneut an. | Eine neue aktive Phase beginnt; der „seit …“-Timer startet bei der bestätigten Wiederkehr, nicht beim ursprünglichen früheren Beobachtungsbeginn. |  |  |  |
| T-05 | Watcher außerhalb der Sichtweite lassen, bis die eingestellte Aufbewahrungsdauer abläuft, danach erneut erfassen lassen (Testschritt 10). | Datensatz wird nach Ablauf entfernt; die erneute Erfassung gilt als vollständig neue Beobachtung mit neuem Zeitbezug. |  |  |  |
| T-06 | `/rpw selftest` ausführen und die Cache-/Timer-Ergebnisse im Chat kontrollieren. | Alle Cache-bezogenen Selbsttests melden `[OK]`. |  |  |  |

## Combat-Auto-Hide

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| K-01 | „Im Kampf automatisch ausblenden“ aktivieren (Testschritt 11). | Option wird sofort gespeichert. |  |  |  |
| K-02 | Mit sichtbarem Fenster in den Kampf gehen und den Kampf verlassen (Testschritt 12). | Fenster verschwindet bei Kampfbeginn und erscheint nach Kampfende wieder (sofern die übrigen Regeln dies erlauben). |  |  |  |
| K-03 | Fenster manuell schließen, danach in den Kampf gehen und wieder verlassen (Testschritt 13). | Fenster bleibt während und nach dem Kampf geschlossen. |  |  |  |
| K-04 | Im Kampf per `/rpw` und separat per Minimap-Linksklick öffnen anfordern (Testschritt 14). | Fenster bleibt während des Kampfes tatsächlich verborgen; erscheint nach Kampfende. |  |  |  |
| K-05 | Im Kampf das Fenster manuell schließen (sofern sichtbar) bzw. den gewünschten Zustand auf verborgen setzen (Testschritt 15). | Fenster bleibt auch nach Kampfende geschlossen. |  |  |  |
| K-06 | Die Option während eines laufenden Kampfes ein- und wieder ausschalten (Testschritt 16). | Aktivieren unterdrückt das Fenster sofort; Deaktivieren berechnet die Sichtbarkeit sofort anhand der übrigen Regeln neu. |  |  |  |
| K-07 | Auto-Ausblendung bei leerer Liste zusätzlich aktivieren und mit Kampf kombinieren: Liste leeren, in den Kampf gehen, Kampf verlassen (Testschritt 17). | Fenster bleibt in jeder Kombination korrekt entweder wegen Kampf oder wegen leerer Liste verborgen; Auto-Ausblendung bleibt auch nach Kampfende maßgeblich. |  |  |  |
| K-08 | Während des gesamten Kampf-Tests `/rpw perf report` und die Watcherliste beobachten (Testschritt 18). | Scanner, Watcher-Zeitmessung und Statuswechsel laufen im Kampf unverändert weiter; kein Datenreset. |  |  |  |
| K-09 | Rechtsklick auf den Minimap-Button während des Kampfes. | Öffnet weiterhin zuverlässig die Blizzard-Optionsseite. |  |  |  |
| K-10 | `/rpw selftest` ausführen und die Combat-Ergebnisse im Chat kontrollieren. | Alle Combat-bezogenen Selbsttests melden `[OK]`. |  |  |  |

## Optionsseite

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| O-01 | Optionsseite bei Standard-UI-Skalierung öffnen. | Alle vier Bereiche (Fenster, Anzeigeverhalten, Integration, Zugriff) sind vollständig sichtbar bzw. über den Scrollbereich erreichbar; keine überlappenden oder abgeschnittenen Texte. |  |  |  |
| O-02 | Optionsseite bei mindestens zwei weiteren UI-Skalierungen öffnen (Testschritt 19). | Layout bleibt konsistent, scrollbar und ohne Überlappungen. |  |  |  |
| O-03 | Jede Option verändern (Fenster sperren, Kampf-Option, Skalierung, Transparenz, Auto-Ausblendung, Aufbewahrungsdauer, TRP3-Profilbutton, Minimap-Schaltfläche), Optionsseite schließen und erneut öffnen (Testschritt 20). | Alle Werte entsprechen exakt dem tatsächlichen Datenbankzustand. |  |  |  |
| O-04 | „Fenster zurücksetzen“ verwenden, nachdem auch Kampf-Option, Auto-Ausblendung, Aufbewahrungsdauer, TRP3- und Minimap-Option verändert wurden (Testschritt 21). | Nur Position, Größe, Skalierung, Transparenz und Sperrstatus werden zurückgesetzt; die übrigen Optionen bleiben unverändert. |  |  |  |
| O-05 | Hilfetext unter „Unsichtbare Watcher behalten“ lesen. | Text erklärt sinngemäß die Zeitfortführung bei kurzem Sichtverlust. |  |  |  |

## Tote Spieler und Geister

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| D-01 | Einen toten freundlichen Spieler mit sichtbarer Nameplate, der dich im Target hat, als Watcher prüfen (Testschritt 22). | Spieler wird wie jeder andere freundliche Spieler als Watcher erfasst; kein Ausschluss allein wegen des Todeszustands. |  |  |  |
| D-02 | Einen freigelassenen Geist mit sichtbarer Nameplate prüfen, sofern reproduzierbar (Testschritt 23). | Geist wird erfasst, sofern WoW einen gültigen freundlichen Spieler-Unit-Token liefert; kein spekulativer Ausschluss. |  |  |  |
| D-03 | Denselben Spieler nach Wiederbelebung weiter beobachten (Testschritt 24). | Kein unnötiger Timer-Reset allein durch den Tod/Wiederbelebungs-Übergang, solange die Nameplate durchgehend oder innerhalb der Aufbewahrungsdauer sichtbar war. |  |  |  |

## Regression – bestehende Funktionen

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| R-01 | `/rpw stress 200` ausführen und vollständig scrollen, danach `/rpw clear` (Testschritt 25). | Bleibt flüssig scrollbar; keine 200 vollständigen Zeilenframes; kein Fehler beim Clear. |  |  |  |
| R-02 | Minimap-Button (Linksklick, Rechtsklick, Ziehen) und TRP3-Profilbutton gegenprüfen (Testschritt 26). | Beide verhalten sich unverändert wie in 1.1.1. |  |  |  |
| R-03 | `/rpw`, `/rpwatcher`, `/rpw help`, `/rpw clear`, `/rpw refresh`, `/rpw trp3`, `/rpw lock`, `/rpw unlock`, `/rpw plates`, `/rpw perf report` einzeln testen. | Alle bestehenden Befehle funktionieren unverändert; `/rpw selftest` ist zusätzlich vorhanden. |  |  |  |

## BugSack und Datenschutz

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| B-01 | Gesamten Test mit aktivem BugSack begleiten (Testschritt 27). | Keine neuen RPWatcher-Lua- oder BugSack-Fehler. |  |  |  |
| B-02 | Nach dem Test `RPWatcherDB` vollständig kontrollieren (Testschritt 28). | Enthält ausschließlich eigene Fenster-, Anzeige-, Kampf-, TRP3- und Minimap-Einstellungen; keine Watcher-, GUID-, RP-Namen- oder Profildaten. |  |  |  |

## Abschlussfreigabe

- [ ] Alle Pflichtpunkte bestanden oder nachvollziehbar als nicht anwendbar markiert.
- [ ] Getesteter ZIP-Dateiname lautet exakt `RPWatcher-1.2.0.zip`.
- [ ] Eingetragene SHA-256 stimmt mit `dist/RPWatcher-1.2.0.sha256` und dem tatsächlichen ZIP überein.
- [ ] Manifest nennt den tatsächlich getesteten Source-Commit und einen sauberen Source-Tree.
- [ ] BugSack enthält keine neue RPWatcher-Meldung.
- [ ] Keine privaten Account-, GUID- oder Profildaten wurden dem Bericht beigefügt.
- [ ] Die veröffentlichten Tags `v1.0.0`, `v1.1.0` und `v1.1.1` wurden nicht verändert.
