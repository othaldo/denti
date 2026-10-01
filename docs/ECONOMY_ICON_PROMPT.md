# Economy-Icons · Generierung

Erzeugt am 01.10.2026 mit OpenAI ImageGen, transparentem Hintergrund und der lokalen Stilreferenz `assets/items/item_icons_expansion_2.png`.

Die unveränderte Quelle ist `assets/items/reference/economy_icons_source.png`. Das Spiel verwendet `assets/items/item_icons_economy.png`: zwei gepolsterte Atlaszellen, Goldsonde links und Goldextraktor rechts. Der Packvorgang ist mit `python tools/pack_economy_icons.py` reproduzierbar.

## Verwendeter Prompt

Create a transparent game item icon atlas for Denti Divine Dentistry in the exact glossy hand-painted cartoon dental style of the supplied reference atlas: rich ivory, gold and turquoise, soft dark burgundy outlines, clean readable silhouettes, dimensional painted highlights. TWO separate icons in ONE row, equal square cells, wide 2:1 canvas, each centered with at least 12% empty transparent padding, absolutely no text, no letters, no grid or background. LEFT: Goldsonde, a compact dental explorer detector, gold handle and elegant curved silver probe tip, turquoise glowing detector ring circling a single large gold coin with embossed tooth, plus a tiny sparkle. Dental tool, not a gun. RIGHT: Goldextraktor, chunky elegant dental extraction forceps with dark burgundy grip and silver/golden jaws holding TWO small gold tooth coins, clear distinct plier silhouette, a single ivory molar etched on hinge. Both artwork isolated, no shared elements and no parts entering neighboring cell, same scale and detail, readable at 48 pixels. Preserve warm whimsical polished original art style; not flat vector, no photorealism.
