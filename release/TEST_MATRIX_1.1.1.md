# RPWatcher 1.1.1 – finale Testmatrix

- **Zu testendes Artefakt:** `RPWatcher-1.1.1.zip`
- **SHA-256:** `________________________________________________________________`
- **Source-Commit laut Manifest:** `________________________________________`
- **WoW-Retail-Version/Build:** `________________________________________`
- **Total-RP-3-Version:** `________________ / deaktiviert`
- **Tester und Datum:** `________________________________________`

Für jeden Punkt `Bestanden`, `Nicht bestanden` oder `Nicht anwendbar` eintragen. Bei Fehlern BugSack-Ausgabe und Reproduktionsschritte referenzieren, jedoch keine Accountdaten, GUIDs oder vollständigen Profile einfügen.

## Installation und Update

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| I-01 | Bestehendes RPWatcher 1.1.0 mit `RPWatcherDB` und dem 1.1.1-ZIP aktualisieren. | Fenster-, Benutzer- und Minimap-Einstellungen bleiben vollständig erhalten; Version ist 1.1.1; Datenbankschema bleibt unverändert bei 3. |  |  |  |
| I-02 | `Get-FileHash` für das ZIP ausführen und mit `.sha256` vergleichen. | Tatsächlicher ZIP-Hash, SHA-Datei und eingetragener Testhash stimmen exakt überein. |  |  |  |

## Regressionstest: nil-Watcher beim Listenübergang

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| N-01 | Hauptfenster sichtbar machen und Liste vollständig leeren (`/rpw clear`). | Leere-Liste-Anzeige erscheint; kein Lua-Fehler. |  |  |  |
| N-02 | `/rpw test` ausführen. | Drei Testeinträge erscheinen fehlerfrei; kein `UI.lua:385`-Fehler oder vergleichbarer nil-Watcher-Fehler in BugSack. |  |  |  |
| N-03 | `/rpw clear` ausführen. | Liste leert sich fehlerfrei; kein Fehler. |  |  |  |
| N-04 | Schritte N-02 und N-03 mindestens fünfmal hintereinander wiederholen. | Bei jedem Übergang leer → gefüllt und gefüllt → leer kein Fehler. |  |  |  |
| N-05 | Nach leerer Liste einen ersten echten Watcher erfassen lassen (freundlicher Spieler targetet dich). | Watcher erscheint korrekt und fehlerfrei als erster Eintrag. |  |  |  |
| N-06 | Denselben Vorgang mit aktiviertem Total RP 3 und einem Spieler mit bereits bekanntem, bestätigtem Profil wiederholen. | Watcher erscheint korrekt; synchrones TRP3-Profilupdate löst keinen Fehler aus; Profilbutton erscheint korrekt. |  |  |  |
| N-07 | Einen späten TRP3-Profilcallback auslösen (z. B. `/rpw refresh` oder Profil wird erst nach Verzögerung bekannt). | UI aktualisiert sich fehlerfrei ohne `/reload`. |  |  |  |
| N-08 | Fenster während eines Datenwechsels (z. B. direkt nach `/rpw test`) per Ziehgriff skalieren. | Kein Fehler; Liste bleibt konsistent dargestellt. |  |  |  |
| N-09 | Während eines Datenwechsels in der Liste scrollen (bei ausreichend vielen Einträgen, z. B. `/rpw stress 200`). | Kein Fehler; sichtbare Zeilen bleiben korrekt. |  |  |  |
| N-10 | Auto-Ausblendung aktivieren und Übergang 0 → 1 → 0 Watcher durchlaufen lassen. | Fenster blendet sich in beiden Richtungen korrekt und fehlerfrei ein/aus. |  |  |  |
| N-11 | `/rpw stress 200` ausführen, vollständig scrollen, anschließend `/rpw clear`. | Bleibt flüssig scrollbar; keine 200 vollständigen Zeilenframes; kein Fehler beim abschließenden Clear. |  |  |  |

## Kurze Gegenprüfung unveränderter Funktionen

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| R-01 | Minimap-Button kurz gegenprüfen (Linksklick, Rechtsklick, Ziehen). | Verhält sich unverändert wie in 1.1.0. |  |  |  |
| R-02 | Statusindikatoren (Augen-Symbol, Verlaufspfeil, Fragezeichen) kurz gegenprüfen. | Unverändert korrekt dargestellt, keine Ersatzglyphen. |  |  |  |
| R-03 | TRP3-Profilbutton bei Watcher ohne und mit Profil gegenprüfen. | Verhält sich unverändert wie in 1.1.0. |  |  |  |

## BugSack und Datenschutz

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| D-01 | Gesamten Test mit aktivem BugSack begleiten, gezielt auf den gemeldeten Fehler (`UI.lua:385`, nil-Watcher) sowie weitere Fehler prüfen. | Keine neuen RPWatcher-Lua- oder BugSack-Fehler. |  |  |  |
| D-02 | Nach dem Test `RPWatcherDB` kontrollieren. | Enthält ausschließlich eigene Fenster-, Benutzer- und Minimap-Einstellungen; keine Watcher-, GUID-, RP-Namen- oder Profildaten. |  |  |  |

## Abschlussfreigabe

- [ ] Alle Pflichtpunkte bestanden oder nachvollziehbar als nicht anwendbar markiert.
- [ ] Getesteter ZIP-Dateiname lautet exakt `RPWatcher-1.1.1.zip`.
- [ ] Eingetragene SHA-256 stimmt mit `dist/RPWatcher-1.1.1.sha256` und dem tatsächlichen ZIP überein.
- [ ] Manifest nennt den tatsächlich getesteten Source-Commit und einen sauberen Source-Tree.
- [ ] BugSack enthält keine neue RPWatcher-Meldung.
- [ ] Keine privaten Account-, GUID- oder Profildaten wurden dem Bericht beigefügt.
- [ ] Die veröffentlichten Tags `v1.0.0` und `v1.1.0` wurden nicht verändert.
