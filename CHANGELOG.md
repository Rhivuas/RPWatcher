# Changelog

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
