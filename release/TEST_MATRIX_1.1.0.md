# RPWatcher 1.1.0 – finale Testmatrix

- **Zu testendes Artefakt:** `RPWatcher-1.1.0.zip`
- **SHA-256:** `________________________________________________________________`
- **Source-Commit laut Manifest:** `________________________________________`
- **WoW-Retail-Version/Build:** `________________________________________`
- **Total-RP-3-Version:** `________________ / deaktiviert`
- **Tester und Datum:** `________________________________________`

Für jeden Punkt `Bestanden`, `Nicht bestanden` oder `Nicht anwendbar` eintragen. Bei Fehlern BugSack-Ausgabe und Reproduktionsschritte referenzieren, jedoch keine Accountdaten, GUIDs oder vollständigen Profile einfügen.

## Installation und Update

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| I-01 | Bestehendes RPWatcher 1.0.0 mit `RPWatcherDB` und dem 1.1.0-ZIP aktualisieren. | Fenster- und Benutzereinstellungen bleiben vollständig erhalten; Version ist 1.1.0; Datenbankschema wechselt verlustfrei von 2 auf 3. |  |  |  |
| I-02 | Saubere Neuinstallation ohne vorhandene `RPWatcherDB` durchführen. | Addon lädt fehlerfrei mit Standardwerten, inklusive aktivierter Minimap-Schaltfläche an der Standardposition. |  |  |  |
| I-03 | ZIP-Struktur und Manifest prüfen. | Genau ein Wurzelordner `RPWatcher`; `Minimap.lua` ist enthalten und in der TOC gelistet. |  |  |  |
| I-04 | `Get-FileHash` für das ZIP ausführen und mit `.sha256` vergleichen. | Tatsächlicher ZIP-Hash, SHA-Datei und eingetragener Testhash stimmen exakt überein. |  |  |  |

## Header und Statussymbole

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| H-01 | Hauptfenster öffnen und Titelleiste betrachten. | Untertitel „Beobachtungsübersicht“ ist vollständig entfernt; keine leere Lücke; Titel „RPWatcher“ ist sauber vertikal zentriert. |  |  |  |
| H-02 | `/rpw test` ausführen und alle drei Zeilen betrachten. | Aktuell zeigt ▲, Vorher zeigt ●, Unbekannt zeigt ? – drei klar unterschiedliche Formen, nicht nur Farben. |  |  |  |
| H-03 | Statusleiste (Zusammenfassung oben) mit Zeilen vergleichen. | Dieselben Symbole werden in Statusleiste und Zeilen konsistent verwendet. |  |  |  |
| H-04 | Kontrast auf dunklem Hintergrund prüfen. | Alle drei Symbole und Farben bleiben gut lesbar. |  |  |  |
| H-05 | Fenster mehrere Minuten beobachten. | Keine permanente Animation; keine spürbare zusätzliche Dauerarbeit. |  |  |  |

## TRP3-Profilbutton

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| P-01 | Echten Watcher ohne Total-RP-3-Profil erfassen. | Kein Profilbutton sichtbar, auch wenn ein RP-Name bekannt ist; kein reservierter Leerraum, Name/Zeit nutzen die volle Breite. |  |  |  |
| P-02 | Echten Watcher mit bekanntem Total-RP-3-Profil erfassen. | Profilbutton erscheint; Klick öffnet das richtige Profil; aktuelles Target bleibt unverändert. |  |  |  |
| P-03 | Watcher erfassen, dessen Profil erst nach einer verzögerten TRP3-Antwort (`REGISTER_DATA_UPDATED`) bekannt wird. | Profilbutton erscheint automatisch ohne `/reload`, sobald das Profil bestätigt ist. |  |  |  |
| P-04 | Bekannten Profil-Watcher in den Status Unbekannt wechseln lassen (Nameplate verschwindet). | Profilbutton bleibt sichtbar und weiterhin nutzbar, solange das Profil zuvor bestätigt wurde. |  |  |  |
| P-05 | `/rpw test` und `/rpw stress 200` bei aktivem Total RP 3 ausführen. | Test- und Stressdaten zeigen niemals einen aktiven Profilbutton und lösen keine TRP3-Anfrage aus. |  |  |  |
| P-06 | „TRP3-Profilbutton anzeigen“ deaktivieren und wieder aktivieren. | Nur die Buttonanzeige ändert sich; Profilprüfung und RP-Namen bleiben unabhängig davon funktional. |  |  |  |
| P-07 | Total RP 3 vollständig deaktivieren. | RPWatcher lädt und arbeitet fehlerfrei; kein Profilbutton erscheint; kein Lua-Fehler. |  |  |  |

## Minimap-Schaltfläche

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| M-01 | Minimap-Schaltfläche per Linksklick betätigen. | Verhält sich identisch zu `/rpw` (manuelle Sichtbarkeit umschalten). |  |  |  |
| M-02 | Minimap-Schaltfläche per Rechtsklick betätigen. | Öffnet die RPWatcher-Einstellungsseite defensiv, identisch zu `/rpw options`. |  |  |  |
| M-03 | Schaltfläche entlang des Minimap-Randes ziehen, danach `/reload` ausführen. | Position wird gespeichert und bleibt nach `/reload` an derselben Stelle. |  |  |  |
| M-04 | „Minimap-Schaltfläche anzeigen“ deaktivieren, danach wieder aktivieren. | Schaltfläche verschwindet und erscheint an der zuvor gespeicherten Position wieder. |  |  |  |
| M-05 | Auto-Ausblendung bei leerer Liste aktivieren und Hauptfenster über die Minimap-Schaltfläche ein-/ausblenden. | Manuelle Sichtbarkeit und Auto-Ausblendung bleiben sauber getrennt. |  |  |  |
| M-06 | `/rpw reset` ausführen. | Minimap-Sichtbarkeit und -Position bleiben unverändert; nur dokumentierte Fensterwerte werden zurückgesetzt. |  |  |  |
| M-07 | UI-Skalierung/Minimap-Zoom verändern, danach erneut ziehen. | Schaltfläche bleibt korrekt entlang des Minimap-Randes positioniert. |  |  |  |
| M-08 | `/reload` mehrfach hintereinander ausführen. | Schaltfläche wird nicht mehrfach erzeugt; kein zusätzlicher Ticker oder OnUpdate außerhalb des aktiven Ziehens. |  |  |  |

## Ohne Total RP 3 (Regression)

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| N-01 | `/rpw`, `/rpwatcher`, `/rpw help` testen. | Sichtbarkeit, Alias und Hilfe funktionieren unverändert. |  |  |  |
| N-02 | Lock, Resize, Skalierung und Transparenz prüfen. | Alle Funktionen bleiben nach der Header-Verkleinerung uneingeschränkt nutzbar. |  |  |  |
| N-03 | Gespeicherte Fenstergröße aus 1.0.0 übernehmen. | Größe bleibt gültig; Mindest- und Maximalgröße unverändert. |  |  |  |
| N-04 | `/rpw stress 200` ausführen und vollständig scrollen. | Bleibt flüssig scrollbar; keine 200 vollständigen Zeilenframes; neue Statusicons korrekt dargestellt. |  |  |  |
| N-05 | `/rpw plates` und `/rpw perf report` ausführen. | Beide Befehle funktionieren unverändert und bleiben namenslos. |  |  |  |

## Datenschutz und Persistenz

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| D-01 | Nach einer Sitzung `RPWatcherDB` kontrollieren. | Enthält ausschließlich eigene Fenster- und Benutzereinstellungen, inklusive Minimap-Sichtbarkeit/-Position; keine Watcher-, GUID-, RP-Namen- oder Profildaten. |  |  |  |
| D-02 | Mehrere echte Watcher mit und ohne bestätigtes Profil erfassen, dann `RPWatcherDB` prüfen. | Kein `hasTRP3Profile`-Wert oder vergleichbare Profildaten werden gespeichert. |  |  |  |
| D-03 | `/rpw clear` mit vorhandenen echten, Test- und Stress-Watchern sowie bestätigten Profilen ausführen. | Alle nicht persistenten Profilzustände werden zusammen mit den Watchern entfernt. |  |  |  |

## Regression – BugSack

| ID | Testschritt | Erwartung | Ergebnis | Bestanden/Nicht bestanden | Notizen |
|---|---|---|---|---|---|
| R-01 | Gesamten Test mit aktivem BugSack begleiten. | Keine neuen RPWatcher-Lua- oder BugSack-Fehler. |  |  |  |
| R-02 | `Scanner.lua` und `Performance.lua` funktional gegen 1.0.0 vergleichen. | Kein funktionaler Unterschied außerhalb der dokumentierten Profilverfügbarkeitsprüfung. |  |  |  |

## Abschlussfreigabe

- [ ] Alle Pflichtpunkte bestanden oder nachvollziehbar als nicht anwendbar markiert.
- [ ] Getesteter ZIP-Dateiname lautet exakt `RPWatcher-1.1.0.zip`.
- [ ] Eingetragene SHA-256 stimmt mit `dist/RPWatcher-1.1.0.sha256` und dem tatsächlichen ZIP überein.
- [ ] Manifest nennt den tatsächlich getesteten Source-Commit und einen sauberen Source-Tree.
- [ ] BugSack enthält keine neue RPWatcher-Meldung.
- [ ] Keine privaten Account-, GUID- oder Profildaten wurden dem Bericht beigefügt.
- [ ] Der veröffentlichte Tag `v1.0.0` wurde nicht verändert.
