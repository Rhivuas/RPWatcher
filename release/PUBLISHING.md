# Veröffentlichung von RPWatcher 0.9.0

Dieses Dokument bereitet Veröffentlichungen vor. Es autorisiert keinen Upload. Für den aktuellen Release-Candidate-Auftrag werden kein Remote angelegt, keine Plattformprojekte erstellt, keine API-Schlüssel erzeugt und keine Dateien hochgeladen.

## Gemeinsame Vorbereitung

1. `tools/Build-Release.ps1 -ExpectedVersion 0.9.0 -RequireCleanGit` aus einem sauberen committed Stand ausführen.
2. `dist/RPWatcher-0.9.0.zip`, `.sha256` und Manifest prüfen.
3. Das exakte ZIP anhand von `release/TEST_MATRIX_0.9.0.md` in WoW testen.
4. Getestete SHA-256 dokumentieren.
5. Release Candidate auf öffentlichen Plattformen als **Beta** beziehungsweise **Pre-Release** markieren.
6. Erst nach Test des exakten Artefakts einen passenden Git-Tag erwägen.
7. Version 1.0.0 später separat als **Stable** veröffentlichen.

Immer das Allowlist-generierte Release-ZIP hochladen. Nicht den vollständigen Repository-Download oder einen automatisch erzeugten Quellcode-Snapshot als WoW-Addon-Paket verwenden.

## GitHub Releases

1. Erst nach ausdrücklicher Freigabe ein öffentliches Repository beziehungsweise Remote einrichten.
2. Release mit Titel `RPWatcher 0.9.0 Release Candidate` anlegen.
3. Als **Pre-release** markieren.
4. `release/RELEASE_NOTES_0.9.0.md` als Grundlage verwenden.
5. `RPWatcher-0.9.0.zip` und optional die `.sha256` sowie Manifestdatei anhängen.
6. Prüfen, dass der Download das eigene ZIP und nicht nur GitHubs Source-Code-Archive hervorhebt.

## CurseForge

1. Projekt erst über die CurseForge-Oberfläche erstellen.
2. Keine Curse-Projekt-ID erfinden oder als Platzhalter in die TOC schreiben.
3. Das eigene `RPWatcher-0.9.0.zip` hochladen.
4. Release-Typ **Beta** wählen.
5. Retail-Kompatibilität und Interface-Version prüfen.
6. Deutsche Projektbeschreibung verwenden; englische Beschreibung bei unterstützter Lokalisierung ergänzen.

Eine echte `X-Curse-Project-ID` darf erst nach Erhalt einer realen ID und in einer eigenen geprüften Änderung ergänzt werden.

## Wago Addons

1. Projekt über Wago Addons erstellen.
2. Keine Wago-Projekt-ID erfinden.
3. Das eigene `RPWatcher-0.9.0.zip` als Beta/Pre-Release hochladen.
4. Projektbeschreibung, Datenschutz und Supporthinweis übernehmen.
5. Dateistruktur im Plattform-Preview prüfen.

`X-Wago-ID` wird erst nach Erstellung des Projekts und Erhalt einer echten ID ergänzt. Bis dahin bleibt die Metadatenzeile vollständig aus der TOC entfernt.

## Zugangsdaten

- Keine API-Schlüssel, Tokens, Cookies oder Passwörter in Dateien, Skripten, Git-Historie oder Issue-Templates speichern.
- Plattformzugänge ausschließlich über die jeweiligen sicheren Benutzeroberflächen beziehungsweise später ausdrücklich autorisierte Secret-Stores verwenden.
- Diagnoselogs vor Veröffentlichung auf private Namen und Accountdaten prüfen.
