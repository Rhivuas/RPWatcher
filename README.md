# RPWatcher

RPWatcher ist ein World-of-Warcraft-Retail-Addon. Es erkennt freundliche Spieler mit sichtbarer Nameplate und zeigt an, ob diese den eigenen Spielercharakter aktuell oder zuvor im Target hatten. Optional zeigt es bekannte RP-Namen aus Total RP 3 an und öffnet deren Profile.

## Entwicklungsstand

Version 0.5.0 implementiert Phase 5 zur operativen Härtung für stark besuchte RP-Orte und Großereignisse. Die getesteten Status-, Fenster-, Settings- und TRP3-Funktionen bleiben erhalten. Der zentrale Target-Scanner läuft weiterhin alle 0,25 Sekunden; es gibt weder einen zweiten dauerhaften RPWatcher-Ticker noch eine `OnUpdate`-Schleife.

Ein Spieler erscheint erst, nachdem er den eigenen Charakter mindestens einmal im Target hatte. Berücksichtigt werden ausschließlich gültige Nameplate-Unit-Tokens freundlicher Spielercharaktere ungleich dem eigenen Spieler.

Watcher, RP-Namen, Profilinformationen und TRP3-Abfragezustände sind reine Laufzeitdaten. `RPWatcherDB` speichert ausschließlich Addon-, Fenster- und Anzeigeeinstellungen.

## Optimierte Scannerarchitektur

Beim Ereignis `NAME_PLATE_UNIT_ADDED` prüft RPWatcher einmalig gültige Unit, Spielerstatus, Freundlichkeit, Selbstausschluss, GUID und vollständigen WoW-Namen. Nur gültige freundliche Spieler werden in die schnelle Kandidatenliste aufgenommen. Der 0,25-Sekunden-Pfad prüft anschließend nur noch:

- ob der Unit-Token weiterhin dieselbe GUID besitzt,
- ob dessen zwischengespeicherter Target-Token den Spieler bezeichnet.

Der Target-Token wird nicht bei jedem Scan neu zusammengesetzt. Alle fünf Sekunden gleicht derselbe bestehende Ticker die aktuellen Frames aus `C_NamePlate.GetNamePlates()` vollständig ab. Dadurch werden verpasste Ereignisse, geänderte statische Eigenschaften und wiederverwendete Tokens korrigiert, ohne einen weiteren Timer anzulegen. Die Entfernung unbekannter Watcher wird innerhalb desselben Ticketers einmal pro Sekunde geprüft.

Die Tokenauflösung für diese Frames ist zentral gekapselt. Sie verwendet zuerst die aktuelle Nameplate-Frame-Methode `GetUnit()` und greift nur defensiv auf das ältere Feld `namePlateUnitToken` zurück. Das unbestätigte Feld `unitToken` wird nicht verwendet. Der ursprüngliche Phase-5-Abgleich las ausschließlich `namePlateUnitToken`; lieferte dieses Feld keinen Token, entfernte der nächste Fünf-Sekunden-Abgleich zuvor korrekt per Ereignis erfasste Kandidaten fälschlich wieder. Der reproduzierte Bericht mit mindestens 14 sichtbaren freundlichen Nameplates, aber nur einem verwalteten Token und 77 Kandidatenprüfungen in 587 Scans war die Folge dieses Fehlers.

`PLAYER_LEAVING_WORLD` entfernt temporäre Nameplate- und GUID-Zuordnungen und setzt betroffene echte Watcher auf Unbekannt, ohne ihre Laufzeithistorie sofort zu löschen. `PLAYER_ENTERING_WORLD` liest vorhandene Nameplates erneut ein. Der Hotpath vor Phase 5 und die technischen Gründe sind in `PERFORMANCE_AUDIT.md` dokumentiert.

## Performance-Diagnose

Die Diagnose ist standardmäßig ausgeschaltet und wird niemals gespeichert. Im ausgeschalteten Scannerpfad entsteht nur eine boolesche Abfrage pro Tick; `debugprofilestop()` wird ausschließlich bei aktivierter Messung aufgerufen.

```text
/rpw perf
/rpw perf on
/rpw perf off
/rpw perf reset
/rpw perf report
```

Erfasst werden Scananzahl, gesamte, durchschnittliche und maximale Scanzeit, geprüfte Kandidaten, echte und synthetische Watcher, Statuswechsel, erzeugte und entfernte echte Watcher, UI-Daten- und Zeitaktualisierungen sowie versendete und gedrosselte TRP3-Anfragen. Beim ausdrücklichen Bericht wird zusätzlich eine aktuelle, nicht gespeicherte Momentaufnahme erstellt. Sie unterscheidet rohe Frames aus `C_NamePlate.GetNamePlates()`, Frames mit auflösbarem Token, intern verwaltete sichtbare Tokens und qualifizierte freundliche Kandidaten. `/rpw perf on` beginnt immer mit leeren Messwerten; `/rpw perf off` behält den letzten Bericht im Arbeitsspeicher.

`/rpw plates` gibt dieselben Nameplate-Grundmengen detaillierter aus, einschließlich Tokenweg und Ablehnungsgründen. Der Befehl liest ausschließlich den momentanen API- und Scannerzustand: Er erzeugt weder Watcher noch Kandidaten, verändert keinen Target-Status, sendet keine TRP3-Anfrage und speichert nichts. Kandidaten sind sichtbare, für den Target-Scan qualifizierte freundliche Spieler. Im Fenster sichtbare Watcher sind dagegen nur Kandidaten, die den Benutzer mindestens einmal im Target hatten; eine leere Watcherliste bei vielen Kandidaten kann deshalb korrekt sein.

## Synthetischer Belastungstest

`/rpw stress 25`, `50`, `100` oder `200` ersetzt ausschließlich zuvor erzeugte Stressdaten durch die gewünschte Menge. Die Einträge werden deterministisch auf Grün, Grau und Unbekannt verteilt. Sie verwenden reservierte interne Testschlüssel, keine Unit-Tokens und keine echten GUIDs. Sie lösen weder Unit- noch TRP3-Aufrufe aus, besitzen keinen Profilbutton und werden nicht gespeichert.

Unbekannte Stress-Einträge bleiben absichtlich bis zum nächsten Stress-Befehl oder Clear erhalten, damit auch längere UI-Tests mit einer kurzen realen Aufbewahrungszeit möglich sind. `/rpw stress clear` entfernt nur Stressdaten. Echte Watcher und die drei normalen `/rpw test`-Einträge bleiben unangetastet. `/rpw clear` entfernt weiterhin sämtliche Laufzeitdaten.

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

Da RPWatcher den öffentlichen Export `TRP3_API.r.sendQuery` direkt verwendet und damit nicht durch die interne TRP3-Nameplate-Slot-Queue läuft, puffert Phase 5 RPWatcher-Anfragen zusätzlich. Über den bestehenden Scanner wird höchstens eine Anfrage pro Sekunde versendet. Doppelte Queue-Einträge werden verhindert; entfernte Watcher werden vor dem Versand verworfen. `/rpw clear` leert auch die Warteschlange. Diese konservative Rate verhindert Anfragespitzen bei vielen neuen Watchern, ohne einzelne Profile merklich lange zu blockieren.

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
- `/rpw perf [on|off|reset|report]` – nicht persistente Laufzeitdiagnose steuern.
- `/rpw plates` – reine Momentaufnahme der Nameplate-Auflösung und Ablehnungsgründe ausgeben.
- `/rpw stress 25|50|100|200` – synthetische Lastdaten erzeugen.
- `/rpw stress clear` – ausschließlich synthetische Stressdaten entfernen.

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

## Manuelle Ingame-Testanleitung für Phase 5

### Baseline und Zonenwechsel

1. Mit aktiviertem RPWatcher 0.5.0 und BugSack einloggen und `/reload` ausführen.
2. Prüfen, dass Fensterposition, Größe, Sichtbarkeit, Auto-Ausblendung und Settings aus 0.4.0 erhalten sind.
3. Einen freundlichen Spieler über seine sichtbare Nameplate Grün, Grau und Unbekannt durchlaufen lassen.
4. Während eine Nameplate sichtbar ist einen Ladebildschirm beziehungsweise Zonenwechsel auslösen. Der Eintrag darf nicht als weiterhin sichtbarer Token behandelt werden und soll gegebenenfalls Unbekannt werden.
5. Nach `PLAYER_ENTERING_WORLD` müssen vorhandene Nameplates wieder erkannt werden; es dürfen keine Duplikate oder Lua-Fehler entstehen.
6. Mehrere Zonenwechsel und `/reload` wiederholen. Die Scanfrequenz darf sich nicht vervielfachen.

### Performance-Vergleich

1. Diagnose einschalten:

   ```text
   /rpw perf on
   ```

2. Fünf Minuten in einer ruhigen Umgebung mit wenigen Nameplates warten und anschließend ausgeben:

   ```text
   /rpw perf report
   ```

3. Erneut `/rpw perf on` ausführen, um die Messung zurückzusetzen, und mindestens fünf Minuten in Goldhain, Sturmwind oder einer vergleichbar vollen RP-Veranstaltung messen.
4. Währenddessen bewegen, Nameplates in Reichweite kommen und verschwinden lassen sowie mehrere Target-Wechsel beobachten.
5. Fenster zunächst sichtbar, anschließend ungefähr zwei Minuten manuell verborgen testen. Target-Erkennung muss weiterlaufen; ausschließlich zeitbedingte UI-Aktualisierungen sollen während des Verbergens kaum beziehungsweise nicht zunehmen.
6. Fenster wieder anzeigen. Alle sichtbaren Zeittexte müssen sofort stimmen.
7. Bericht ausgeben und Messung anhalten:

   ```text
   /rpw perf report
   /rpw perf off
   /rpw perf report
   ```

8. Prüfen, dass der zweite Bericht erhalten bleibt. `/reload` muss die Diagnose wieder ausgeschaltet und die Werte verworfen haben.

### Nameplate-Abgleich nach Korrektur 5.1

1. An einem Ort mit vielen sichtbaren freundlichen Spieler-Nameplates `/rpw plates` ausführen.
2. `Rohe Frames` muss ungefähr der tatsächlich sichtbaren Nameplate-Menge entsprechen. `Token aufgelöst` sollte im Normalfall gleich hoch sein; der Tokenweg sollte überwiegend oder vollständig `GetUnit()` melden.
3. `Verwaltete Tokens` muss den aufgelösten aktuellen Tokens entsprechen. `Verwaltete Kandidaten` darf wegen NPCs, Gegnern, dem eigenen Spieler oder fehlenden Unit-Daten kleiner sein.
4. Fünfzehn Sekunden warten, sodass mindestens drei Integritätsabgleiche stattgefunden haben, und `/rpw plates` erneut ausführen. Weiterhin sichtbare Kandidaten dürfen nicht verschwinden.
5. `/rpw perf on` starten, mindestens 30 Sekunden warten und `/rpw perf report` ausgeben. Bei beispielsweise 10 stabilen Kandidaten müssen ungefähr 40 Kandidatenprüfungen pro Sekunde anfallen; eine dauerhaft nur einstellige Kandidatenzahl trotz vieler freundlicher Spieler-Nameplates ist zu melden.
6. Eine Nameplate aus der Reichweite verschwinden lassen und nach mehr als fünf Sekunden `/rpw plates` ausführen. Der wirklich verschwundene Token darf nicht mehr verwaltet werden.
7. `/reload` mit bereits sichtbaren Nameplates ausführen. Direkt danach muss `/rpw plates` die vorhandenen Frames und Tokens wieder melden.
8. Einen freundlichen Spieler den Benutzer anwählen lassen. Erst dann darf aus dem Kandidaten ein sichtbarer grüner Watcher werden; ohne Target-Vorgang bleibt die Watcherliste leer.

### Synthetische UI-Last

1. Nacheinander ausführen:

   ```text
   /rpw stress 25
   /rpw stress 50
   /rpw stress 100
   /rpw stress 200
   ```

2. Bei jeder Größe Statuszähler, Scrollbereich, laufende Zeiten und flüssiges Verschieben beziehungsweise Skalieren prüfen.
3. Mit 200 Einträgen schnell durch die gesamte Liste scrollen. Zeilen dürfen weder leer hängen bleiben noch falsche Tooltips oder Profilbuttons zeigen.
4. Fenster schließen und wieder öffnen. Zeitwerte müssen nachgezogen werden.
5. Parallel einen echten Watcher erfassen. Er muss korrekt sortiert bleiben und darf nicht durch neue Stressdaten ersetzt werden.
6. Zusätzlich `/rpw test` ausführen. Danach nur Stressdaten entfernen:

   ```text
   /rpw stress clear
   ```

   Der echte Watcher und die drei normalen Testeinträge müssen bestehen bleiben.
7. Ungültige Eingaben wie `/rpw stress 0`, `/rpw stress 201` und `/rpw stress foo` müssen lediglich die Hilfe anzeigen.
8. `/rpw clear` muss anschließend echte Watcher, normale Testdaten, Stressdaten und ausstehende RPWatcher-TRP3-Anfragen entfernen.

### TRP3-Anfragedrosselung

1. Total RP 3 aktivieren, `/rpw perf on` eingeben und in kurzer Zeit mehrere echte neue Watcher erfassen.
2. Im Bericht darf die Zahl versendeter RPWatcher-Anfragen höchstens ungefähr um eine pro Sekunde steigen.
3. `/rpw refresh` mehrfach kurz hintereinander ausführen. Individueller 30-Sekunden-Cooldown und Queue-Duplikatschutz müssen greifen.
4. Einen Watcher löschen beziehungsweise `/rpw clear` ausführen, während Anfragen warten. Gelöschte Queue-Einträge dürfen nicht später versendet oder als Watcher wiederhergestellt werden.
5. Total RP 3 deaktiviert sowie nach RPWatcher geladen testen. Beide Fälle müssen ohne Lua-Fehler funktionieren.

### Zurückzumeldender Performance-Bericht

Bitte jeweils den vollständigen Chattext von `/rpw perf report` für folgende Situationen übermitteln:

- ruhiger Ort, Fenster sichtbar, Messdauer mindestens fünf Minuten;
- voller RP-Ort, Fenster sichtbar, Messdauer mindestens fünf Minuten;
- voller RP-Ort, Fenster verborgen, Messdauer mindestens zwei Minuten;
- `/rpw stress 200` mit mehrmaligem vollständigem Scrollen.

Zusätzlich hilfreich sind Ort, ungefähre sichtbare Nameplate-Anzahl, Messdauer, aktiviertes/deaktiviertes TRP3, beobachtete Ruckler und eventuelle BugSack-Meldungen. Es werden keine GUIDs oder Profile benötigt.

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
- Die seltene Integritätsprüfung kann alle fünf Sekunden einen kleinen, messbaren Ausschlag erzeugen; der Maximalwert im Performance-Bericht macht diesen sichtbar.
- Synthetische Stressdaten prüfen UI und Laufzeitlisten, simulieren aber keine echten Unit-API- oder Netzwerkbedingungen.
