# Karies-Graf: Herr unter dem Kissen

**Historischer Prototyp.** Im regulären Run durch den [Umhang-Grafen](COUNT_CLOAK.md)
ersetzt. Die folgenden Aufnahmen und Messwerte dokumentieren den früheren Stand.

Roadmap-Schritt 4 ist als erster eigener Boss-Encounter umgesetzt. Der Graf in
Welle 5 verwendet dieselbe Ressourcen-ID wie bisher, aber einen eigenen Ablauf.
Prinz, König und Imperator behalten vorerst ihre bisherigen Attacken.

## Ablauf

1. Der Graf sucht in der Pause eine nahe, erreichbare Position. Er verfolgt
   Denti nicht während seiner Ankündigung.
2. Ein orange umrandetes Rechteck, ein fallendes Kissen und ein umlaufender
   Zeitindikator kündigen den Einschlag **1,25 s** vorher an. Pfeile zeigen
   gleichzeitig den anschließenden Weg der Stofffalte. Die markierte Position
   bleibt fest; sie verfolgt Denti nach Beginn nicht mehr.
3. Nach dem Einschlag liegen **0,55 s** bis zum Start der wandernden Falte.
   Sie läuft **360 Welteinheiten in 1,3 s** durch ihre bereits markierte Bahn.
   Denti weicht seitlich aus, statt um einen anstürmenden Boss kreisen zu müssen.
4. Ab der ersten Gesundheitsphase folgt ein zweiter, **0,7 s** versetzter
   Kissensturz. Seine Bahn liegt **250 Einheiten** neben der ersten. Bei
   **130 Einheiten** Bahnbreite bleiben dazwischen 120 Einheiten Abstand.
5. Danach gibt es **2,4 s** Erholung. Entzündung beschleunigt nur diese Pause,
   höchstens um Faktor 1,4. Vorwarnungen und Faltengeschwindigkeit werden nicht
   immer kürzer beziehungsweise schneller.

Die Angriffsausrichtung berücksichtigt die Bossposition: Der Graf steht entlang
der Angriffsbahn, statt gezielt den seitlichen Ausweichweg zu besetzen. Ein
Arena-Rand verschiebt die gesamte markierte Bahn nach innen. Die nahe Position
in der Pause berücksichtigt Randkontakt, statt den Boss auf Denti zu klemmen.
Die normalen Körper und Projektile weiterer Gegner bleiben selbstverständlich
Gefahren; ein freier Bereich der Bossmechanik garantiert keine leere Arena.

Schaden läuft über Dentis vorhandenen Trefferweg mit Härte, Schild, Zahnflutsch
und Trefferpause. Ein Dash macht weder Einschlag noch Falte unschädlich. Die
Falte verursacht 70 % des normalen Boss-Angriffsschadens. Jede einzelne Gefahr
trifft höchstens einmal, auch wenn Denti mehrere Frames darin steht.

Die vorhandenen Schmelzschutz-/Gesundheitsphasen bleiben erhalten. Sie brechen
eine laufende Kissenfolge ab und geben danach wieder eine vollständige neue
Vorwarnung. Der Graf schießt keine zusätzlichen generischen Phasenringe mehr;
Verstärkung ist auf zwei Gegner pro Gesundheitsphase reduziert. Zwei Grafen
reservieren ihre Folgen nacheinander, statt gleichzeitig sämtliche Bahnen mit
eigenen Kissen zu überdecken.

## Umsetzung und Save/Resume

- `PillowEncounterData` / `data/encounters/count_pillow.tres`: gemeinsame Werte.
- `PillowEncounter`: je Graf eine kleine Komponente für Ablauf, Treffer und
  Darstellung; keine zusätzliche globale Liste aktiver Boss-Gefahren.
- `HazardGeometry`: Rechteck-/Kreisprüfung und relative Streckenprüfung. Die
  Falte prüft auch lange Frames und Dashes; eine erst später aktivierte Gefahr
  trifft keine bereits verlassene Dashposition.
- Die Angriffszeit, gesperrte Position, Ausrichtung, Anzahl, Staffelung und
  bereits verbrauchte Treffer bleiben im Enemy-Snapshot erhalten.
- Alte Graf-Saves ohne Kissen-Zustand beginnen nach einer Pause mit einer
  vollständigen neuen Ankündigung. Ein alter Charge-Zustand wird nicht als
  unsichtbarer neuer Angriff fortgesetzt. Entzündung, Leben und Gesundheitsphase
  bleiben erhalten. Fehlerhafte neue Vektoren werden beim Laden abgewiesen.
- Tod und Entfernen des Grafen entfernen seine Gefahren. Pause hält den Ablauf
  und die Animation an. Bossabschluss, Beutesammlung und Relikt/Shop-Fluss bleiben
  beim bestehenden Run-Koordinator.

## Darstellung

Die neue Graf-Silhouette trägt einen gepolsterten Umhang mit Zahnfee-Münzen und
einem kleinen Grafenreif. Kissen und Stofffalte sind ebenfalls generierte,
transparent gemalte Grafiken. Sie werden nur proportional skaliert und gedreht.
Der Atlas wird über getrennte vollständige Regionen gelesen; keine angrenzenden
Motive ragen in die andere Animation. Die alten Originalbilder bleiben erhalten.

- [Graf](../assets/enemies/cavity_count_pillow.png)
- [Kissen-/Faltenatlas](../assets/enemies/count_pillow_atlas.png)
- [Desktop-Aufnahme](screenshots/count_pillow/desktop.png)
- [Mobile Aufnahme](screenshots/count_pillow/mobile.png)
- [Native Animation](screenshots/count_pillow/attack.gif)

`tools/preview_pillow_boss.gd -- --animate` erzeugt native Aufnahmen unter
`.godot/pillow_preview/`. Die Animation ist eine arrangierte Demonstration des
Seitwärts-Ausweichens, kein aufgezeichneter menschlicher Spieltest.

## Messung und Grenzen

`tools/measure_pillow_boss.gd` vergleicht den alten gemeinsamen Ablauf mit dem
Kissen-Grafen unter gleichen Ausgangswerten: isolierte Welle 5 auf Normal,
120 Roh-DPS innerhalb der Reichweite, keine Items, keine Verstärkung und kein
Dash, 60 feste Schritte/s. Die Bewegung ist entweder stationär oder eine
einfache, skriptgesteuerte Reaktion mit Grundtempo. Das misst Erreichbarkeit und
Trefferdruck; es ersetzt weder einen kompletten Run noch einen menschlichen
Spieltest. [Rohdaten](count_pillow_measurements.json).

| Ablauf / Testbewegung | Nahkampf-TTK | Fernkampf-TTK | Erlittener Schaden Nah / Fern |
| --- | ---: | ---: | ---: |
| Alter Ablauf, stationär | 24,13 s | 18,80 s | 525,0 / 479,6 |
| Alter Ablauf, Warnungen lesen | 22,97 s | 18,80 s | 40,2 / 318,7 |
| Kissen-Graf, stationär | 19,73 s | 18,80 s | 151,8 / 151,8 |
| Kissen-Graf, Warnungen lesen | 28,90 s | 18,80 s | 0,0 / 23,6 |

Die Nahkampf-Angriffszeit sinkt beim bewussten Ausweichen auf rund 65 %; freie
Positionen und Angriffsfenster verändern den Kampf also tatsächlich. Fernkampf
mit dauerhafter Reichweite liegt mit knapp 19 Sekunden am unteren Rand des
Roadmap-Ziels. Der neue isolierte Boss verursacht insgesamt weniger Schaden
als die alte Charge-/Projektilkombination; die normalen Wellengegner fehlen in
diesem Vergleich. Daraus folgt ausdrücklich noch keine Abnahme der gesamten
Welle oder aller Schwierigkeiten. Tests mit menschlicher Touch-Steuerung,
kompletten Builds, voller Welle und Web-Performance bleiben offen.

`tests/pillow_encounter.gd` prüft Ankündigungen, Ortsbindung, Treffer im Dash,
relative Streckenprüfungen, Einmaltreffer/Schild, zweite Bahn, Ecken, Grundtempo,
Pause, Angriffsabschnitte beim Fortsetzen, Alt-Saves, Doppel-Graf und Tod. Die
bestehenden Boss-/Wellen-/Statusprüfungen decken weiter Schutz, Entzündung,
Abschluss und die übrigen Bossangriffe ab.

Der vollständige Lauf am 20.10.2026 bestand mit **120/120 Tests** in 111,16 s
(`.godot/test_runs/20261020-192902-1d34e520`). Der Editor-Import ist fehlerfrei.
Native Warn-/Aktivansichten wurden bei 1280×720, 320×568 und 568×320 geprüft.

## Generierung

Erstellt mit dem integrierten **Imagegen-Werkzeug**, transparenter Hintergrund
aktiviert. Referenz für beide Aufträge: `assets/enemies/cavity_count.png`, jeweils
als Stil-/Charakterreferenz, nicht als zu überschreibendes Original.

### Prompt: Graf

```text
Use case: stylized-concept. Asset type: one transparent 2D game enemy sprite for Denti. Reference image is the existing Karies-Graf, STYLE AND CHARACTER REFERENCE ONLY; preserve the evil cartoon decayed molar face, ivory enamel, caramel-brown cavities, glowing orange eyes, two short tooth roots, chunky warm dark outline and glossy painted cartoon style. Redesign this COUNT as the lord UNDER THE PILLOW, distinctly less royal than a king: modest small golden coronet, a large plush dusty-plum and ivory pillow-cloak wrapped over the shoulders with visible soft stuffed corners and broad folds, a few tooth-fairy gold coins sewn on the cloak. Compact readable silhouette, no staff or weapon, the pillow cloak is the main identifying feature. Frontal three-quarter view suitable for a top-down arena sprite, full body visible, centered on square with transparent margins. Large simple painted shapes readable at 110 pixels, no tiny details, no floating rubble, no background, no text or watermark. Genuinely transparent alpha background. Do not edit or reproduce the input file; produce a new sibling sprite.
```

### Prompt: Kissen und Falte

```text
Use case: stylized-concept. Asset type: transparent two-cell vertical game VFX atlas for Denti's pillow boss attack. Match the reference enemy's glossy hand-painted playful cartoon finish, warm dark-brown outlines, rich soft highlights. EXACT layout: square canvas divided into TWO EQUAL HORIZONTAL CELLS, top half and bottom half, with fully transparent gutters and margins so nothing touches the cell boundaries. TOP CELL: one soft ivory square pillow seen nearly from above, light lavender/plum piping and four stuffed corners, a slight central cloth depression, subtle broad folds, no face, no symbols. It occupies no more than 70 percent of the top cell width and 80 percent height. BOTTOM CELL: ONE wide short horizontal rolling cloth fold / stuffed fabric ridge, ivory fabric with plum underside and clear rounded curled edge, roughly four times wider than tall, occupying 80 percent of bottom cell width, centered well inside that cell. This ridge will move as an arena hazard. Simple bold shapes readable at 120 px width. No text, no numbers, no panels, no arrows, no particles, no shadow backdrop; genuinely transparent alpha background outside the two objects. Image is a small game asset atlas, not a mockup.
```
