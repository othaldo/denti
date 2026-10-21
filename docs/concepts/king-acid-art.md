# Säuresammler-König: generierte Originalgrafiken

Erstellt mit dem eingebauten Imagegen-Werkzeug am 21.10.2026; kein CLI-/API-Fallback.

Projektdateien:
- `assets/enemies/king_acid/parts.png`: generierter RGBA-Atlas, 1254×1254.
- `assets/enemies/king_acid/acid_stream.png`: eigenständige generierte RGBA-Flusstextur, 2172×724.
- `assets/enemies/king_acid/portrait.png`: transparentes natives Renderbild des aus den Teilen gebauten Rigs.

Die Originale `assets/enemies/cavity_king.png` und sämtliche Prinz-Grafiken bleiben unverändert. Die Referenzen dienen Thema beziehungsweise Malstil. `KingAcidArt` enthält die tatsächlichen Ausschnitte; es gibt keine Textur-/Bilderzeugung während des Kampfes. Teile werden proportional skaliert und an sechs Bone2D-Gelenken bewegt. Ein Shader lässt nur die grünen Reservoirbereiche sichtbar sinken/steigen. Die Flusstextur wird proportional wiederholt und verschoben.

## Prompt für den Teileatlas

Use case: stylized-concept. Asset type: production transparent 2D game sprite parts atlas for Denti: Divine Dentistry, a charming painted cartoon dental arena survivor. Generate one square image containing a strict evenly spaced 3 by 3 grid of NINE ISOLATED PARTS, no labels or gridlines. Reference 1 (old tooth king) is thematic inspiration, NOT an edit target. Reference 2 (caramel parts atlas) is ONLY the painted material/outline/render quality reference. New character: THE ACID COLLECTOR KING. Must look fundamentally different from the rounded caramel prince: tall heavy ivory and dark teal calcified tooth-armour, a stern narrow expressive tooth face, a broad mineral crown with small green gems, large clear acid reservoirs and siphon machinery on his arms, enormous stone boots. Royal absurd dental collector, readable and mischievous, no realistic gore, no cauldron, no orange caramel, no red ruby crown, no huge fanged mouth. Warm ivory highlights, deep teal/purple shadows, polished brass fittings, luminous yellow-green acid. Fixed frontal slight top-down game view, upper-left lighting, confident dark outlines, glossy painted detail simplified for ~170px final assembled height.
EACH CELL contains one separate complete part surrounded by transparent padding; NEVER overlap cells or add text:
top left: the central TALL torso/head/crown alone, no arms and no feet, dark teal breastplate with a recessed round dark core socket;
top middle: LEFT arm, large glass acid reservoir with a curved brass siphon nozzle pointing down and outward, ivory shoulder and elbow joint, detached;
top right: RIGHT arm with a huge calcified stone fist/hammer and a smaller glass acid reservoir, detached;
middle left: left heavy ivory/teal mineral boot, detached;
middle middle: matching right heavy boot, detached;
middle right: glowing green faceted acid core, round shield-shaped insert that fits the torso socket;
bottom left: horizontal ORGANIC flowing acid-stream texture, flat top-down elongated glossy lime-green liquid with soft bubbling edges and no ground/shadow, suitable for repeating along a channel, approximately four times wider than tall within the cell;
bottom middle: isolated chunky triangular ivory/teal tooth-stone shard cluster bursting upward, no ground;
bottom right: isolated glossy lime-green acid droplet with bright ivory highlight, no aura.
Genuine transparent RGBA background everywhere between parts. NO checkerboard, NO black backdrop, NO scene or UI. Preserve source references unchanged. Each part must be assembled through rigid rotation and UNIFORM scale only, so paint full silhouettes and leave clear attachment bases.

## Prompt für die Flusstextur

Use case: stylized-concept. Production 2D game VFX texture for a painted cartoon dental game. Supporting style reference is the supplied acid king atlas, not an edit target. Generate a BRAND NEW genuinely transparent RGBA image, very wide horizontal composition about 3:1. ONE CONTINUOUS TOP-DOWN RIVER OF LIME GREEN ACID across the entire image from the LEFT EDGE to the RIGHT EDGE. A seamless horizontally repeating flow texture: left and right cross-sections must align and be equally thick, acid MUST TOUCH both horizontal edges. NO end caps, no isolated puddles, no separate blob chain, no repeated sausages, no creature. The river occupies the central third of image height, transparent above and below. Slightly irregular soft organic banks, broad continuous deep chartreuse liquid, flowing cream-yellow highlights, translucent green eddies, a few fine pale foam bubbles. Flow direction left to right, rich painted material and clear glossy light, matching the acid reservoirs in reference. Subtle dark green edges, NOT heavy black cartoon outlines within the fluid. NO rocks, no ground, no shadows, no text or arrows, no frame, no checkerboard. The artwork will be uniformly scaled and repeated along long streams and animated through translation; it must read as dangerous flowing liquid, not a string of plants or decorative goo shapes.

