# Neue Talent-Icons für die Assassine

Generiert mit dem eingebauten ImageGen-Tool mit `transparent_background: true`.
Stilreferenzen waren der bestehende `talent_icons.webp`-Atlas, das Giftpaket
`item_icons_poison.png` und die Denti-Silhouette aus `denti_unarmed.png`.
Die Motivliste stammt aus `docs/TALENT_TREE_V3_PLAN.md`.

Der verlustfreie WebP-Atlas enthält 7 × 2 Zellen à 192 × 192 Pixel.
Die Motive folgen zeilenweise der Reihenfolge Giftspur, Zuckerrausch und Zahnpflege.
Die letzte Zelle ist frei.

## Gemeinsamer Prompt

```text
Create a NEW production icon sprite sheet for Denti: Divine Dentistry. Image 1 is a style reference only. Match the original gameplay icons: glossy hand-painted 2D cartoon dentistry, warm ivory enamel, brilliant lacquer colors, dark aubergine-brown outlines, strong small-scale silhouettes, rounded depth, rich but simple color separations. These illustrations must read in small talent tree cells, 24-50px. Every subject is a standalone cutout positioned at the center of its cell, with at least 8% clear margin around every drawn part. Do not draw grid lines, text, frames, signs, backgrounds, outer glow, fog haze outside solid motifs, gradients on the canvas, or drop shadows. True PNG alpha transparency (zero alpha background and cell gutters). No neighboring pixels or objects overlapping any cell boundary.
```

## Giftspur

```text
Strict 2 columns × 2 rows of equal square cells. Exactly four icons. Image 2 is a palette reference for lime poison, aubergine and enamel.
Top left — Giftblüte: a venomous stylized blossom with chunky splayed sour-lime petals and a tiny ivory skull-like molar in its center. Show the tooth with two simple dark eye hollows, the flower clearly opening. Top right — Kettenblüte: exactly three translucent acid-green poison bubbles joined by two short links of bright purple dental floss, rising diagonally in a chain. Bottom left — Dichter Nebel: a dense rounded low cloud of green toxic haze with broad, solidly painted lime and deep emerald lobes, a light tooth silhouette visible within, no vapor outside the outline. Bottom right — Platzende Blüte: a sharply bursting dark violet flower bud in side-facing three-quarter view, with a bright acid-lime angular pop and five large scattered poison droplets. Visually emphasize the explosion and closed bud against Giftblüte's distinct broad open flower.
```

## Zuckerrausch

```text
Strict 2 columns × 2 rows of equal square cells. Exactly four icons. Image 2 is a shape reference only for the ivory molar mascot.
Top left — Rausch: saturated pink hard candy in a crimped wrapper with a bold amber lightning bolt in front of it and thick hot-pink horizontal speed swooshes. Top right — Zuckerguss: a thick sheet of glossy pink sugar glaze pouring from a tiny tilted gold spoon and coating a visibly taut diagonal ivory dental floss thread with raspberry droplets, broad simple S-shaped composition. Bottom left — Kein Kater: a cheerful ivory molar wearing black plum sunglasses beside a clearly crumpled empty raspberry candy pouch, no labels or logos. Bottom right — Hyperaktiv: an upright bright magenta and orange spiral lollipop on a short ivory stick, with two pairs of thick electric-yellow jitter streaks on either side, compact and visibly different from the wrapped candy.
```

## Zahnpflege

```text
Strict 3 columns × 2 rows of equal square cells. Exactly five icons and the bottom RIGHT cell completely clear. Image 2 is a reference for Denti's recognizable silhouette.
Top left — Durchflutschen: Denti in a fast ghostly mint afterimage with the original ivory molar shape visible and swept turquoise streaks behind it, phasing through a sharply shattered magenta orb. Top middle — Heilflutsch: broken magenta projectile fragments transforming into plump translucent mint-green healing drops, distinguished by a small bright green plus and teal accents; flow from upper left to lower right. Top right — Spiegelschmelz: a silver mirror-polished molar-facing enamel plate in perspective deflects a thick bright lime poison arrow back at an angle, with one small reflection spark. Bottom left — Schildpolitur: a warm cream-and-teal dental rotary polishing head rubbing a glossy rounded blue shield with gold trim and one oversized clean white gleam. Bottom middle — Federleicht: bright hovering ivory molar at an angle with a large soft pale lavender feather curled up beside it, a single short mint upward movement swoosh. Bottom right — completely transparent.
```
