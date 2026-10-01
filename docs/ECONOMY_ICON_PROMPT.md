# Economy-Icons · Generierung

Erzeugt am 01.10.2026 mit OpenAI ImageGen, transparentem Hintergrund und der lokalen Stilreferenz `assets/items/item_icons_expansion_2.png`.

Die ursprüngliche Quelle bleibt unverändert in `assets/items/reference/economy_icons_source.png`. Die Korrektur liegt separat in `assets/items/reference/economy_icons_source_v2.png`. Das Spiel verwendet `assets/items/item_icons_economy.png`: zwei gepolsterte Atlaszellen, Goldsonde links aus der ursprünglichen Quelle und Goldextraktor rechts aus der Korrektur. Der Packvorgang ist mit `python tools/pack_economy_icons.py` reproduzierbar.

## Verwendeter Prompt

Create a transparent game item icon atlas for Denti Divine Dentistry in the exact glossy hand-painted cartoon dental style of the supplied reference atlas: rich ivory, gold and turquoise, soft dark burgundy outlines, clean readable silhouettes, dimensional painted highlights. TWO separate icons in ONE row, equal square cells, wide 2:1 canvas, each centered with at least 12% empty transparent padding, absolutely no text, no letters, no grid or background. LEFT: Goldsonde, a compact dental explorer detector, gold handle and elegant curved silver probe tip, turquoise glowing detector ring circling a single large gold coin with embossed tooth, plus a tiny sparkle. Dental tool, not a gun. RIGHT: Goldextraktor, chunky elegant dental extraction forceps with dark burgundy grip and silver/golden jaws holding TWO small gold tooth coins, clear distinct plier silhouette, a single ivory molar etched on hinge. Both artwork isolated, no shared elements and no parts entering neighboring cell, same scale and detail, readable at 48 pixels. Preserve warm whimsical polished original art style; not flat vector, no photorealism.

## Korrektur: zwei Klingen statt drei

Am 01.10.2026 mit dem eingebauten ImageGen als Bearbeitung der Originalquelle erzeugt, mit transparentem Hintergrund. Nur die rechte Atlaszelle wird übernommen; die linke bleibt exakt erhalten. Die zusätzliche Metallspitze zwischen den beiden Klingen entfällt.

### Verwendeter Bearbeitungsprompt

Use case: precise-object-edit. Input image 1 is the EDIT TARGET: a transparent two-icon dental game atlas. Correct ONLY the RIGHT icon, the burgundy-handled Goldextraktor extraction forceps/scissors, to have exactly TWO functional curved metal jaws/blades, one upper and one lower, operated by the existing two grips and one round hinge. It currently has an erroneous THIRD silver triangular blade projecting right/up from the hinge into the middle gap behind the two coins: completely remove that extra middle metal wedge/point. The gap between the upper and lower jaws must be clearly empty transparent negative space except for the two gold tooth coins already being gripped. Make the two remaining opposed jaws mechanically coherent and readable, with exactly two metal working tips. Preserve both gold tooth coins, the round ivory-tooth hinge ornament, both burgundy grips, golden trims, composition, orientation, scale and glossy hand-painted cartoon dental style. Keep the ENTIRE LEFT Goldsonde icon unchanged, including gold handle, turquoise swirl, coin and probe. Preserve the canvas aspect ratio 2:1, two independent equal cells, and real alpha transparency. No additional objects, text, background, third jaw, extra metal spikes, extra handles or photorealism.
