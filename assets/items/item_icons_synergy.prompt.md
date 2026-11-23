# Bildauftrag für die Synergie-Items

Plan: [docs/ITEM_SYNERGY_EXPANSION.md](../../docs/ITEM_SYNERGY_EXPANSION.md).

Mit dem eingebauten Bildgenerator (`image_gen.imagegen`, `transparent_background: true`)
erzeugen. Keine bestehenden Grafiken verändern. Nach dem Erzeugen jede Zelle bei
Shop-Kartengröße (~48 px) prüfen und unten „Ergebnis“ ausfüllen.

## 1. Item-Atlas

Datei `assets/items/item_icons_synergy.png`, RGBA, **7 Spalten × 2 Zeilen**,
gleich große quadratische Zellen (z. B. 1792 × 512, Zellen 256 px). Zeilenweise:

| Zelle | Item | Motiv |
| --- | --- | --- |
| 0 | Blumentopf | kleiner Terrakotta-Blumentopf mit Zahn-Emblem, aus dem ein Salbeitrieb und ein Eiskristall wachsen |
| 1 | Dünger | prall gefüllter Jutesack mit grünem Dünger, kleine Zahnfigur auf dem Etikett, ein paar grüne Körnchen |
| 2 | Wurzelnetz | goldenes Netz aus feinen Wurzeln, in dessen Mitte ein kleiner Elfenbeinzahn leuchtet |
| 3 | Taschenbeet | aufgeklappte Hosentasche aus Stoff, aus der ein kleiner Salbeitrieb mit Samenkapsel ragt |
| 4 | Zahnseidenfalle | gespannte Zahnseiden-Schlinge zwischen zwei kleinen Pflöcken mit rotem Zünder |
| 5 | Sprungfeder | kräftige goldene Spiralfeder unter einem kleinen Zahn-Stempel, Bewegungsbögen |
| 6 | Nachhall-Krone | kleine Krone mit drei konzentrischen Schall-Ringen dahinter |
| 7 | Rutschwachs | Dose mit glänzendem rosa Wachs und einer Gleitspur, kleine Glanzpunkte |
| 8 | Katalysator | Reagenzglas mit zwei sich mischenden Flüssigkeiten (orange und eisblau), Funken |
| 9 | Thermoskanne | silber-rote Thermoskanne, halb vereist, halb glühend |
| 10 | Gewitterwolke | kleine dunkle Regenwolke mit gelbem Blitz und blauen Tropfen |
| 11 | Minzbeet | kleines Beet mit drei frischen Minzblättern |
| 12 | Scharfe Zahnpasta | Zahnpastatube mit rot-grünem Streifen, aus der eine kleine Flamme schießt |
| 13 | Kompost | kleiner Holzkomposter mit Blättern und einem Minzblatt obenauf |

```text
Create a NEW painted 2D video game item icon atlas for Denti: Divine Dentistry. Style references only: assets/items/item_icons_expansion_2.png and assets/relics/relic_icons_expansion.png. Match the glossy cartoon dental style: warm ivory enamel, glossy gold, saturated accent colors, soft painted gradients, strong highlights, bold dark-brown outlines, chunky toy-like shapes, readable at 48 px. Exactly fourteen separate icons on a strict grid of SEVEN square columns and TWO square rows, reading left to right, top to bottom, each centered in its own cell with about 20 % clear padding. True transparent alpha background, no shadows under icons, no backgrounds, panels, text, numbers, grid lines or faces. Row 1: (1) small terracotta flower pot with a tooth emblem, a sage sprout and a small ice crystal growing out of it; (2) plump jute sack of green fertilizer with a tooth figure on its label and a few green granules; (3) golden net of fine roots with a small glowing ivory tooth in its centre; (4) an opened fabric trouser pocket with a small sage sprout and seed pod sticking out; (5) a taut dental-floss snare between two small pegs with a red trigger; (6) a strong golden spiral spring under a small tooth-shaped stamp with motion arcs; (7) a small crown with three concentric sound rings behind it. Row 2: (8) a tin of glossy pink wax with a sliding streak and sparkles; (9) a test tube with two mixing liquids, orange and ice-blue, with sparks; (10) a silver-red thermos flask, half frozen and half glowing hot; (11) a small dark rain cloud with a yellow lightning bolt and blue drops; (12) a small garden bed with three fresh mint leaves; (13) a toothpaste tube with a red-green stripe shooting a small flame; (14) a small wooden compost bin with leaves and one mint leaf on top. Wide 7:2 canvas, genuine RGBA.
```

## 2. Beute-Sprite „Minzblatt“

Datei `assets/loot/mint_leaf.png`, RGBA, quadratisch (z. B. 256 × 256), ein einzelnes
frisches, leicht leuchtendes Minzblatt mit kleinem Glanzpunkt, gut lesbar bei 20 px,
klar unterscheidbar von Münzen (gold) und XP (Stil siehe `assets/loot/`).

```text
Create a single painted 2D loot pickup sprite for Denti: Divine Dentistry on true transparent RGBA: one fresh bright-green mint leaf with a soft inner glow and a small white highlight, slightly tilted, bold dark-brown outline, glossy cartoon style matching the game's coin and XP pickups. Square canvas, centered with padding, readable at 20 px, no text, no background, no shadow.
```

## Ergebnis

Die beiden Grafiken wurden mit dem eingebauten ImageGen und transparentem
Hintergrund erzeugt. Für den Atlas dienten `item_icons_expansion_2.png` und
`relic_icons_expansion.png` als Stilreferenzen. Für das Minzblatt dienten
`gold_tooth_coin.png` und `xp_crystal.png` als Stilreferenzen.

Beim finalen Atlas-Prompt standen die 14 oben beschriebenen Motive in derselben
Reihenfolge auf einer quadratischen 4×4-Vorlage. Der zusätzliche Layoutteil
lautete:

```text
Paint exactly fourteen icons in the first fourteen positions of a precise FOUR-by-FOUR square production contact sheet. Use four equal columns and four equal rows, with icons centered at x = 12.5%, 37.5%, 62.5%, 87.5% and y = 12.5%, 37.5%, 62.5%, 87.5%. Keep the last two cells entirely transparent. Every icon has generous transparent margins and air on all four sides, all parts and effects within its cell. Fill each icon's footprint to around 78% of the cell, with similar visual weight across the sheet. Sequential slots 1 to 14 occupy 4 + 4 + 4 + 2 positions, in standard reading order.
```

Der finale Minzblatt-Prompt ergänzte den ursprünglichen Auftrag um die Ausrichtung
vom Stiel links unten zur leicht gekerbten Spitze rechts oben, leuchtendes
Frühlingsgrün und einen warmen dunklen Rand. Das Blatt sollte bei kleinem Maßstab
auch ohne lose Glanzpunkte klar zu erkennen sein.

- `assets/items/item_icons_synergy.png` enthält 14 quadratische Zellen à 256 px
  im 7×2-Raster (1792 × 512 px RGBA). Jede Zelle wurde in einer 48-px-Vorschau geprüft.
- `assets/loot/mint_leaf.png` ist 256 × 256 px RGBA. Das sichtbare Blatt wurde
  bei etwa 20 px neben Münze und XP-Kristall geprüft.
