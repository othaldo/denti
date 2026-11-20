# Grafikauftrag: Porträts und Talent-Symbole der vier neuen Klassen

Für Codex. Betrifft Zahnfee (`tooth_fairy`), Glutzahn (`ember`), Spültechniker
(`rinser`) und Frostwächter (`frost_warden`). Bis die Bilder existieren, zeigen
Klassenauswahl und Baum Platzhalter.

Allgemeine Regeln (wie bei den bisherigen Klassen- und Talentbildern):

- Eingebautes ImageGen mit `transparent_background: true`.
- Originale und bestehende Atlanten nie überschreiben.
- Je Bild eine `.prompt.md` mit dem exakten Prompt neben die Datei legen.
- Keine Schrift, keine Zahlen, keine Rahmen, keine Hintergründe.
- Jedes Motiv muss bei 28 bis 55 Pixeln lesbar sein.

---

## 1. Klassenporträts

Ziel: `assets/classes/<id>_portrait.png`, quadratisch, transparentes RGBA.
Grundlage: `assets/denti/denti_unarmed.png` als Identitätsreferenz,
`assets/classes/assassin_portrait_v2.png` als Stilreferenz für einen
Klassen-Denti.

Gemeinsamer Prompt-Anfang:

```text
Use case: identity-preserve. Create a class portrait of the reference Denti character for a class-selection card in Denti: Divine Dentistry. Preserve the exact recognizable little ivory molar character: tooth body silhouette, short root feet, round proportions, dark glossy eyes, glossy painted cartoon dental-game style with warm enamel highlights and dark brown outlines. Full-body pose, single character centered with transparent padding, square transparent RGBA. No text, no background, no weapons unless named below, no crown.
```

Klassenteil, jeweils angehängt:

| Datei | Klassenteil des Prompts |
| --- | --- |
| `tooth_fairy_portrait.png` | `Class: Zahnfee (tooth fairy). Small translucent pastel-gold fairy wings on the back, a tiny glowing star wand in one hand, a soft gold sparkle trail, a little satchel with a peeking gold coin. Gentle, mischievous smile, rosy cheeks. Warm gold and cream accents.` |
| `ember_portrait.png` | `Class: Glutzahn (ember tooth). The tooth body glows warm orange from within along subtle cracks like cooling lava, small flames flicker from the crown top like hair, a short charred-brown scarf. Determined grin, clenched fists. Accents of orange, ember red and soot brown; no smoke cloud covering the face.` |
| `rinser_portrait.png` | `Class: Spültechniker (rinse technician). A blue work cap, a small water tank backpack with a hose and a chrome spray nozzle held in one hand, a few water droplets and two tiny yellow electric sparks at the nozzle. Busy, confident expression. Accents of aqua blue, chrome and safety yellow.` |
| `frost_warden_portrait.png` | `Class: Frostwächter (frost warden). Icy pale-blue frost spreading over the crown like a helmet edge, a short ice-crystal cape on the shoulders, a small round shield of clear ice on one arm. Calm, stern guardian look. Accents of ice blue, white frost and steel.` |

Danach `python tools/generate_class_roster.py` ausführen. Der Generator nimmt das
Porträt automatisch, sobald die Datei existiert.

---

## 2. Talent-Symbolatlanten

Ziel: `assets/classes/<id>_talent_icons.webp`, verlustfreies WebP mit
**8 Spalten × 3 Zeilen** zu je 192 × 192 Pixeln. Jede **Zeile ist ein Ast**, die
Zellen laufen von links nach rechts in der Reihenfolge der Tabellen unten.
Überzählige Zellen bleiben vollständig transparent.

Vorgehen wie beim Molar-Atlas: Je Ast ein eigenes Blatt (4 × 2 Zellen) erzeugen,
anschließend zeilenweise in den 8 × 3-Atlas packen.

Gemeinsamer Prompt (Zahl der Symbole je Blatt anpassen):

```text
Create a NEW painted 2D video game sprite sheet for Denti: Divine Dentistry. The supplied talent atlases (assets/classes/talent_icons.webp, molar_talent_icons.webp) are a style reference ONLY. Match their warm ivory enamel, glossy gold and painted metal, saturated accent colors, warm directional highlights, slight brush texture, bold dark-brown outlines and chunky, toy-like three-dimensional shapes. Make exactly N symbols on a strict evenly spaced layout of FOUR square columns and TWO square rows, reading left to right, top to bottom; unused cells completely empty. Keep 25% clear space within each cell and every silhouette well inside its cell. Each object is large and unmistakable even at 28 pixels. Real clean transparent alpha background: zero alpha in gutters, borders and empty cells, no cast shadows, haze, backdrop glows, base plates, text, numbers, grid, borders or watermarks.
```

Form im Baum, damit die Motive passen: Skill = großer Diamant, Modifikator = kleine
Raute, Schlüsselstein = Achteck, sonst abgerundete Kachel. Das Symbol selbst
braucht keine Rahmenform.

### Zahnfee (`tooth_fairy_talent_icons.webp`)

| Zeile | 1 | 2 | 3 (Skill) | 4 | 5 | 6 | 7 (Schlüsselstein) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Glanz | Splitterschliff: geschliffener Lichtkristall mit Schleifstein-Funken | Lichtbrechung: Lichtstrahl, der an einem Prisma in zwei Strahlen bricht | **Feenstaub**: goldener Funkelregen aus einer kleinen Wolke | Sternschnuppe: Sternschnuppe mit langem Schweif | Heiligenschein: goldener Ring über einem Herz | Funkelzauber: Zauberstab mit vierzackigem Kritfunken | Glitzerwahn: übervoller Glitzertopf, der überläuft |
| Schatzkammer | Klimpergeld: zwei springende Goldmünzen mit Klang-Strichen | Sparschwein: rosa Sparschwein in Zahnform | **Kopfgeld**: Steckbrief-Rolle mit Zahn und Goldmünze | Goldene Zähne: drei goldene Zähne nebeneinander | Glückspilz: roter Fliegenpilz mit Kleeblatt | Sparstrumpf: Socke voller Münzen | Habgier: Schatztruhe mit gierig glühenden Münzen |
| Kissen | Daunenfedern: zwei weiche weiße Federn | Süße Träume: Mondsichel mit Zzz-Wölkchen (ohne Buchstaben, nur Wolkenform) | **Zahnkissen**: kleines Kissen, unter dem ein Milchzahn hervorschaut | Federbett: aufgeplustertes Federbett | Sanfter Schlaf: Schlafmütze mit Bommel | Nachtwache: Laterne mit kleinem Schild | Schlafwandler: Pantoffel mit Feenflügeln |

### Glutzahn (`ember_talent_icons.webp`)

| Zeile | 1 | 2 | 3 (Skill) | 4 | 5 | 6 | 7 (Schlüsselstein) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Esse | Zunder: Zunderbüschel mit erster Flamme | Brandbeschleuniger: Ölkanne mit Flammenspritzer | **Glutkern**: glühender Lavakern in einem Steinkranz | Nachglühen: verglimmende Kohle mit warmem Schimmer | Funkenflug: Funkenregen aus einer Esse | Schmiedefeuer: Amboss mit Flamme | Flächenbrand: brennender Kreis am Boden |
| Dampfkessel | Kesseldruck: Manometer mit Zeiger im roten Bereich | Heiße Sohlen: brennender Schuh mit Laufstrichen | **Druckablass**: Ventil, das einen Dampfstoß ausstößt | Kesselpfeife: Pfeife mit Dampfwolke | Volldampf: kleine Dampflok-Front | Sicherheitsventil: Ventil mit grünem Haken | Überdruck: platzender Kessel mit Nieten |
| Hitzeschild | Hornhaut: rissige, gehärtete Zahnschale | Abkühlung: Eiswürfel auf einer heißen Kohle | **Glühende Haut**: Zahn mit glühenden Rissen und Hitzeflimmern | Asbestschmelz: feuerfester Handschuh | Schlacke: dunkle Schlackebrocken mit Glutadern | Glutdornen: Kugel mit glühenden Dornen | Lavakern: Zahn mit Lavaherz im Inneren |

### Spültechniker (`rinser_talent_icons.webp`)

| Zeile | 1 | 2 | 3 (Skill) | 4 | 5 | 6 | 7 (Schlüsselstein) |
| --- | --- | --- | --- | --- | --- | --- | --- |
| Leitung | Kupferader: Kupferkabel mit Funken | Mehrleiter: dreifach verzweigter Blitz | **Kurzschluss**: geschlossener Wasserring mit Blitz in der Mitte | Starkstrom: Hochspannungsblitz auf gelbem Warnschild | Funkenregen: Wassertropfen mit Funken | Erdung: Erdungsspieß mit kleinem Schild | Hochdruck: Druckdüse mit hartem Wasserstrahl |
| Spülung | Langer Schlauch: aufgerollter blauer Schlauch | Tropfnass: drei große Wassertropfen | **Schwall**: brechende Welle | Sog: Wasserstrudel | Pfützenteppich: zwei glänzende Pfützen | Schaumbad: Schaumberg mit Blasen | Wischmop: Wischmop mit Wasserspur |
| Wartung | Kalkschicht: weiße Kalkkruste auf Fliese | Spülwasser: Glas mit Mundspülung | **Notdusche**: Notdusche mit Zugkette und Wasserschwall | Kalkschutz: Schild aus Kalkplatten | Nachspülen: Wasserhahn mit Rücklaufpfeil | Tropfsteinschild: Tropfstein über einem Schild | Abdichtung: Dichtungsring mit zwei Schilden |

### Frostwächter (`frost_warden_talent_icons.webp`)

| Zeile | 1 | 2 | 3 | 4 | 5 | 6 | 7 | 8 |
| --- | --- | --- | --- | --- | --- | --- | --- | --- |
| Gletscher | Dicke Wand: dicker Eisblock | Weite Wand: lange Eismauer in Perspektive | Zackenwand: Eiswand mit Zacken | **Frostwelle**: zerspringende Eiswand mit Splittern | Dauerfrost: Eis mit Schneeflocke und Uhr | Rutschbahn: glatte Eisrutsche mit Pfeil | Lawine: Schneelawine | *(Schlüsselstein)* Permafrost: tiefgefrorener Boden mit Eiskristall |
| Bruch | Kältebiss: Eiszahn mit Frostbiss-Spur | Eispickel: Eispickel | **Zerschmettern**: zerberstender Eisblock | Schwerer Hammer: schwerer Hammer mit Frost | Kettenbruch: drei zerspringende Eiskristalle in Kette | Eiszapfen: drei Eiszapfen | Schockfrost: Eiskristall mit Kritfunken | *(Schlüsselstein)* Glasschmelz: gläserner Zahn mit Sprüngen |
| Wacht | Eisschicht: Zahn mit Eisüberzug | Frostmantel: kurzer Frostumhang | **Eispanzer**: Schild aus klarem Eis | Raureif: Zweig mit Raureif | Frostatem: kalter Atemhauch mit Kristallen | Kältestarre: erstarrte Eisfigur mit Stoßlinien | Festung: kleine Eisfestung | *(leer)* |

---

## 3. Einbau

1. Atlanten unter `assets/classes/` ablegen und in `.gitignore` die
   `.import`-Ausnahme ergänzen, wie für `molar_talent_icons.webp.import`.
2. In `scripts/ui/denti_ui_icons.gd` je Atlas eine Konstante mit 8 Spalten und
   3 Zeilen anlegen und `talent(index)` um die Bereiche erweitern. Die Bereiche
   liegen hinter den vorhandenen Atlanten, in dieser Reihenfolge: Zahnfee,
   Glutzahn, Spültechniker, Frostwächter. Jeder Bereich umfasst 24 Zellen.
3. In `tools/generate_class_roster.py` bei `ATLAS_BASE` den ersten Index jedes
   Atlas eintragen. Den Startwert aus `talent()` ableiten: Er beginnt hinter den
   Zellen von Basis-, Molar- und Assassinen-Atlas.
4. `python tools/generate_class_roster.py` ausführen. Der Generator schreibt
   Symbole und Porträts in die `.tres`-Dateien. Die `.tres` nicht von Hand ändern,
   sonst überschreibt der nächste Generatorlauf sie.
5. Prüfen mit
   `Godot_v4.7.2-stable_win64.exe --path . --script res://tools/preview_class_talents.gd`
   (Aufnahmen `talent_<id>_1280x720.png` und `class_pick_*.png` unter `.godot/`)
   und `python tools/run_tests.py --godot <godot> --filter class_roster --filter class_talents`.
