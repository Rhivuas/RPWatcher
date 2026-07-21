# RPWatcher 0.9.0 Release Candidate

RPWatcher 0.9.0 bündelt den vollständig getesteten Funktionsstand, die operative Härtung und die visuelle Überarbeitung als öffentlichen Release Candidate. Diese Phase führt keine neuen Kernfunktionen ein.

## Wichtigste Funktionen

- freundliche Spieler über sichtbare Nameplate-Units erfassen
- Watcher erst nach einem bestätigten Target-Vorgang anzeigen
- Aktuell, Vorher und Unbekannt mit laufenden Zeitangaben
- GUID-basierte Wiedererkennung ohne Duplikate
- konfigurierbare Aufbewahrung unbekannter Watcher
- skalierbares, sperrbares und automatisch ausblendbares Fenster

## Operative Härtung

- statische Kandidatenprüfung außerhalb des schnellen Target-Pfads
- ein zentraler 0,25-Sekunden-Ticker
- Fünf-Sekunden-Integritätsabgleich über `GetUnit()` mit defensivem Fallback
- sichere Zonenwechsel- und Tokenbereinigung
- virtualisierte Listenzeilen für größere Mengen
- nicht persistente Performance- und Nameplate-Diagnose
- gedrosselte Total-RP-3-Anfragewarteschlange

## Visuelle Überarbeitung

- zentrales dunkles WoW-/TRP3-nahes Farbsystem
- klare Titel-, Status- und Listenbereiche
- Status nicht nur über Farbe, sondern zusätzlich über Symbol und Text
- kompakte Profilbuttons und erweiterte Tooltips
- erklärender Leerzustand und gruppierte Einstellungsseite

## Total-RP-3-Integration

Total RP 3 bleibt vollständig optional. Bekannte RP-Namen werden als nicht persistente Anzeige verwendet; der normale WoW-Name bleibt erhalten. Profilöffnung und Callback-Aktualisierung wurden gegen Total RP 3 3.3.7 verifiziert.

## Datenschutz

RPWatcher verwendet keine Telemetrie oder externen Dienste. Watcher, fremde GUIDs, RP-Namen, Profile, Diagnosewerte und Warteschlangen werden nicht dauerhaft gespeichert. `RPWatcherDB` enthält nur eigene Einstellungen.

## Bekannte Grenzen

- RPWatcher erkennt Target-Auswahl, keine Blickrichtung.
- Nur API-verfügbare sichtbare Nameplates können live geprüft werden.
- Sehr kurze Target-Wechsel können zwischen Scans liegen.
- Ohne sichtbare Nameplate ist der Target-Status unbekannt.
- Total-RP-3-Profile können fehlen oder versionsabhängige API-Änderungen erfahren.

## Testhinweis

Der Release Candidate muss als exaktes Artefakt `RPWatcher-0.9.0.zip` getestet werden. Ein späterer Tag `v0.9.0` darf erst gesetzt werden, wenn ZIP-Datei und zugehörige SHA-256 eindeutig dokumentiert und erfolgreich geprüft wurden.

## Feedback

Bitte Versionen, Reproduktionsschritte, erwartetes und tatsächliches Verhalten, BugSack-Ausgabe sowie bei Bedarf `/rpw plates` und `/rpw perf report` angeben. Keine Accountdaten, GUIDs oder vollständigen RP-Profile mitsenden.
