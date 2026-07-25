# Changelog

## 1.2.0

- Hauptfenster von `DIALOG` auf die niedrige Frame-Ebene `LOW` umgestellt: RPWatcher bleibt über der Spielwelt sichtbar, tritt aber nicht mehr vor Charakterfenster, Weltkarte, Taschen oder andere Blizzard- und Addonfenster. Kein `Raise()` und kein dynamischer Strata-Wechsel mehr.
- Statusfarben von Vorher und Unbekannt in `Theme.lua` getauscht: Vorher ist jetzt gold/gelb, Unbekannt ist jetzt grau (Aktuell bleibt grün). Symbole (Auge, Verlaufspfeil, ASCII-Fragezeichen) und Zeittexte sind unverändert; Farbe bleibt weiterhin nicht das einzige Unterscheidungsmerkmal.
- Bestehenden GUID-basierten Watcher-Laufzeitcache in `Scanner.lua` erweitert: Ein kurzer Verlust der Nameplate setzt die laufende „Aktuell“- oder „Vorher“-Zeitmessung eines bereits erfassten Watchers innerhalb der eingestellten Aufbewahrungsdauer nicht mehr grundlos zurück. Kehrt ein zuvor aktueller Watcher ohne fortbestehendes Target zurück, wird der Verlustzeitpunkt konservativ auf den Beginn des Sichtverlusts gesetzt statt auf den Zeitpunkt der Wiederkehr. Der Cache bleibt vollständig flüchtig; es werden weiterhin keine fremden GUIDs, Namen, RP-Namen oder Profildaten in `RPWatcherDB` gespeichert.
- Neue Option „Im Kampf automatisch ausblenden“ (standardmäßig aus) ergänzt: Nur das sichtbare RPWatcher-Hauptfenster wird während eines Kampfes tatsächlich verborgen; Scanner, Watcher-Zeitmessung und die optionale TRP3-Integration laufen im Kampf unverändert weiter. Der gespeicherte manuelle Sichtbarkeitswunsch bleibt von der Kampf-Unterdrückung unberührt und wird nach Kampfende unter Berücksichtigung der Auto-Ausblendung bei leerer Liste neu ausgewertet. Kein neuer Ticker, kein permanentes `OnUpdate`.
- Optionsseite strukturell in die vier Bereiche Fenster, Anzeigeverhalten, Integration und Zugriff überarbeitet, in einen Scrollbereich für robuste Darstellung bei verschiedenen UI-Skalierungen eingebettet und mit konsistenten Abständen versehen. „Unbekannte Watcher behalten“ heißt jetzt „Unsichtbare Watcher behalten“ und enthält einen Hilfetext zur Zeitfortführung bei kurzem Sichtverlust. „Fenster zurücksetzen“ setzt weiterhin ausschließlich Fensterdarstellung und -position zurück.
- Datenbankschema kontrolliert von Version 3 auf Version 4 erhöht, um die neue Kampf-Option zu speichern; bestehende 1.1.1-Einstellungen bleiben vollständig erhalten, `hideInCombat` erhält automatisch den Standardwert „aus“.
- Bestehende Spielerqualifizierung in `Scanner.lua` statisch auf Tote-Spieler- und Geister-Ausschlüsse geprüft: Der gemeldete Verdacht konnte nicht reproduziert werden, es wurde kein UnitIsDead-/UnitIsDeadOrGhost-Ausschluss gefunden, und es wurde kein spekulativer Filter ergänzt. Tod, Geist und Wiederbelebung sind Teil der manuellen Testmatrix.
- Neuer Diagnosebefehl `/rpw selftest` ergänzt: führt nicht persistente interne Prüfungen für Watcher-Zeitfortführung, Statusfarben und Kampf-Sichtbarkeitslogik aus und meldet das Ergebnis im Chat, ohne bestehende Befehle zu verändern.
- Nameplate-Erfassung, 0,25-Sekunden-Scanner, Fünf-Sekunden-Integritätsabgleich, TRP3-Kernlogik, UI-Virtualisierung, die 1.1.1-nil-Absicherung, Minimap-Drag, Performance-Diagnose und alle Datenschutzprinzipien bleiben unverändert.

## 1.1.1

- Hotfix: Lua-Laufzeitfehler behoben, bei dem die virtualisierte Watcher-Liste beim Übergang von einer leeren Liste zum ersten echten Watcher gelegentlich mit einem nil-Watcher aufgerufen wurde.
- Refresh-Reihenfolge in `UI.lua` korrigiert: Der Listensnapshot wird jetzt vor dem Sichtbarwerden des Listenbereichs aktualisiert, sodass ein dadurch synchron ausgelöstes `OnSizeChanged` keine veralteten Daten mehr rendern kann.
- Zusätzliche defensive Absicherung ergänzt: Eine Zeilenaktualisierung ohne aktuellen Watcher wird kontrolliert übersprungen statt einen Lua-Fehler auszulösen.
- Keine Änderung an Scanner-, TRP3- oder Datenschutzfunktion; kein Verlust gespeicherter Einstellungen.
- Alle Funktionen aus 1.1.0 (Statusindikatoren, Minimap-Schaltfläche, TRP3-Profilbutton-Korrektur) bleiben vollständig enthalten.

## 1.1.0

- Überflüssigen, funktionslosen Untertitel „Beobachtungsübersicht“ aus dem Hauptfenster entfernt; Titelleiste kompakter gestaltet und Statusübersicht sowie Listenbereich rücken in den frei gewordenen Platz nach.
- Drei klar unterscheidbare Statussymbole (Aktuell, Vorher, Unbekannt) eingeführt; Farbe bleibt ergänzend, ist aber nicht mehr das einzige Unterscheidungsmerkmal. Zentrale Symbolzuordnung in `Theme.lua`, gemeinsam genutzt von Statusleiste und Watcher-Zeilen.
- TRP3-Profilbutton erscheint jetzt ausschließlich, wenn für den echten Watcher tatsächlich ein Total-RP-3-Profil bestätigt wurde; ein bekannter RP-Name allein reicht dafür nicht mehr aus. Kein reservierter Leerraum, wenn der Button verborgen ist.
- Neue Minimap-Schaltfläche mit dem originalen RPWatcher-Icon für schnellen Zugriff ohne Chatbefehl ergänzt (`Minimap.lua`, keine externe Bibliothek). Linksklick entspricht `/rpw`, Rechtsklick entspricht `/rpw options`, Ziehen speichert die Position entlang des Minimap-Randes.
- Neue Einstellung „Minimap-Schaltfläche anzeigen“ ergänzt; Ausblenden verwirft die gespeicherte Position nicht.
- Datenbankschema kontrolliert von Version 2 auf Version 3 erhöht, um die neuen Minimap-Einstellungen zu speichern; bestehende 1.0.0-Einstellungen bleiben vollständig erhalten.
- Kleinere responsive Layoutverbesserungen an Kopfbereich und Zeilen im Rahmen der obigen Änderungen.
- Scanner-, Performance-, TRP3-Kern- (abgesehen von der neuen Profilverfügbarkeitsprüfung über bestehende Anfragewege) und Datenschutzprinzipien unverändert beibehalten.

## 1.0.0

- Eigenes RPWatcher-Addon- und Projekticon ergänzt.
- Erste stabile öffentliche Version von RPWatcher vorbereitet.
- Versions- und Veröffentlichungsdokumentation von 0.9.0 auf 1.0.0 finalisiert.
- Finale Release Notes und vollständige Testmatrix für das exakte 1.0.0-Paket ergänzt.
- Allowlist-basierter Paketbau, SHA-256 und Manifest für die stabile Veröffentlichung beibehalten.
- Scanner-, Status-, Performance-, TRP3-, Settings- und UI-Kern unverändert aus dem vollständig getesteten Release Candidate übernommen.

## 0.9.0 – Release Candidate

- Öffentliche Metadaten auf Autor Mercia, MIT-Lizenz und Version 0.9.0 vereinheitlicht.
- Vollständige MIT-Lizenzdatei und öffentliche Benutzer-, Datenschutz-, Support- und Drittanbieter-Dokumentation ergänzt.
- Deutsche und englische Projektseitentexte, Kurzbeschreibungen, Screenshotplan, Release Notes und Testmatrix vorbereitet.
- GitHub-Issue-Templates für Fehlerberichte und Funktionsvorschläge ergänzt.
- Reproduzierbare PowerShell-Validierung und Allowlist-basierten Paketbau hinzugefügt.
- Release-ZIP wird mit genau einem Ordner `RPWatcher`, SHA-256-Datei und Inhaltsmanifest erzeugt.
- Finales Lebenszyklus-, Scanner-, TRP3-, UI-, Sicherheits- und Datenschutz-Audit ohne funktionalen Releaseblocker abgeschlossen.
- Scanner-, Status-, Performance-, TRP3-, Settings- und UI-Kern unverändert aus dem getesteten Stand 0.6.0 übernommen.

## 0.6.0

- Zentrales, WoW-/TRP3-nahes Farbsystem und wiederverwendbare Darstellungshilfen in `Theme.lua` ergänzt.
- Hauptfenster mit abgesetzter Titelleiste, Statusbereich, klaren Trennlinien und dezentem Sperrindikator überarbeitet.
- Zugängliche Statusübersicht aus Symbol, Text, Farbe und Zähler eingeführt.
- Virtualisierte Watcher-Zeilen mit statusabhängigen Flächen, alternierender Leseführung und ereignisbasiertem Hoverzustand gestaltet.
- RP-/WoW-Namen, Statuszeiten und kompakte `Profil`-Buttons responsiv neu angeordnet.
- Namenstooltips um verständliche Statussätze ergänzt; interne GUIDs und Unit-Tokens bleiben verborgen.
- Erklärenden leeren Zustand sowie Tooltip für den Resize-Griff ergänzt.
- Einstellungsseite in Fenster, Verhalten und Total RP 3 gegliedert und mit kurzen Hilfetexten versehen.
- Synthetische Stressdaten um kurze, mittlere und sehr lange RP-Anzeigenamen für Layouttests ergänzt.
- Scanner-, Performance-, TRP3-, Speicher- und Virtualisierungslogik funktional unverändert beibehalten.

## 0.5.0

- Nameplate-Integritätsabgleich korrigiert: aktuelle Frames werden primär über die lokal verifizierte `GetUnit()`-Methode aufgelöst.
- `namePlateUnitToken` nur noch als defensiven Fallback verwendet; kein unbestätigtes `unitToken`-Feld eingeführt.
- Performancebericht in rohe Frames, aufgelöste Tokens, verwaltete Tokens, Kandidaten und Watcher präzisiert.
- Read-only-Diagnose `/rpw plates` mit Tokenwegen und kompakten Ablehnungsgründen ergänzt.
- Freundliche Spieler-Nameplates beim Hinzufügen statisch validiert und als schnelle Kandidaten zwischengespeichert.
- Dauerhaften Target-Scan auf GUID-Integrität und Target-Prüfung reduziert.
- Seltenen vollständigen Nameplate-Abgleich im bestehenden Scanner-Ticker ergänzt.
- Temporäre Token-Zuordnungen über `PLAYER_LEAVING_WORLD` und `PLAYER_ENTERING_WORLD` gehärtet.
- Standardmäßig deaktivierte, nicht persistente Performance-Diagnose über `debugprofilestop()` hinzugefügt.
- `/rpw perf` mit Aktivierung, Reset und kompaktem Bericht ergänzt.
- UI-Zeilen auf den sichtbaren Scrollausschnitt virtualisiert und Aktualisierungen verborgener Zeilen vermieden.
- Direkte RPWatcher-TRP3-Anfragen auf höchstens eine Anfrage pro Sekunde gedrosselt.
- Synthetische Lasttests mit `/rpw stress 25|50|100|200|clear` ergänzt.
- Vorherigen Hotpath und technische Optimierungsgründe in `PERFORMANCE_AUDIT.md` dokumentiert.

## 0.4.0

- Zentrales `Settings.lua`-Modul mit Datenbankschema 2, Validierung und Migration ergänzt.
- RPWatcher-Kategorie in der aktuellen Retail-Einstellungsoberfläche registriert.
- Fenstergröße, Skalierung, Hintergrundtransparenz und Sperrstatus konfigurierbar gemacht.
- Größenänderung über einen sperrbaren Griff mit gespeicherter Breite und Höhe ergänzt.
- Aufbewahrung unbekannter Watcher auf 15, 30, 60, 120 oder 300 Sekunden konfigurierbar gemacht.
- Manuelle Sichtbarkeit von der optionalen Auto-Ausblendung bei leerer Liste getrennt.
- Einstellbaren TRP3-Profilbutton und Statuszähler im Hauptfenster ergänzt.
- Slash-Befehle `/rpw options`, `/rpw lock`, `/rpw unlock` und `/rpw reset` hinzugefügt.
- Bestehende Fensterposition und Sichtbarkeit aus Version 0.3.0 werden bei der Migration erhalten.

## 0.3.0

- Optionale Integration mit Total RP 3 3.3.7 hinzugefügt.
- RP-Namen als nicht persistente Anzeigewerte mit WoW-Namensfallback ergänzt.
- Profilanfragen auf echte Watcher begrenzt und pro GUID auf 30 Sekunden gedrosselt.
- Aktualisierung über den zentralen TRP3-Callback `REGISTER_DATA_UPDATED` implementiert.
- Anklickbaren `[Profil]`-Verweis und Namenstooltips zu echten Watchern hinzugefügt.
- Profilöffnung über den lokal verifizierten Export `TRP3_API.slash.openProfile` gekapselt.
- Diagnosebefehle `/rpw trp3` und `/rpw refresh` ergänzt.
- Testdaten um künstliche RP-Anzeigenamen erweitert, ohne TRP3-Kommunikation auszulösen.
- Vollständigen Fallbackbetrieb ohne Total RP 3 beibehalten.

## 0.2.0

- Freundliche Spieler mit sichtbaren Nameplates GUID-basiert erfasst.
- Target-Prüfung mit einem zentralen Scanintervall von 0,25 Sekunden hinzugefügt.
- Status Grün, Grau und Unbekannt samt laufender Zeitdarstellung implementiert.
- Unbekannte Watcher werden nach 60 Sekunden ohne Nameplate entfernt.
- Wiederkehrende GUIDs werden vorhandenen Watchern ohne Duplikate zugeordnet.
- Scrollbare, wiederverwendbare UI-Zeilen ergänzt.
- Slash-Befehle `/rpw test`, `/rpw clear` und `/rpw help` hinzugefügt.
- Reload-Initialisierung über vorhandene Retail-Nameplates ergänzt.
- Watcher bleiben reine, nicht persistente Laufzeitdaten.

## 0.1.0

- Initiales Projektgrundgerüst erstellt.
- Minimales verschiebbares Hauptfenster mit leerem Listenbereich hinzugefügt.
- Sichtbarkeit und Fensterposition über `RPWatcherDB` gespeichert.
- Slash-Befehle `/rpw` und `/rpwatcher` hinzugefügt.
- Leere Modulflächen für Scanner und optionale Total-RP-3-Integration angelegt.
