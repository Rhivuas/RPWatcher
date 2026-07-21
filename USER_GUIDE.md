# RPWatcher – Benutzeranleitung

Diese Anleitung gilt für RPWatcher 0.9.0 Release Candidate auf World of Warcraft Retail. Die Addon-Oberfläche ist deutschsprachig.

## Installation

1. World of Warcraft vollständig beenden.
2. `RPWatcher-0.9.0.zip` entpacken.
3. Den enthaltenen Ordner `RPWatcher` nach `World of Warcraft\_retail_\Interface\AddOns\` kopieren.
4. Die Struktur prüfen: `...\AddOns\RPWatcher\RPWatcher.toc` muss direkt vorhanden sein.
5. Spiel starten und RPWatcher in der Addon-Liste aktivieren.
6. Freundliche Nameplates in den WoW-Einstellungen aktivieren.

Total RP 3 ist optional. Für RP-Namen und die Profilöffnung muss es separat installiert und aktiviert sein.

## Erster Start

Nach dem Laden bestätigt RPWatcher seine Initialisierung im Chat. Mit `/rpw` lässt sich das Hauptfenster ein- und ausblenden. Das Fenster kann entsperrt verschoben und am Griff unten rechts skaliert werden.

RPWatcher zeigt nicht jede sichtbare Person an. Ein freundlicher Spieler wird erst zum Watcher, nachdem seine sichtbare Nameplate mindestens einmal bestätigt hat, dass der Spieler dich im Target hatte.

RPWatcher erkennt Target-Auswahl – keine Blickrichtung, Kamerabewegung oder Mausposition.

## Statusbedeutung

### ● Aktuell

Die Nameplate ist sichtbar und der Spieler hat dich gerade im Target. Der Zeitwert beginnt mit diesem aktuellen Target-Vorgang.

### ● Vorher

Die Nameplate ist weiterhin sichtbar. Der Spieler hatte dich zuvor im Target, aktuell jedoch nicht mehr. Der Zeitwert beginnt beim erkannten Wechsel.

### ? Unbekannt

Die zuvor erkannte Nameplate ist nicht mehr sichtbar. Ohne gültige Nameplate-Unit kann WoW den Target-Status nicht bereitstellen. Der Eintrag bleibt je nach Einstellung 15 bis 300 Sekunden erhalten.

Farben werden immer durch Symbol und Text ergänzt.

## Total RP 3 und Profilbutton

Ist Total RP 3 verfügbar und ein RP-Name bekannt, zeigt RPWatcher diesen als Hauptnamen. Der vollständige normale WoW-Name bleibt erhalten und erscheint im Tooltip.

Der Button `Profil` ist nur bei echten Watchern und verfügbarer Profilöffnung aktiv. Er verändert dein Target nicht. Test- und Stressdaten besitzen keinen aktiven Profilbutton und lösen keine Profilanfrage aus.

Fehlen Profildaten, kann RPWatcher kontrolliert eine Anfrage über Total RP 3 vormerken. Pro Spieler gilt ein Cooldown von 30 Sekunden; zusätzlich wird höchstens eine RPWatcher-Anfrage pro Sekunde verarbeitet.

## Optionen

Öffne die Einstellungen über `/rpw options` oder **Optionen > AddOns > RPWatcher**.

- **Fenster sperren:** verhindert Verschieben und Größenänderung.
- **Fensterskalierung:** verändert die gesamte Fensterdarstellung zwischen 0,80 und 1,30.
- **Hintergrundtransparenz:** verändert hauptsächlich die dunklen Flächen.
- **Unbekannte Watcher behalten:** wählt 15, 30, 60, 120 oder 300 Sekunden.
- **Fenster ausblenden, wenn die Liste leer ist:** blendet ein manuell sichtbar gewünschtes Fenster vorübergehend aus.
- **TRP3-Profilbutton anzeigen:** verändert nur die Buttonanzeige, nicht RP-Namen oder Anfragen.
- **Fenster zurücksetzen:** setzt Position, Größe, Skalierung, Transparenz und Sperrstatus zurück.

Der Schließen-Button gilt als manuelles Verbergen. Ein neuer Watcher öffnet ein manuell verborgenes Fenster nicht automatisch.

## Slash-Befehle

| Befehl | Wirkung |
|---|---|
| `/rpw` | Fenster manuell umschalten |
| `/rpwatcher` | Langer Alias für `/rpw` |
| `/rpw help` | Befehlsübersicht |
| `/rpw test` | Drei lokale Testeinträge erzeugen |
| `/rpw clear` | Alle Laufzeit-Watcher und Testzustände entfernen |
| `/rpw options` | Einstellungen öffnen |
| `/rpw lock` | Fenster sperren |
| `/rpw unlock` | Fenster entsperren |
| `/rpw reset` | Fensterdarstellung zurücksetzen |
| `/rpw trp3` | TRP3-Diagnose |
| `/rpw refresh` | RP-Namen echter Watcher aktualisieren |
| `/rpw plates` | Nameplate-Momentaufnahme |
| `/rpw perf on|off|reset|report` | Laufzeitmessung steuern |
| `/rpw stress 25|50|100|200` | Synthetische UI-Last erzeugen |
| `/rpw stress clear` | Nur Stressdaten entfernen |

## Häufige Fragen

### Warum sehe ich viele Nameplates, aber keine Watcher?

Das ist korrekt, wenn niemand dich seit der Erfassung im Target hatte. `/rpw plates` zeigt Kandidaten unabhängig von der Watcherliste.

### Erkennt RPWatcher, ob jemand mich anschaut?

Nein. Es erkennt ausschließlich die API-seitig bestätigte Target-Auswahl.

### Warum wird ein Eintrag zum Fragezeichen?

Die Nameplate ist nicht mehr API-verfügbar. Der tatsächliche Target-Status ist deshalb unbekannt und darf nicht als „Vorher“ behauptet werden.

### Warum fehlt ein RP-Name?

Total RP 3 kann deaktiviert sein, das Profil kann unbekannt sein oder die andere Person verwendet kein kompatibles RP-Addon. RPWatcher fällt auf den normalen WoW-Namen zurück.

### Werden andere Spieler dauerhaft protokolliert?

Nein. Watcher, GUIDs, RP-Namen und Profilzustände bleiben ausschließlich im Arbeitsspeicher und werden bei Reload, Logout oder Neustart verworfen.

## Fehlerdiagnose

1. BugSack beziehungsweise die WoW-Lua-Fehleranzeige aktivieren.
2. `/rpw clear` und `/reload` ausführen.
3. Problem möglichst exakt reproduzieren.
4. `/rpw plates` ausgeben, wenn Nameplates oder Kandidaten betroffen sind.
5. Bei Performanceproblemen `/rpw perf on`, einige Minuten messen und `/rpw perf report` ausgeben.
6. Total RP 3 testweise deaktivieren, wenn RP-Namen oder Profilöffnung betroffen sind.
7. Angaben aus [SUPPORT.md](SUPPORT.md) zusammenstellen.

Keine Accountdaten, GUIDs oder vollständigen RP-Profile übermitteln.

## Vollständige Deinstallation

1. World of Warcraft beenden.
2. Den Ordner `World of Warcraft\_retail_\Interface\AddOns\RPWatcher` löschen.
3. Für eine vollständige Entfernung der Einstellungen zusätzlich `RPWatcher.lua` und gegebenenfalls `RPWatcher.lua.bak` unter `World of Warcraft\_retail_\WTF\Account\<Account>\SavedVariables\` entfernen.

Diese Dateien enthalten ausschließlich RPWatcher-Fenster- und Benutzereinstellungen, keine Watcher-Historie oder fremden Profile.
