# RPWatcher 0.4.0 – Hotpath-Audit vor Phase 5

Dieses Dokument beschreibt den getesteten Stand `v0.4.0` vor den operativen Änderungen. Es dient als Vergleichsbasis für Phase 5.

## Dauerhafter Scanner

`Scanner:Scan()` läuft über genau einen `C_Timer.NewTicker` alle 0,25 Sekunden. Für jeden Eintrag in `visibleUnits` führte der schnelle Pfad bisher folgende WoW-Unit-APIs aus:

1. `UnitExists(unitToken)`
2. `UnitIsPlayer(unitToken)`
3. `UnitIsFriend("player", unitToken)`
4. `UnitIsUnit(unitToken, "player")`
5. `UnitGUID(unitToken)`
6. `UnitExists(unitToken .. "target")`
7. `UnitIsUnit(unitToken .. "target", "player")`, sofern das Target existiert
8. `GetUnitName(unitToken, true)` für bereits erfasste Watcher

Damit wurden Spieler-, Freund-, Selbst- und Namensprüfung viermal pro Sekunde wiederholt, obwohl diese Eigenschaften normalerweise nur beim Hinzufügen beziehungsweise bei einem seltenen Integritätsabgleich benötigt werden. GUID und Target bleiben dagegen dynamisch: Die GUID muss Token-Wiederverwendung erkennen; der Target-Token muss bei jedem schnellen Scan geprüft werden.

## Tabellen und Allokationen

- `staleUnitTokens`, `expiredGUIDs` und `sortedWatchers` wurden bereits wiederverwendet und gezielt geleert.
- Im Lua-Code wurde keine neue Hilfstabelle pro normalem Scan oder Kandidat erzeugt.
- `unitToken .. "target"` erzeugte jedoch bei jedem Kandidaten und Scan erneut einen String.
- `C_NamePlate.GetNamePlates()` liefert beim Initialisieren beziehungsweise Betreten der Welt eine API-seitig erzeugte Liste.
- Die sortierte Watcherliste wurde nur bei `sortedListDirty` neu aufgebaut und sortiert.

## Dirty-Flags und UI-Aktualisierung

Die Sortierliste wurde bei Erzeugung, Entfernung, Statuswechsel, Namensänderung, RP-Namensänderung sowie Testdatenänderungen ungültig. Reine Aktualisierungen von `lastTargetConfirmedAt` oder `lastVisibleAt` lösten keine Sortierung aus.

Bei jeder Datenänderung rief der Scanner den UI-Callback auf. `UI:RefreshWatcherList()` sortierte bei Bedarf und formatierte anschließend jede Watcherzeile vollständig. Für 100 beziehungsweise 200 Watcher entstanden 100 beziehungsweise 200 Zeilenframes. Der Pool wurde wiederverwendet, konnte aber bis zur höchsten jemals gleichzeitig angezeigten Watcherzahl wachsen.

Bei verborgenem Fenster lief die Target-Erkennung korrekt weiter. Vollständige Datenaktualisierungen und Zeilenformatierung fanden trotzdem statt. Ausschließlich zeitbedingte Aktualisierungen wurden bei verborgenem Fenster bereits übersprungen und beim Anzeigen nachgezogen.

## Zonenwechsel und Token-Bereinigung

- `PLAYER_ENTERING_WORLD` las vorhandene Nameplates über `C_NamePlate.GetNamePlates()` ein.
- Ein ausdrückliches Bereinigen temporärer Tokens bei `PLAYER_LEAVING_WORLD` fehlte.
- Wiederholtes `PLAYER_ENTERING_WORLD` ergänzte die vorhandenen Zuordnungen, statt einen vollständigen Abgleich mit den tatsächlich sichtbaren Nameplates durchzuführen.
- `NAME_PLATE_UNIT_REMOVED` verwendete korrekt die zuvor gespeicherte Token-zu-GUID-Zuordnung und war nicht von einem nachträglichen `UnitGUID(unitToken)` abhängig.

## TRP3-Anfragen

RPWatcher besaß einen 30-Sekunden-Cooldown pro GUID, rief `TRP3_API.r.sendQuery` für neue Watcher jedoch unmittelbar auf. Total RP 3 3.3.7 besitzt in `NamePlates_RequestQueue.lua` eine Slot-Queue für seine eigene Nameplate-Funktion, der öffentliche direkte Export `sendQuery` führt aber nur seine eigene Ziel-ID-Prüfung und einen per-Ziel-Cooldown durch. Viele neue RPWatcher-GUIDs konnten daher in kurzer Folge direkte Aufrufe auslösen.

## Begründete Phase-5-Maßnahmen

- Statische Kandidateneigenschaften und vollständigen Namen beim Nameplate-Add prüfen und zwischenspeichern.
- Im schnellen Scan nur GUID-Integrität und Target prüfen; statische Eigenschaften selten innerhalb desselben Ticketers abgleichen.
- Temporäre Token-Zuordnungen beim Verlassen der Welt leeren und beim Betreten vollständig mit vorhandenen Nameplates abgleichen.
- Target-Token pro Kandidat zwischenspeichern.
- UI-Zeilen auf den sichtbaren Ausschnitt virtualisieren und verborgene Listen erst beim Anzeigen formatieren.
- Direkte RPWatcher-Profilanfragen mit höchstens einer Anfrage pro Sekunde über den bestehenden Scanner abarbeiten.
- Diagnose standardmäßig deaktiviert halten; im deaktivierten Scannerpfad bleibt nur eine boolesche Abfrage pro Tick.

## Korrektur 5.1: Nameplate-Tokenauflösung

Der erste Phase-5-Stand las Frames aus `C_NamePlate.GetNamePlates()` ausschließlich über `nameplate.namePlateUnitToken`. In einem reproduzierten Lauf waren aus Benutzersicht mindestens 14 freundliche Spieler-Nameplates sichtbar; nach 2 Minuten 33 Sekunden meldete die Diagnose jedoch nur einen verwalteten Token, einen Kandidaten und 77 Kandidatenprüfungen bei 587 Scans. Die leere Watcherliste war ohne beobachtenden Spieler möglich, die geringe Kandidatenmenge dagegen nicht plausibel.

Ursache war der Fünf-Sekunden-Integritätsabgleich: Frames ohne gültiges `namePlateUnitToken` wurden nicht in `seenNameplateTokens` eingetragen. Dadurch entfernte der Abgleich zuvor über `NAME_PLATE_UNIT_ADDED` korrekt erfasste Tokens als vermeintlich verschwunden.

Die lokale Prüfung erfolgte gegen den installierten Retail-Client `12.0.7.68453` mit Interface `120007`. Die Blizzard-UI liegt dort nicht als lose Quellkopie vor; die aktuelle `GetUnit`-Methode ist im Client vorhanden und wird deshalb zusätzlich für jedes konkrete Frame auf Existenz geprüft und gezielt geschützt aufgerufen.

Die Auflösung ist nun zentral gekapselt. Aktuelle Blizzard-Nameplate-Frames werden zuerst defensiv über `nameplate:GetUnit()` ausgewertet; `namePlateUnitToken` bleibt ausschließlich als älterer Fallback. Das unbestätigte Feld `unitToken` wird nicht verwendet. Initialisierung, `PLAYER_ENTERING_WORLD` und der seltene Integritätsabgleich verwenden dieselbe Funktion. Ereignisse verwenden weiterhin direkt ihren gelieferten Unit-Token.

Der Performancebericht bezeichnet `visibleNameplateTokens` nicht mehr pauschal als „Nameplates“. Eine nur beim ausdrücklichen Bericht erzeugte Momentaufnahme trennt rohe API-Frames, aufgelöste Tokens, verwaltete Tokens, freundliche Kandidaten sowie echte und synthetische Watcher. `/rpw plates` ergänzt dazu Tokenwege und Ablehnungsgründe, ohne Scannerzustand, Target-Status, TRP3 oder SavedVariables zu verändern.
