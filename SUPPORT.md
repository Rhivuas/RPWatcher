# RPWatcher-Support und Fehlerberichte

Vielen Dank für einen möglichst reproduzierbaren Bericht. RPWatcher 0.9.0 ist ein Release Candidate; Rückmeldungen zu Regressionen, Interface-Kompatibilität und Großereignissen sind besonders hilfreich.

## Erforderliche Angaben

- RPWatcher-Version
- World-of-Warcraft-Retail-Version und Interface-Build
- Total-RP-3-Version oder Angabe „deaktiviert/nicht installiert“
- genaue Reproduktionsschritte
- erwartetes Verhalten
- tatsächliches Verhalten
- relevante BugSack- beziehungsweise Lua-Fehlerausgabe
- Ausgabe von `/rpw plates`, wenn Nameplates oder Kandidaten betroffen sind
- Ausgabe von `/rpw perf report`, wenn Performance betroffen ist
- andere aktive Nameplate-, Unitframe- oder UI-Addons

## Empfohlener Ablauf

1. `/rpw clear` ausführen.
2. `/reload` ausführen.
3. Fehler erneut reproduzieren.
4. BugSack-Ausgabe vollständig, aber ohne private Chat- oder Profildaten kopieren.
5. Bei Nameplate-Problemen `/rpw plates` direkt am betroffenen Ort ausführen.
6. Bei Performanceproblemen `/rpw perf on`, mindestens zwei bis fünf Minuten messen und `/rpw perf report` ausführen.
7. Wenn möglich angeben, ob der Fehler ohne Total RP 3 weiterhin auftritt.

## Nicht übermitteln

Bitte keine folgenden Daten veröffentlichen oder als Pflichtangabe aufnehmen:

- Battle.net- oder WoW-Accountdaten
- Passwörter oder Zugangsdaten
- Spieler-GUIDs
- vollständige RP-Profile oder Profiltexte
- private Chatverläufe
- API-Schlüssel oder Tokens

Charakternamen können anonymisiert werden. Die RPWatcher-Diagnosebefehle geben keine vollständigen internen Tabellen, Namen oder GUIDs aus.

## Performanceberichte

Hilfreich sind Berichte aus:

- einem ruhigen Ort mit wenigen Nameplates,
- einem stark besuchten RP-Ort,
- einem Großereignis bei sichtbarem Fenster,
- derselben Situation bei verborgenem Fenster,
- `/rpw stress 200` mit schnellem Scrollen.

Bitte Messdauer, ungefähre sichtbare Nameplate-Anzahl, Fensterzustand und beobachtete Ruckler dazuschreiben.
