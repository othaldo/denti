# Gemalter Atlas für die Synergie-Relikte

`DentiUIIcons.relic_icon` lädt den Atlas für die zwölf Synergie-Relikte.

Erzeugt mit dem eingebauten Bildgenerator (`image_gen.imagegen`,
`transparent_background: true`). Die Motive wurden anschließend in den
Atlaszellen zentriert und mit transparenten Rändern eingepackt.

Referenzen (nur Stil):

- `assets/relics/relic_icons_atlas.png` (die sechs ursprünglichen Relikte)
- `assets/items/item_icons_expansion_2.png`

Der [Atlas](relic_icons_expansion.png) ist 1440 × 1080 px groß (RGBA) und hat
**4 Spalten × 3 Zeilen** mit je 360 × 360 px großen Zellen. Die Reihenfolge
läuft zeilenweise von links oben. Zelle 0 gehört zu `icon_index = 6`.

| Zelle | Relikt | Motiv |
| --- | --- | --- |
| 0 | Zahnspange | goldene Zahnspange über zwei kleinen Elfenbeinzähnen, zwei unterschiedlich farbige Edelsteine (Rubin, Saphir) als Brackets |
| 1 | Glockenkrone | kleine goldene Krone, die zugleich eine Glocke ist, Elfenbein-Klöppel, sanfter Schall-Ring |
| 2 | Schattenseide | Spule mit dunkelvioletter, schimmernder Zahnseide, ein limettengrüner Gifttropfen am Fadenende |
| 3 | Tollkirsche | glänzende schwarzviolette Beere mit grünem Kelch, in einer goldenen Zahnfassung, kleiner grüner Giftglanz |
| 4 | Milchzahndose | runde Elfenbein-Dose mit goldenem Deckel und Zahnemblem, ein Milchzahn und Münzen schweben heraus |
| 5 | Glückspfennig | goldene Münze mit eingeprägtem Backenzahn und vierblättrigem Kleeblatt, Lichtfunkeln |
| 6 | Zunderzahn | Elfenbein-Backenzahn mit glimmenden orangeroten Glutrissen und kleiner Flamme an der Wurzel |
| 7 | Hitzestein | rundlicher Amalgam-Stein, von innen orange glühend, zarte Hitzewellen |
| 8 | Kupferkrone | Kupferkrone mit gelben Blitzbögen und Wassertropfen |
| 9 | Mundspülstrudel | türkiser Mundspül-Wirbel in einem goldenen Becherrand, Schaumbläschen |
| 10 | Eisblume | Eiskristall-Blüte mit eisblauen Blütenblättern, kleiner Elfenbeinzahn in der Mitte |
| 11 | Gletscherherz | herzförmiger Gletscherkristall in goldener Reliquienfassung, Frosthauch |

Verwendeter Prompt

```text
Use case: stylized-concept. Create a NEW transparent painted sprite atlas for the 2D game Denti: Divine Dentistry. Image 1 (existing relic atlas) and image 2 (item icons) are style references only. Match the warm glossy cartoon dental style, dark chocolate contours, volumetric hand-painted gradients, strong specular highlights, saturated colorful materials. Deliver exactly twelve individual icon cutouts in a regular four-column by three-row grid, 4:3 canvas, equal square cells. Each cell holds one icon centered within its own invisible cell, using around 76–80 percent of the cell and with wide clean gutters. True alpha transparency all around icon silhouettes. No backgrounds, panels, shadows beneath icons, text, numbers, grid lines, faces, or overlap. Size and center the silhouettes consistently. Make the silhouettes readable at 48–64 px. Row 1, left to right: (1) two adjacent ivory molars with a gold orthodontic wire and prominent ruby and sapphire brackets; (2) a small yellow-gold crown shaped as a bell, with visible ivory clapper and short golden sound arcs; (3) an upright spool of dark violet shimmering dental floss, with one vivid lime-green poison drop at the loose thread end; (4) one glossy black-violet belladonna berry with a bright green calyx in a small golden tooth-shaped setting. Row 2, left to right: (5) an open round ivory tin with golden lid and tooth emblem, a small milk tooth and two coins floating above it; (6) a round golden lucky coin embossed with a molar and a green four-leaf clover, with a compact glint; (7) an ivory molar with vivid orange-red glowing ember cracks and a small flame at its roots, large white silhouette; (8) a rounded dark metallic amalgam stone with a glowing orange core and short heat curls, distinct from the tooth beside it. Row 3, left to right: (9) a reddish copper crown with strong yellow zigzag lightning arcs and blue water droplets, distinct from the yellow bell crown; (10) a turquoise mouthwash whirlpool in a thin gold cup rim, with foam bubbles; (11) a pale ice-blue crystal flower with radially arranged icy petals and a tiny ivory tooth in its center; (12) a deep blue, distinctly heart-shaped faceted glacier crystal in a thin golden reliquary setting with a small frost curl. Keep the row order and preserve each visual motif.
```
