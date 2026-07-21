# Screenshotplan für RPWatcher 0.9.0

## Allgemeine Regeln

- Screenshots ausschließlich im aktuellen WoW-Retail-Client aufnehmen.
- Möglichst ein einheitliches UI-Scale- und Fensterlayout verwenden.
- Chat, BattleTags, Real IDs, Gildennachrichten und andere private UI-Elemente ausblenden oder zuschneiden.
- Reale Charakternamen nur mit Zustimmung zeigen; andernfalls Testdaten verwenden oder Namen nachträglich anonymisieren.
- Keine vollständigen privaten RP-Profile abbilden.

## 1. Leeres Hauptfenster

- **Motiv:** Das visuell überarbeitete RPWatcher-Fenster im Leerzustand.
- **Erforderlicher Zustand:** `/rpw clear`, Auto-Ausblendung deaktiviert, Fenster sichtbar und entsperrt oder sauber gesperrt.
- **Sichtbar:** Titelleiste, Nullzähler, leerer Hinweis und Hilfetext, Rahmen und Resize-Griff beziehungsweise Sperrindikator.
- **Anonymisierung:** Chat und andere Spielerdaten ausblenden; im RPWatcher-Fenster sind keine Namen vorhanden.
- **Kurztitel:** `Bereit für Watcher`
- **DE-Beschreibung:** `Das kompakte RPWatcher-Hauptfenster im leeren Ausgangszustand.`
- **EN-Beschreibung:** `The compact RPWatcher main window in its empty ready state.`

## 2. Grün-, Grau- und Unbekannt-Status

- **Motiv:** Alle drei Statusarten gleichzeitig.
- **Erforderlicher Zustand:** `/rpw test` oder kontrollierte Testcharaktere.
- **Sichtbar:** Statusübersicht, grüner aktueller Eintrag, grauer früherer Eintrag, unbekannter Eintrag mit Fragezeichen und laufenden Zeiten.
- **Anonymisierung:** Bevorzugt die eindeutig markierten `[Test]`-Namen verwenden; reale Namen anonymisieren.
- **Kurztitel:** `Drei klare Zustände`
- **DE-Beschreibung:** `Aktuell, vorher und unbekannt bleiben durch Farbe, Symbol und Text unterscheidbar.`
- **EN-Beschreibung:** `Current, previous, and unknown remain distinguishable by color, symbol, and text.`

## 3. Echter RP-Name und Profilbutton

- **Motiv:** Ein echter Watcher mit Total-RP-3-RP-Namen und sichtbarem Profilbutton.
- **Erforderlicher Zustand:** Total RP 3 aktiv, Zustimmung des dargestellten Spielers, bekannter RP-Name.
- **Sichtbar:** RP-Name, Statuszeit, Button `Profil`; optional der Namenstooltip mit normalem WoW-Namen.
- **Anonymisierung:** Nur mit Zustimmung unverändert zeigen. Sonst einen speziell dafür erstellten Testcharakter nutzen; kein vollständiges Profilfenster mit privaten Texten aufnehmen.
- **Kurztitel:** `Optionale TRP3-Integration`
- **DE-Beschreibung:** `Bekannte RP-Namen und die lokale Profilöffnung ergänzen die Watcherliste.`
- **EN-Beschreibung:** `Known roleplay names and local profile access enhance the watcher list.`

## 4. Einstellungsseite

- **Motiv:** RPWatcher-Kategorie in den WoW-Addon-Einstellungen.
- **Erforderlicher Zustand:** `/rpw options`.
- **Sichtbar:** Gruppen Fenster, Verhalten und Total RP 3 sowie alle Regler, Checkboxen und Reset-Button.
- **Anonymisierung:** Andere Addonlisten oder Accountinformationen bei Bedarf zuschneiden.
- **Kurztitel:** `Anpassbare Darstellung`
- **DE-Beschreibung:** `Fenstergröße, Skalierung, Transparenz und Verhalten lassen sich direkt konfigurieren.`
- **EN-Beschreibung:** `Window size, scale, opacity, and behavior can be configured directly.`

## 5. Großes RP-Ereignis

- **Motiv:** RPWatcher im realen Einsatz an einem stark besuchten RP-Ort.
- **Erforderlicher Zustand:** Viele freundliche Nameplates, mehrere freiwillige Watcher, stabiles getestetes UI.
- **Sichtbar:** Spielwelt mit Nameplates und RPWatcher-Liste mit mehreren Zuständen; keine Diagnoseflut im Chat.
- **Anonymisierung:** Reale Namen, Chat, Gilden- und Profilinformationen konsequent anonymisieren oder Zustimmung aller klar identifizierbaren Personen einholen.
- **Kurztitel:** `Übersicht auch bei Großereignissen`
- **DE-Beschreibung:** `Die virtualisierte Liste bleibt auch an belebten RP-Orten kompakt und übersichtlich.`
- **EN-Beschreibung:** `The virtualized list remains compact and readable at busy roleplay events.`
