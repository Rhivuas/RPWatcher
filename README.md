# RPWatcher

RPWatcher ist ein World-of-Warcraft-Retail-Addon. Es erkennt freundliche Spieler mit sichtbarer Nameplate und zeigt an, ob diese den eigenen Spielercharakter aktuell oder zuvor im Target hatten. Optional zeigt es bekannte RP-Namen aus Total RP 3 an und öffnet deren Profile.

## Entwicklungsstand

Version 0.4.0 implementiert Phase 4 mit einer eigenen Einstellungsseite, robuster Fensterverwaltung und Statuszählern. Die getestete GUID-basierte Nameplate-, Target- und TRP3-Logik aus den Versionen 0.2.0 und 0.3.0 bleibt erhalten. Der zentrale Scanner läuft unverändert alle 0,25 Sekunden; ein zweiter dauerhafter Timer wird nicht verwendet.

Ein Spieler erscheint erst, nachdem er den eigenen Charakter mindestens einmal im Target hatte. Berücksichtigt werden ausschließlich gültige Nameplate-Unit-Tokens freundlicher Spielercharaktere ungleich dem eigenen Spieler.

Watcher, RP-Namen, Profilinformationen und TRP3-Abfragezustände sind reine Laufzeitdaten. `RPWatcherDB` speichert ausschließlich Addon-, Fenster- und Anzeigeeinstellungen.

## Statuszustände

- **Grün / Aktuell:** sichtbare Nameplate und aktuelles Target auf dem Benutzer; Anzeige `seit …`.
- **Grau / Vorher:** sichtbare Nameplate, aber Target wurde gewechselt; Anzeige `zuletzt vor …`.
- **Unbekannt:** Nameplate ist nicht mehr sichtbar; Anzeige `nicht mehr sichtbar · vor …`.

Die Statuszeile im Fenster zeigt `Aktuell`, `Vorher` und `Unbekannt`. Die drei mit `/rpw test` erzeugten Testeinträge werden in diesen sichtbaren Zählern mitgezählt.

Unbekannte Watcher werden nach der gewählten Aufbewahrungszeit entfernt. Zur Auswahl stehen 15, 30, 60, 120 und 300 Sekunden; Standard sind 60 Sekunden. Änderungen gelten unmittelbar auch für bereits unbekannte Einträge und werden vom vorhandenen zentralen Scanner ausgewertet.

## Einstellungen und Fenster

Die Kategorie **RPWatcher** ist unter **Optionen > AddOns** registriert und kann mit `/rpw options` direkt geöffnet werden. Sie enthält:

- **Fenster sperren:** verhindert Verschieben und Größenänderung; die Änderung gilt sofort.
- **Fensterskalierung:** 0,80 bis 1,30 in Schritten von 0,05.
- **Hintergrundtransparenz:** 50 bis 100 Prozent; Texte und Bedienelemente behalten ihre Lesbarkeit.
- **Unbekannte Watcher behalten:** schaltet zyklisch durch 15, 30, 60, 120 und 300 Sekunden.
- **Fenster ausblenden, wenn die Liste leer ist:** blendet nur vorübergehend aus.
- **TRP3-Profilbutton anzeigen:** verbirgt oder zeigt `[Profil]`, ohne RP-Namen oder Profilanfragen zu beeinflussen.
- **Fenster zurücksetzen:** setzt ausschließlich Position, Größe, Skalierung, Transparenz und Sperrstatus zurück.

Das entsperrte Fenster lässt sich am Griff unten rechts zwischen 320 × 170 und 750 × 700 Pixeln skalieren. Größe, Position, Skalierung, Transparenz und Sperrstatus bleiben nach `/reload` erhalten. Der Listenbereich passt sich an und verwendet weiterhin wiederverwendete Scrollzeilen.

### Sichtbarkeitslogik

Die manuell gewünschte Sichtbarkeit und das automatische Ausblenden sind getrennt:

- Manuell verborgen bleibt das Fenster immer verborgen, auch wenn Watcher erscheinen.
- Manuell sichtbar und Auto-Ausblendung aus bleibt das Fenster auch mit leerer Liste sichtbar.
- Manuell sichtbar und Auto-Ausblendung an zeigt das Fenster nur bei mindestens einem Watcher.

Der Schließen-Button und `/rpw` ändern ausschließlich die manuell gewünschte Sichtbarkeit. Automatisches Ausblenden schreibt diesen Wert nicht um. Wird Auto-Ausblendung deaktiviert, erscheint ein manuell sichtbar gewünschtes Fenster wieder.

## Datenbankschema und Migration

Version 0.4.0 verwendet `schemaVersion = 2`. Beim Laden werden bestehende Version-0.3.0-Daten validiert und ergänzt. Vorhandene Fensterposition und manuelle Sichtbarkeit bleiben erhalten; fehlende neue Felder erhalten Standardwerte. Ungültige Größen, Skalierungen, Transparenzwerte, Ankerpunkte und Aufbewahrungswerte werden auf erlaubte Werte begrenzt beziehungsweise auf sichere Standards gesetzt.

Die Migration legt keine Watcher-, Profil- oder RP-Daten an.

## Optionale Total-RP-3-Integration

RPWatcher funktioniert vollständig ohne installiertes oder aktiviertes Total RP 3. Wenn Total RP 3 verfügbar ist, wird ein bekannter nichtleerer RP-Name angezeigt, andernfalls der vollständige normale WoW-Name. Der normale WoW-Name bleibt immer als technische Identität erhalten. Profilanfragen erfolgen nur für echte Watcher und sind pro GUID 30 Sekunden lang gedrosselt.

Später eintreffende Profildaten werden über den zentralen Total-RP-3-Callback `REGISTER_DATA_UPDATED` verarbeitet. Es gibt keinen zusätzlichen Polling-Ticker. Testdaten lösen niemals TRP3-Kommunikation aus.

### Technische Abhängigkeit der Profilöffnung

Die lokale Referenz ist Total RP 3 Version `3.3.7`. Die Profilöffnung ist vollständig in `TRP3.lua` gekapselt und verwendet:

```text
TRP3_API.slash.openProfile(characterIDOderName)
```

Dieser Export wird in Total RP 3 3.3.7 selbst für `/trp3 open` und Unit-Popup-Profilaktionen verwendet. Er befindet sich im öffentlichen `TRP3_API`-Namespace, wird aber als versionsabhängiger, lokal verifizierter Integrationspunkt behandelt. Fehlt er in einer späteren Version, bleibt RPWatcher funktionsfähig und blendet den Profilbutton aus.

## Interface-Version

Die Interface-Nummer `120007` stammt aus `F:\World of Warcraft\_retail_\Interface\AddOns\totalRP3\totalRP3.toc`. Nach einem Retail-Patch muss sie gegebenenfalls anhand einer aktuellen funktionierenden Retail-TOC aktualisiert werden.

## Installation

1. Den Projektordner unter dem exakten Namen `RPWatcher` nach `World of Warcraft\_retail_\Interface\AddOns\` kopieren.
2. World of Warcraft vollständig starten oder neu starten.
3. RPWatcher in der Addon-Liste aktivieren.
4. Für reale Tests freundliche Nameplates in den WoW-Einstellungen aktivieren.
5. Total RP 3 nur für die optionalen RP-Funktionen aktivieren.

## Slash-Befehle

- `/rpw` – manuell gewünschte Fenstersichtbarkeit umschalten.
- `/rpwatcher` – identischer langer Alias.
- `/rpw test` – einen grünen, grauen und unbekannten Testeintrag erzeugen.
- `/rpw clear` – alle Laufzeit-Watcher, Testdaten, TRP3-Zuordnungen und RPWatcher-Cooldowns entfernen.
- `/rpw help` – alle Befehle anzeigen.
- `/rpw trp3` – kompakte Diagnose der TRP3-Verfügbarkeit und Watcher-Namenszahlen.
- `/rpw refresh` – RP-Namen echter Watcher kontrolliert aktualisieren.
- `/rpw options` – RPWatcher-Einstellungsseite öffnen.
- `/rpw lock` – Fenster sperren und Zustand speichern.
- `/rpw unlock` – Fenster entsperren und Zustand speichern.
- `/rpw reset` – Position, Größe, Skalierung, Transparenz und Sperrstatus zurücksetzen.

Unbekannte Argumente zeigen die Hilfe an.

## Manuelle Ingame-Testanleitung für Phase 4

### Migration und Grundeinstellungen

1. Mit den vorhandenen SavedVariables aus Version 0.3.0 einloggen.
2. Prüfen, dass RPWatcher ohne Lua- oder BugSack-Fehler lädt.
3. Prüfen, dass die bisherige Fensterposition und Sichtbarkeit erhalten sind.
4. `/rpw options` eingeben. Die Kategorie **RPWatcher** muss sich unter den AddOn-Einstellungen öffnen.
5. `/reload` ausführen und erneut kontrollieren, dass Position, Sichtbarkeit und alle neuen Werte erhalten bleiben.

### Verschieben, Größe, Sperre und Darstellung

1. `/rpw unlock` eingeben und das Fenster mit der linken Maustaste verschieben.
2. Den Griff unten rechts ziehen; Liste, Scrollbereich, Statuszeit und Profilbutton dürfen sich nicht überdecken.
3. `/reload` ausführen. Position und Größe müssen wiederhergestellt werden.
4. `/rpw lock` eingeben. Ziehen am Fenster und am nun verborgenen Resize-Griff darf Position beziehungsweise Größe nicht verändern.
5. Auf der Einstellungsseite die Skalierung nacheinander auf 0,80, 1,00 und 1,30 stellen. Die Änderung muss sofort wirken; die gespeicherte Position darf nicht verloren gehen.
6. Die Hintergrundtransparenz auf 50 und 100 Prozent stellen. Nur der dunkle Haupthintergrund soll sich wesentlich ändern; Texte müssen lesbar bleiben.
7. `/rpw reset` eingeben. Position, Größe, Skalierung, Transparenz und Sperre müssen auf Standard wechseln. Watcher, Sichtbarkeit, Auto-Ausblendung, Aufbewahrung und Profilbutton-Einstellung dürfen sich nicht ändern.

### Auto-Ausblendung und manuelle Sichtbarkeit

1. `/rpw clear` eingeben und Auto-Ausblendung deaktivieren. Ein manuell sichtbares Fenster muss leer sichtbar bleiben.
2. Auto-Ausblendung aktivieren. Das Fenster muss bei leerer Liste verschwinden, ohne die manuelle Sichtbarkeit umzuschalten.
3. `/rpw test` eingeben. Das Fenster muss erscheinen und drei Testeinträge anzeigen.
4. `/rpw clear` eingeben. Das Fenster muss wieder automatisch verschwinden.
5. `/rpw` so verwenden, dass das Fenster manuell verborgen ist. Danach `/rpw test` nur zur expliziten Testanzeige verwenden und anschließend das Fenster über den Schließen-Button schließen.
6. Einen echten Watcher erfassen lassen. Ein durch den Schließen-Button manuell verborgenes Fenster darf nicht automatisch aufgehen.
7. Fenster manuell sichtbar schalten, Auto-Ausblendung aktiv lassen und `/rpw clear` ausführen. Beim nächsten echten Watcher muss das nur automatisch verborgene Fenster erscheinen.
8. Auto-Ausblendung bei leerer Liste deaktivieren. Ist die manuelle Sichtbarkeit weiterhin aktiv, muss das Fenster sofort erscheinen.

### Aufbewahrung und Statuszähler

1. `/rpw test` eingeben. Die Statuszeile muss `Aktuell: 1 · Vorher: 1 · Unbekannt: 1` zeigen, sofern keine echten Watcher vorhanden sind.
2. `/rpw clear` eingeben. Alle drei Zähler müssen null anzeigen; bei Auto-Ausblendung darf das Fenster verschwinden.
3. Aufbewahrung auf 15 Sekunden stellen.
4. Einen echten grünen Watcher erzeugen lassen, dann dessen Target wechseln und schließlich die Nameplate verschwinden lassen.
5. Die Zähler müssen nacheinander Grün/Aktuell, Grau/Vorher und Unbekannt abbilden.
6. Der unbekannte Eintrag muss nach ungefähr 15 Sekunden verschwinden.
7. Aufbewahrung auf 300 Sekunden stellen und denselben Ablauf wiederholen. Der unbekannte Eintrag darf nach 15 Sekunden noch vorhanden sein.
8. Während ein unbekannter Eintrag existiert, auf 15 Sekunden wechseln. Ist sein Alter bereits größer, muss der vorhandene zentrale Scanner ihn beim nächsten Lauf entfernen.

### TRP3-Profilbutton und Regression

1. Total RP 3 aktivieren und einen echten Watcher mit RP-Profil erfassen. RP-Name und `[Profil]` müssen wie in Version 0.3.0 funktionieren.
2. **TRP3-Profilbutton anzeigen** deaktivieren. `[Profil]` muss sofort verschwinden; RP-Name und spätere TRP3-Aktualisierungen müssen weiter funktionieren.
3. Die Option wieder aktivieren. Der Button muss bei verfügbarem Total RP 3 zurückkehren.
4. Total RP 3 deaktivieren und neu laden. Mit aktivierter Profilbutton-Einstellung darf kein Button und kein Lua-Fehler entstehen.
5. Prüfen, dass Gegner, NPCs, der eigene Spieler und freundliche Spieler ohne früheren Target-Vorgang nicht erscheinen.
6. Grün → Grau → Grün, Neubeginn des grünen Zeitmessers, Nameplate-Verlust zu Unbekannt und GUID-Wiederkehr ohne Duplikat erneut prüfen.
7. `/rpw trp3`, `/rpw refresh`, `/rpw help`, `/rpwatcher` und einen unbekannten Slash-Unterbefehl testen.

## Bekannte Einschränkungen und Risiken

- Nur sichtbare Nameplate-Unit-Tokens können live auf ihr Target geprüft werden.
- Target-Wechsel unter 0,25 Sekunden können zwischen zwei Scans liegen.
- Ohne Nameplate bleibt der aktuelle Target-Status unbekannt.
- RP-Namen und Watcher gehen bei Reload, Logout oder Neustart verloren.
- Andere Spieler ohne kompatibles RP-Addon liefern möglicherweise kein Profil und damit keinen RP-Namen.
- Die Profilöffnung hängt vom lokal verifizierten TRP3-Export `TRP3_API.slash.openProfile` der Version 3.3.7 ab.
- Sehr lange Namen werden in schmalen Zeilen abgeschnitten; der vollständige Name bleibt im Tooltip sichtbar.
- Die installierte Retail-Version enthält keine lose Blizzard-UI-Quellkopie. Die Settings-Registrierung wurde anhand der im Client verfügbaren `Settings`-API und lokal funktionierender aktueller Retail-Addons verifiziert.
- Ein vollständiger Laufzeittest ist nur in World of Warcraft möglich.
