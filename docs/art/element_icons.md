# Gemalte Elementsymbole

Erzeugt am 27.10.2026 mit dem eingebauten Imagegen-Werkzeug und
`transparent_background: true`, ohne CLI. Stilreferenz:
`assets/items/item_icons_atlas.png`. Die Referenz wurde nicht verändert.

Spielasset: `assets/ui/element_icons_atlas.png`, 1536×1024 RGBA mit echtem Alpha.
Die generierte Datei wurde pixelidentisch übernommen; der Import erzeugt Mipmaps.
`DentiUIIcons.item()` zentriert die sechs vollständigen Motive in 512×512-Rahmen.
Die Indizes 91–96 sind für Elemente reserviert; bisherige Itemindizes bleiben gleich.

| Index | Effekt | Symbol |
| --- | --- | --- |
| 91 | Feuer | Orange Flamme |
| 92 | Eis | Cyanfarbener Eiskristall |
| 93 | Gift | Grüner Giftschädel |
| 94 | Blutung | Rote Blutstropfen |
| 95 | Elektro | Gelber Blitz |
| 96 | Wasser | Blauer Tropfen mit Welle |

Die Ressourcen in `data/affixes/` wählen diese Indizes. Dadurch verwenden
Verzauberungsauswahl, belegte Plätze, Fusionsvorschau, Dentipedia und alte
Kapselansichten dieselben Symbole. Der Atlas wird über die gemeinsame Iconklasse
vorgeladen. Waffenbilder, Angriffseffekte und Verstärkungsicons bleiben unverändert.

Native Prüfung mit `tools/preview_element_icons.gd`:
[Auswahl](../screenshots/element_icons/elements.png),
[16/24/32/48 Pixel](../screenshots/element_icons/native_sizes.png).

## Verwendeter Prompt

Use case: stylized-concept. Asset type: production transparent game UI icon atlas for Denti Divine Dentistry. Generate ONE NEW 1536 x 1024 transparent PNG sprite sheet, exactly THREE equal square columns by TWO equal square rows (512px cells), SIX SEPARATE icons total. The reference sheet is STYLE ONLY: match its glossy hand-painted warm cartoon game art, dark plum outlines, soft painted volume and crisp specular highlights. Do NOT reuse the reference's objects, bottles, tools, toothpaste, teeth, labels or faces. These are direct ELEMENT SYMBOLS, immediately recognizable at 24-48 px. Uniform optical size, each symbol centered in its cell with a generous 70px transparent safety gutter, no neighboring overlap. Fixed row-major order: TOP LEFT FIRE, one compact orange/red flame with bright golden center and a bold curved silhouette. TOP MIDDLE ICE, one chunky six-point cyan ice-crystal snowflake with white faceted highlights, recognizable snowflake silhouette. TOP RIGHT POISON, one vivid lime-green stylized toxic skull with two dark eye sockets and a small green bubble beside it, playful and symbolic, no gore. BOTTOM LEFT BLEED, one large glossy deep ruby-red blood droplet and two much smaller red droplets, clean symbolic design. BOTTOM MIDDLE ELECTRIC, one thick bright golden-yellow zigzag lightning bolt with a very small cyan electric spark, primary silhouette unmistakably a lightning bolt. BOTTOM RIGHT WATER, one large glossy saturated blue water droplet with a small turquoise wave curl inside its lower half, smooth pointed top, no face. No text, no numbers, no frames, no badges, no tile backgrounds, no checkerboard painted into the image, no floor shadows or haze outside the silhouettes. Actual transparent alpha background. Keep silhouettes simple and thick, avoid ornamental details that disappear at game size. Six icons in total, in the exact grid order specified.
