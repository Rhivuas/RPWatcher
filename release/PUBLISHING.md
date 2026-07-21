# Veröffentlichung von RPWatcher 1.0.0

Dieses Dokument beschreibt die spätere Veröffentlichung der stabilen Version. Es autorisiert in diesem Arbeitsauftrag keinen Upload, kein Remote und keine Erstellung von Plattformprojekten oder Zugangsdaten.

## Gemeinsame Vorbereitung

1. `tools/Build-Release.ps1 -ExpectedVersion 1.0.0 -RequireCleanGit` aus einem sauberen committed Stand ausführen.
2. `dist/RPWatcher-1.0.0.zip`, `.sha256` und Manifest prüfen.
3. Das exakte ZIP anhand von `release/TEST_MATRIX_1.0.0.md` in WoW testen.
4. Den tatsächlich getesteten SHA-256 in der Testmatrix und im Freigabebericht dokumentieren.
5. Erst nach erfolgreichem Test des exakten Artefakts den Git-Tag `v1.0.0` setzen.
6. Version 1.0.0 auf öffentlichen Plattformen als **Stable/Release** kennzeichnen.

Immer das Allowlist-generierte Release-ZIP hochladen. Weder den vollständigen Repository-Download noch automatisch erzeugte Quellcode-Archive als WoW-Addon-Paket verwenden.

## Projektgrafiken

- Für große Projektgrafiken bevorzugt `release/assets/RPWatcherIcon_1024.png` verwenden.
- Falls die Plattform eine kleinere Datei verlangt, `release/assets/RPWatcherIcon_512.png` verwenden.
- `release/assets/RPWatcherIcon_64_preview.png` dient nur als kleine Vorschau.
- Das Runtime-Icon `Media/RPWatcherIcon.tga` bleibt Bestandteil des Allowlist-ZIPs; die drei Projekt-PNGs werden nicht in das WoW-Addon-Paket aufgenommen.
- Das Icon ist ein originales RPWatcher-Asset und wird gemeinsam mit dem Projekt unter MIT veröffentlicht.

## GitHub Releases

1. Erst nach ausdrücklicher Freigabe ein öffentliches Repository beziehungsweise Remote einrichten.
2. Nach Artefakttest und Tagging ein Release mit Titel `RPWatcher 1.0.0` anlegen.
3. Nicht als Pre-Release markieren.
4. `release/RELEASE_NOTES_1.0.0.md` als Grundlage verwenden.
5. `RPWatcher-1.0.0.zip` und optional `.sha256` sowie Manifest anhängen.
6. Prüfen, dass das eigene ZIP hervorgehoben wird und nicht nur GitHubs Source-Code-Archive.

## CurseForge

1. Projekt über die CurseForge-Oberfläche erstellen.
2. Keine Curse-Projekt-ID erfinden oder als Platzhalter in die TOC schreiben.
3. Das eigene `RPWatcher-1.0.0.zip` hochladen.
4. Release-Typ **Release** beziehungsweise **Stable** wählen.
5. Retail-Kompatibilität und Interface-Version prüfen.
6. Deutsche Projektbeschreibung verwenden und die englische Beschreibung ergänzen, sofern die Plattform dies unterstützt.

Eine echte `X-Curse-Project-ID` darf erst nach Erhalt einer realen ID in einer eigenen geprüften Änderung ergänzt werden.

## Wago Addons

1. Projekt über Wago Addons erstellen.
2. Keine Wago-Projekt-ID erfinden.
3. Das eigene `RPWatcher-1.0.0.zip` als stabile Version hochladen.
4. Projektbeschreibung, Datenschutz und Supporthinweis übernehmen.
5. Dateistruktur im Plattform-Preview prüfen.

`X-Wago-ID` wird erst nach Erstellung des Projekts und Erhalt einer echten ID ergänzt. Bis dahin bleibt die Metadatenzeile vollständig aus der TOC entfernt.

## Zugangsdaten

- Keine API-Schlüssel, Tokens, Cookies oder Passwörter in Dateien, Skripten, Git-Historie oder Issue-Templates speichern.
- Plattformzugänge ausschließlich über sichere Benutzeroberflächen beziehungsweise später ausdrücklich autorisierte Secret-Stores verwenden.
- Diagnoselogs vor Veröffentlichung auf private Namen und Accountdaten prüfen.
