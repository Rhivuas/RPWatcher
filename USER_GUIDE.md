# RPWatcher – Benutzeranleitung

Diese Anleitung gilt für RPWatcher 1.3.0 auf World of Warcraft Retail. Seit 1.3.0 erkennt RPWatcher die WoW-Clientsprache automatisch: Auf einem deutschen Client (`deDE`) ist die Oberfläche deutsch, auf `enUS`, `enGB` und jeder anderen beziehungsweise noch nicht unterstützten Sprache englisch. Es gibt keine manuelle Sprachauswahl, keinen Sprach-Slash-Befehl und keine gespeicherte Spracheinstellung. Diese Anleitung selbst bleibt deutschsprachig; die englischen Texte entsprechen sinngemäß denselben Inhalten.

## Installation

1. World of Warcraft vollständig beenden.
2. `RPWatcher-1.3.0.zip` entpacken.
3. Den enthaltenen Ordner `RPWatcher` nach `World of Warcraft\_retail_\Interface\AddOns\` kopieren.
4. Die Struktur prüfen: `...\AddOns\RPWatcher\RPWatcher.toc` muss direkt vorhanden sein.
5. Spiel starten und RPWatcher in der Addon-Liste aktivieren.
6. Freundliche Nameplates in den WoW-Einstellungen aktivieren.

Total RP 3 ist optional. Für RP-Namen und die Profilöffnung muss es separat installiert und aktiviert sein.

Das eigene RPWatcher-Icon kennzeichnet das Addon in unterstützten WoW-Addonansichten. Das Runtime-Asset liegt im Paket unter `Media/RPWatcherIcon.tga` und wird zusammen mit RPWatcher unter MIT veröffentlicht.

## Update von 1.0.0

1. World of Warcraft vollständig beenden.
2. Den vorhandenen Ordner `Interface\AddOns\RPWatcher` durch den Ordner aus `RPWatcher-1.1.0.zip` ersetzen.
3. Die SavedVariables beibehalten, wenn Fenster- und Benutzereinstellungen erhalten bleiben sollen.
4. Spiel starten und in der Addon-Liste Version 1.1.0 prüfen.

Das Datenbankschema wird beim Update von 1.0.0 auf 1.1.0 kontrolliert von Version 2 auf Version 3 erhöht, um die neue Minimap-Einstellung zu speichern. Bestehende Fenster- und Benutzereinstellungen bleiben vollständig erhalten; die neuen Felder erhalten automatisch Standardwerte. Fremde Watcher-, GUID-, RP-Namen- und Profildaten werden grundsätzlich nicht dauerhaft gespeichert.

## Erster Start

Nach dem Laden bestätigt RPWatcher seine Initialisierung im Chat. Mit `/rpw` lässt sich das Hauptfenster ein- und ausblenden. Das Fenster kann entsperrt verschoben und am Griff unten rechts skaliert werden.

RPWatcher zeigt nicht jede sichtbare Person an. Ein freundlicher Spieler wird erst zum Watcher, nachdem seine sichtbare Nameplate mindestens einmal bestätigt hat, dass der Spieler dich im Target hatte.

RPWatcher erkennt Target-Auswahl – keine Blickrichtung, Kamerabewegung oder Mausposition.

## Statusbedeutung

Seit 1.1.0 unterscheiden sich die drei Zustände durch deutlich unterschiedliche, aus Texture-/Frame-Objekten aufgebaute Symbole, nicht nur durch Farbe. Symbol, Farbe und Text benennen jeden Zustand gemeinsam.

### Aktuell (grün) – Augen-Symbol

Ein kleines Augen-Symbol (Ausschnitt des originalen RPWatcher-Icons, grün eingefärbt). Die Nameplate ist sichtbar und der Spieler hat dich gerade im Target. Der Zeitwert beginnt mit diesem aktuellen Target-Vorgang.

### Vorher (grau) – Verlaufspfeil

Ein kompakter, nach links gerichteter Verlaufspfeil. Die Nameplate ist weiterhin sichtbar. Der Spieler hatte dich zuvor im Target, aktuell jedoch nicht mehr. Der Zeitwert beginnt beim erkannten Wechsel.

### Unbekannt (gold) – Fragezeichen

Die zuvor erkannte Nameplate ist nicht mehr sichtbar. Ohne gültige Nameplate-Unit kann WoW den Target-Status nicht bereitstellen. Der Eintrag bleibt je nach Einstellung 15 bis 300 Sekunden erhalten.

## Total RP 3 und Profilbutton

Ist Total RP 3 verfügbar und ein RP-Name bekannt, zeigt RPWatcher diesen als Hauptnamen. Der vollständige normale WoW-Name bleibt erhalten und erscheint im Tooltip.

Der Button `Profil` erscheint seit 1.1.0 ausschließlich, wenn für den betreffenden echten Watcher tatsächlich ein Total-RP-3-Profil bestätigt wurde. Ein bekannter RP-Name allein aktiviert den Button nicht mehr. Ohne bestätigtes Profil bleibt der Button verborgen und beansprucht keinen Platz in der Zeile; Name und Zeittext nutzen den frei werdenden Platz. Sobald ein Profil später über Total RP 3 bestätigt wird, erscheint der Button ohne Reload. Test- und Stressdaten besitzen niemals einen aktiven Profilbutton und lösen keine Profilanfrage aus. Der Button verändert dein Target nicht.

Wechselt ein Watcher mit bereits bestätigtem Profil in den Status Unbekannt, weil seine Nameplate nicht mehr sichtbar ist, bleibt der Profilbutton weiterhin sichtbar und nutzbar, solange das Profil zuvor sicher bestätigt wurde.

Fehlen Profildaten, kann RPWatcher kontrolliert eine Anfrage über Total RP 3 vormerken. Pro Spieler gilt ein Cooldown von 30 Sekunden; zusätzlich wird höchstens eine RPWatcher-Anfrage pro Sekunde verarbeitet.

## Minimap-Schaltfläche

RPWatcher zeigt seit 1.1.0 eine eigene Minimap-Schaltfläche mit dem originalen RPWatcher-Icon:

- **Linksklick:** blendet das RPWatcher-Hauptfenster ein oder aus – identisch zu `/rpw`.
- **Rechtsklick:** öffnet die RPWatcher-Einstellungen – identisch zu `/rpw options`.
- **Ziehen:** verschiebt die Schaltfläche entlang des Minimap-Randes. Die Position wird gespeichert und bleibt nach `/reload` erhalten.

Unter **Optionen > AddOns > RPWatcher** beziehungsweise `/rpw options` lässt sich die Schaltfläche über „Minimap-Schaltfläche anzeigen“ ein- oder ausblenden. Das Ausblenden löscht die gespeicherte Position nicht; beim erneuten Aktivieren erscheint die Schaltfläche wieder an derselben Stelle. `/rpw reset` verändert weder Sichtbarkeit noch Position der Minimap-Schaltfläche – es setzt ausschließlich die dokumentierten Fensterwerte zurück. RPWatcher bleibt zusätzlich vollständig über `/rpw` und `/rpw options` bedienbar.

## Optionen

Öffne die Einstellungen über `/rpw options` oder **Optionen > AddOns > RPWatcher**.

- **Fenster sperren:** verhindert Verschieben und Größenänderung.
- **Fensterskalierung:** verändert die gesamte Fensterdarstellung zwischen 0,80 und 1,30.
- **Hintergrundtransparenz:** verändert hauptsächlich die dunklen Flächen.
- **Unbekannte Watcher behalten:** wählt 15, 30, 60, 120 oder 300 Sekunden.
- **Fenster ausblenden, wenn die Liste leer ist:** blendet ein manuell sichtbar gewünschtes Fenster vorübergehend aus.
- **TRP3-Profilbutton anzeigen:** verändert nur die Buttonanzeige, nicht RP-Namen, Profilprüfung oder Anfragen.
- **Minimap-Schaltfläche anzeigen:** blendet die Minimap-Schaltfläche ein oder aus, ohne die gespeicherte Position zu verändern.
- **Fenster zurücksetzen:** setzt Position, Größe, Skalierung, Transparenz und Sperrstatus zurück; Minimap-Sichtbarkeit und -Position bleiben davon unberührt.

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

### Warum sehe ich keinen Profilbutton, obwohl ein RP-Name angezeigt wird?

Ein bekannter RP-Name allein bestätigt kein vorhandenes Total-RP-3-Profil. Der Button erscheint erst, sobald RPWatcher ein echtes Profil bestätigt hat.

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
