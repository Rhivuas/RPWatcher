# RPWatcher

RPWatcher ist ein deutschsprachiges Addon für World of Warcraft Retail. Es zeigt freundliche Spieler mit sichtbarer Nameplate an, nachdem sie den eigenen Charakter mindestens einmal im Target hatten. Ein aktueller, früherer oder wegen fehlender Nameplate unbekannter Target-Status wird übersichtlich dargestellt. Total RP 3 kann optional RP-Namen und Profilöffnung ergänzen.

- **Version:** 0.9.0 Release Candidate
- **Autor:** Mercia
- **Lizenz:** MIT
- **Copyright:** Copyright 2026 Mercia

## Wichtig: Target-Auswahl, nicht Blickrichtung

RPWatcher erkennt ausschließlich, ob eine von der WoW-API bereitgestellte Nameplate-Unit den eigenen Charakter im Target hat. Das Addon erkennt keine Blickrichtung, Kamerarichtung, Mausbewegung oder Aufmerksamkeit außerhalb der Target-Auswahl.

Nur aktuell API-verfügbare sichtbare Nameplates können live geprüft werden. Spieler ohne sichtbare Nameplate erscheinen erst dann in der Liste, wenn sie zuvor als Watcher erkannt wurden; ihr Status ist anschließend bis zum Ablauf der eingestellten Aufbewahrung unbekannt.

## Hauptfunktionen

- Erfasst ausschließlich freundliche Spielercharaktere mit sichtbarer Nameplate.
- Schließt den eigenen Spieler, NPCs, Gegner und nicht qualifizierte Units aus.
- Nimmt einen Spieler erst nach einem erkannten Target-Vorgang auf.
- Verwaltet Watcher GUID-basiert und vermeidet Duplikate.
- Zeigt aktuelle, frühere und unbekannte Watcher mit laufenden Zeitangaben.
- Erkennt zurückkehrende Nameplates innerhalb der Aufbewahrungszeit wieder.
- Bietet ein skalierbares, verschiebbares, sperrbares und virtualisiertes Fenster.
- Unterstützt optional RP-Namen und Profilöffnung über Total RP 3.
- Enthält nicht persistente Diagnose- und synthetische Belastungstests.

## Voraussetzungen

- World of Warcraft Retail mit Interface `120007` oder einer kompatiblen neueren Retail-Version.
- Aktivierte freundliche Nameplates für die reale Erfassung.
- Total RP 3 ist optional und wird nicht mitgeliefert.

Die Interface-Nummer wurde lokal anhand von Total RP 3 3.3.7 für den Retail-Client verifiziert.

## Installation

1. `RPWatcher-0.9.0.zip` entpacken.
2. Den enthaltenen Ordner `RPWatcher` nach `World of Warcraft\_retail_\Interface\AddOns\` kopieren.
3. Prüfen, dass die Datei `RPWatcher\RPWatcher.toc` existiert und keine Struktur `RPWatcher\RPWatcher\RPWatcher.toc` entstanden ist.
4. World of Warcraft vollständig starten beziehungsweise neu starten.
5. RPWatcher in der Addon-Liste aktivieren.

## Update

1. World of Warcraft beenden.
2. Den vorhandenen Addonordner `RPWatcher` durch den Ordner aus dem neuen Release-ZIP ersetzen.
3. Eigene SavedVariables nicht löschen, wenn Fenster- und Anzeigeeinstellungen erhalten bleiben sollen.
4. Spiel starten und mit `/rpw`, `/rpw options` sowie `/reload` die Übernahme prüfen.

Beim Update von 0.6.0 bleibt das Datenbankschema unverändert. Watcher- und RP-Daten sind reine Laufzeitdaten und werden bei Reload oder Neustart ohnehin verworfen.

## Statuszustände

- **● Aktuell (grün):** Der sichtbare Spieler hat dich gerade im Target; Zeittext `seit …`.
- **● Vorher (grau):** Der weiterhin sichtbare Spieler hatte dich zuvor im Target; Zeittext `zuletzt vor …`.
- **? Unbekannt:** Die Nameplate ist nicht mehr sichtbar, daher kann der aktuelle Target-Status nicht geprüft werden; Zeittext `nicht sichtbar · …`.

Farbe ist nicht das einzige Merkmal: Symbol und Text benennen jeden Zustand zusätzlich.

## Total-RP-3-Integration

RPWatcher funktioniert vollständig ohne Total RP 3. Wenn Total RP 3 verfügbar ist:

- wird ein bekannter RP-Name als Anzeigename verwendet,
- bleibt der normale vollständige WoW-Name technisch erhalten,
- kann ein echtes Watcherprofil über `Profil` geöffnet werden,
- werden Profilanfragen pro GUID 30 Sekunden gedrosselt und zusätzlich global begrenzt.

RPWatcher liest oder speichert keine Profiltexte. Test- und Stressdaten lösen niemals TRP3-Kommunikation aus. Die Profilöffnung verwendet den lokal gegen Total RP 3 3.3.7 verifizierten Export `TRP3_API.slash.openProfile` und verändert das aktuelle Target nicht.

## Einstellungen

Die Seite **Optionen > AddOns > RPWatcher** beziehungsweise `/rpw options` enthält:

- Fenster sperren
- Fensterskalierung von 0,80 bis 1,30
- Hintergrundtransparenz von 50 bis 100 Prozent
- unbekannte Watcher 15, 30, 60, 120 oder 300 Sekunden behalten
- Fenster bei leerer Liste automatisch ausblenden
- TRP3-Profilbutton ein- oder ausblenden
- Position und Darstellung des Fensters zurücksetzen

Manuelle Sichtbarkeit und vorübergehende Auto-Ausblendung bleiben getrennt. Ein manuell geschlossenes Fenster wird durch neue Watcher nicht ungefragt geöffnet.

## Slash-Befehle

- `/rpw` – Fenster manuell ein- oder ausblenden.
- `/rpwatcher` – identischer langer Alias.
- `/rpw help` – Befehlsübersicht anzeigen.
- `/rpw test` – drei nicht persistente Testeinträge erzeugen.
- `/rpw clear` – alle Laufzeit-Watcher, Testdaten und RPWatcher-TRP3-Zustände entfernen.
- `/rpw options` – Einstellungsseite öffnen.
- `/rpw lock` – Fenster sperren.
- `/rpw unlock` – Fenster entsperren.
- `/rpw reset` – Position, Größe, Skalierung, Transparenz und Sperrstatus zurücksetzen.
- `/rpw trp3` – Verfügbarkeit der optionalen Integration anzeigen.
- `/rpw refresh` – RP-Namen echter Watcher kontrolliert aktualisieren.

## Erweiterte Diagnose

Diese Befehle erzeugen ausschließlich nicht persistente Laufzeitdaten:

- `/rpw plates` – aktuelle Nameplate-Auflösung und Ablehnungsgründe anzeigen.
- `/rpw perf` – Diagnosezustand und Hilfe anzeigen.
- `/rpw perf on|off|reset|report` – Performance-Messung steuern beziehungsweise berichten.
- `/rpw stress 25|50|100|200` – synthetische UI-Last erzeugen.
- `/rpw stress clear` – ausschließlich Stressdaten entfernen.

Diagnose und Stressdaten enthalten keine echten GUID-Ausgaben, werden nicht gespeichert und lösen keine Unit- oder TRP3-Aufrufe mit künstlichen Identitäten aus.

## Datenschutz

RPWatcher besitzt keine Telemetrie, Werbung oder externen Netzwerkzugriffe. Es speichert keine Watcher-Historie, fremden GUIDs, RP-Namen oder Profiltexte dauerhaft. `RPWatcherDB` enthält ausschließlich eigene Fenster- und Benutzereinstellungen. Details stehen in [PRIVACY.md](PRIVACY.md).

## Technische Grenzen

- Nur sichtbare, von der WoW-API bereitgestellte Nameplate-Units können live geprüft werden.
- Sehr kurze Target-Wechsel können zwischen zwei Scans von 0,25 Sekunden liegen.
- Ohne Nameplate ist der aktuelle Target-Status unbekannt.
- Andere Spieler ohne kompatibles RP-Addon liefern möglicherweise keinen RP-Namen.
- Diagnose-Stressdaten testen die UI, aber keine echten Netzwerk- oder Nameplate-Bedingungen.

## Fehlerberichte

Bitte zuerst [SUPPORT.md](SUPPORT.md) lesen. Ein hilfreicher Bericht enthält RPWatcher- und WoW-Version, TRP3-Version oder „deaktiviert“, Reproduktionsschritte, erwartetes und tatsächliches Verhalten, BugSack-Ausgabe sowie bei Bedarf `/rpw plates` und `/rpw perf report`.

Keine Accountdaten, GUIDs oder vollständigen RP-Profile veröffentlichen.

## Weitere Dokumentation

- [Benutzeranleitung](USER_GUIDE.md)
- [Datenschutz](PRIVACY.md)
- [Support und Fehlerberichte](SUPPORT.md)
- [Drittanbieterhinweise](THIRD_PARTY_NOTICES.md)
- [Changelog](CHANGELOG.md)

## Lizenz und Autor

RPWatcher ist freie Software unter der [MIT-Lizenz](LICENSE).

Copyright 2026 Mercia. Autor: **Mercia**.
