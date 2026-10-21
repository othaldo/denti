# Karies-Prinz: generierte Einzelteile

Erzeugt am 20.10.2026 mit dem integrierten Imagegen-Werkzeug, mit echtem
transparentem Hintergrund. Keine API-/CLI-Ausweichlösung.

Projektdatei: `assets/enemies/prince_caramel/parts.png`. Das unveränderte
generierte Original wird über native AtlasTexture-Regionen gelesen. Die
Ausgabe hält das gewünschte gleichmäßige Raster nicht exakt ein; deshalb
verwendet der Code individuell vermessene Grenzen statt gestreckter Zellen.
Es wurden keine Teilbilder per Hand nachgemalt oder Originalreferenzen ersetzt.

Stilreferenzen: `assets/enemies/count_rig/portrait.png`,
`assets/enemies/bacteria.png`, `assets/denti/denti_unarmed.png`.
Die Referenzen bestimmen Malstil und Materialbehandlung, nicht die Körperform.

Das Porträt `assets/enemies/prince_caramel/portrait.png` stammt aus dem
nativen Rig-Renderer `tools/preview_caramel_prince.gd -- --portrait`.

## Vollständiger Generierungsprompt

```text
Use case: stylized-concept
Asset type: production-ready modular 2D game sprite atlas for Denti: Divine Dentistry, the SECOND boss, Karies-Prinz, caramel kitchen encounter.
Reference images: supplied files are STYLE REFERENCES ONLY (glossy painted cartoon, warm burgundy outlines, cream highlights, charming expressive face). Do not copy their tooth body, vampire silhouette or props.
Create ONE square transparent PNG, precisely arranged as a 3 by 3 grid of NINE equally sized cells, each isolated object entirely inside its own cell with generous transparent gutters. No grid lines, no labels, no text, no backdrop, no ground shadows, no checkerboard painted into image.
Consistent front/three-quarter overhead arena game view, upper-left soft light. Broad simple readable forms, painterly glossy highlights, deep warm dark plum outlines. Designed to be readable at 100-160 px tall, avoid fussy small details.
Cell order, left to right, top to bottom:
1. MAIN BOSS TORSO: a very wide squat smug amber caramel pudding prince sitting inside his round copper cooking cauldron like a belly. Head is glossy flowing caramel, thick confident dark plum eyebrows, big mischievous eyes, one little cream sugar fang, crooked crown made of thick ivory icing with three chunky candied tips. Pot belly is dark copper with golden rim, a big caramel drip down its front. NO arms, NO hands, NO legs, NO spoon on this isolated torso. The funny imposing boss is a pudding creature and kitchen tyrant, NOT a tooth, NOT humanoid human, NOT the previous vampire.
2. Detached entire RIGHT ARM WITH LADLE, chunky caramel shoulder at lower left, elbow, hand gripping a very large copper/gold ladle reaching to upper right, ladle bowl full of glowing amber sugar. One single connected object, arm thick enough to rotate as one skeletal piece.
3. Detached entire LEFT ARM, chunky caramel shoulder at upper right with stubby bent forearm and hand to lower left presenting a round glossy amber sugar grenade, ivory sugar cap and a small dark plum fuse. One connected object.
4. Detached LEFT FOOT with short caramel shin and cream chef slipper. Toe points left, chunky simple single piece.
5. Detached RIGHT FOOT, matching left foot, toe points right.
6. Isolated sugar grenade projectile, very readable large amber sphere with a diagonal cream sugar stripe, small plum fuse and bright tiny ember. NO arm.
7. Floor decal of a sticky caramel puddle, overhead view, irregular scalloped organic outline, transparent thin amber syrup interior, slightly thick glossy darker burnt honey edge, a few cream highlights and syrup bubbles. No circle outline, no rocks, no ground plane, no shadow, no opaque dark disk. Flat on the floor, not a standing bowl.
8. Caramel impact splash burst, an organic low fan of amber syrup and a few cream sugar chunks flying out from the center, seen in game view. No circular shockwave and no smoke cloud. Transparent between droplets.
9. Small freestanding crystallized sugar heart/kernel, chunky amber candy crystal with pale cream top and copper-brown base, a possible later destroyable control target. No text.
Maintain the same materials and proportions across the modular parts. True transparent alpha background. This is game art, not a UI mockup.
```
