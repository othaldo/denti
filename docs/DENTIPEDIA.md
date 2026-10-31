# Dentipedia

Stand: 31.10.2026. Das Nachschlagewerk ist im Hauptmenü und über Escape
erreichbar. Ein pausierter Kampf bleibt beim Lesen pausiert. Die Suche filtert
Titel und Text innerhalb des gewählten Bereichs.

Die Dentipedia nutzt die rahmenlose gemeinsame Menüfläche. Alle sechs Bereiche
sind direkt als Reiter sichtbar; ein Kategorie-Dropdown entfällt. Suche und
Auswahl bleiben auf einer gemeinsamen Flucht. Auswahlzustand, Hover und
Tastaturfokus sind getrennt erkennbar. Items behalten ihre Seltenheitskante.
Waffendetails zeigen größere Bilder und eine kompakte Mk-Tabelle aus denselben
Ressourcen wie bisher; „Basiswerte“ kennzeichnet den Vergleich ohne Build.

![Rahmenlose Dentipedia mit sichtbaren Kategorien](screenshots/dentipedia_update/weapons_1280x720.png)

- **Waffen:** 18 Standardwaffen mit Spielweise, Skalierung, Effekten und
  Basiswerten Mk I–IV; entdeckte Spezialwaffen ergänzen die Liste.
- **Items:** Effekte, Stapel- und Familienlimits aus den aktuellen Ressourcen.
- **Relikte:** alle fünf Relikte mit ihren Effekten.
- **Werte:** dieselben Attribute, Namen und Icons wie in HUD und Shop.
- **Mechaniken:** 26 Themen zu aktuellen Systemen und ihrem Zusammenspiel.
- **Verzauberungen:** Übersicht und Einzeleinträge aller Elemente und
  Verstärkungen, einschließlich ausdrücklich markiertem Altbestand.

## Aktuelle Regeln

Die Texte unterscheiden Waffenpunkte, Effektränge, Mk-Stufen und Wurzeln.
Neue Kapseln geben zwei Punkte; jeder Rang kostet einen Punkt pro belegter
Wurzel der Zielwaffe. Mk öffnet bis zu vier Plätze, jeder Effekt reicht bis 10/10, und pro Waffe ist ein Element wählbar.
Reichweite, Tempo, Lebensraub, Krit-Chance, Krit-Schaden und Wucht ergänzen es.

Die manuelle Verzauberungsfusion erklärt Auswahl, Zusammenlegen und vollständige
Punkteerstattung. Bei unveränderten Wurzelkosten ergeben Feuer 7/10 plus 6/10 maximal 10/10; die übrigen drei Ränge werden mit ihren Wurzelkosten erstattet. Wechselnde Wurzelkosten rechnen das investierte Budget in bezahlbare Ränge um.
Konflikte blockieren die Fusion nicht pauschal. Neue Punkte erzeugen keine
zufälligen Effekt-Seltenheiten, Slotfunde oder Mk-Aufstiege; alte gespeicherte
Angebote werden im eigenen Altbestand-Thema erklärt.

![Manuelle Verzauberungsfusion](screenshots/dentipedia_update/fusion_1280x720.png)

Weitere Themen behandeln Dash und festen Ausdauerregen, den erhöhten
Körperkontaktschaden beim Dash, Lebensraub, Elementformen und Einschläge,
die ein- und zweifädigen Zahnseidenwaffen, Goldzahn-Gauner, Waffenrollen,
Shopwerte, Belohnungsfolge, Gegner, Boss-Entzündung, Schwierigkeit, Story,
Endlos und Fortsetzen. Kurze kosmetische Elementspuren sind von schädlichen
Item-Bodenwirkungen getrennt.

Dashkosten, Cooldown, Regeneration und Kontaktmultiplikator stammen direkt
aus PlayerDash.DEFAULT. Lebensraub liest das Intervall je Waffenexemplar und die Obergrenze aus seiner
Affix-Ressource; Gauner und Aufstiegswahl verwenden ebenfalls ihre aktuellen
Spieldaten. Waffen-, Item-, Relikt- und Werteeinträge bleiben katalogbasiert.

## Waffenformen und Bedienung

Ein Waffeneintrag zeigt Normal, Feuer, Eis, Gift, Elektro, Blutung und Wasser
über die bestehenden Elementsymbole. Die Ansicht wechselt nur das Bild und
den Formzusatz; Basiswerte, Ausrüstung und Verzauberungen bleiben unverändert.
Die Formbilder werden über den vorhandenen Skin-Cache geladen.

[Desktop-Formvorschau](screenshots/dentipedia_update/weapon_forms_1280x720.png),
[Hochformat](screenshots/dentipedia_update/weapon_forms_360x640.png).

Die Suche findet die Zahnseiden-Schneide auch unter ihrem früheren Namen
Garotte. Beim Öffnen eines anderen Eintrags beginnt dessen Text wieder oben.
Am Desktop stehen Liste und Details nebeneinander. Im schmalen Hochformat
nimmt die Liste zunächst die ganze Inhaltsfläche ein. Antippen öffnet den
Eintrag; der Zurück-Pfeil oder Escape führt zuerst zur Liste und anschließend
zum Menü. Kategorie, Suchtext und Listenposition bleiben beim Zurückgehen
erhalten. Die Kategorien bleiben sichtbar; auf kleinen Flächen heißt der
Verzauberungsreiter kurz „Effekte“. Formbuttons umbrechen innerhalb der
Details und behalten mindestens 48 × 48 Touchfläche. Kurzes Querformat behält
die beiden Spalten.

Unentdeckte Spezialwaffen zeigen nur ihre schwarze Alpha-Silhouette.
Namen, Zutaten, Effekte, Werte und Formvorschau bleiben verborgen, bis die
erste Evolution bestätigt wurde. Der dauerhafte Fortschritt bleibt über Runs,
Verkäufe und Neustarts erhalten. Familienzutaten akzeptieren jede Seltenheit.

## Prüfung

tests/dentipedia.gd prüft sichtbare Kategorien ohne Dropdown, Touchgrößen,
rahmenlose Menüintegration, Hochformat-Navigation und Pause sowie Kataloge,
neue Themen, Schriftzeichen, echte
Freischaltung, Spoilerschutz, Suche, alle sieben Formbuttons, unveränderte
Waffenvorlagen, Scrollpositionen und vier Bildschirmgrößen. Menü- und
Belohnungsansichten werden zusätzlich durch ihre bestehenden Tests geprüft.

tools/preview_dentipedia.gd erzeugt native Ansichten für Waffen-/Itemübersicht,
Fusion, Dash, Waffenpunkte, Feuerform und Lebensraub in 1280×720, 320×568,
360×640 und 568×320.
Die Aufnahmen liegen unter docs/screenshots/dentipedia_update/; das Werkzeug
verwendet getrennte Sitzungsdateien.

Glück: einmalige Bonuskapsel nach dem Loot-Sweep (10 % bei 100 Glück, maximal 25 %). Runenpolitur: jede fünfte seit dem Erwerb gesammelte Kapsel erzeugt einen Bonus, ohne Rekursion. Beide Regeln und die einmalige Umrechnung alter Restpunkte sind ingame dokumentiert.

Das Mechanikthema Waffenmeisterschaften erklärt die Regeln und verweist auf das
eigene Menü **Achievements**. Persönliche Fortschrittsstände werden dort angezeigt;
die Dentipedia bleibt das Nachschlagewerk für Mechaniken.
