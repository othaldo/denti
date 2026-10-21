# Schwierigkeitsmotive

Erzeugt am 21.10.2026 mit dem eingebauten Imagegen-Werkzeug.
Referenzen: `assets/denti/denti_unarmed.png` und `assets/ui/stat_icons_atlas.png`.
Das vollständige generierte RGBA-Atlasbild bleibt als `difficulty_motifs_source.png`
erhalten (tatsächliche Ausgabe: 1254×1254 RGBA). Die vier Laufzeitbilder liegen
in `assets/ui/run_setup/`.

Die tatsächlichen Atlas-Trennlinien wurden geprüft. Zellen wurden ohne Streckung
oder Farbänderung auf transparente 704×704-Rahmen verteilt; die Originalpixel
bleiben erhalten. Denti stellt in allen vier Motiven dieselbe Figur dar.

## Vollständiger Prompt

```text
Use case: style-transfer. Asset type: transparent game UI illustration atlas for Denti: Divine Dentistry.
Create one cohesive 2 by 2 atlas containing FOUR separate polished painted game UI motifs. Use the supplied tooth mascot as exact identity reference and the supplied glossy dental icons as the rendering style reference. This is a new derivative asset: preserve the original reference files.
Layout: square 2048x2048 image, four equally sized 1024x1024 cells, no gutters crossing a cell, generous fully transparent margin 12% on every cell edge. Each motif must occupy the SAME approximate bounding box and same scale. No element may touch another cell. True transparent background around every motif, NOT a checkerboard or a colored panel.
Top left EASY motif: the SAME cute ivory molar Denti, friendly face and small gold crown, standing unarmed, with a calm mint enamel sparkle and a simple smooth gold crescent behind.
Top right NORMAL motif: the SAME Denti silhouette, size, crown and face, unarmed, alert happy expression, with a few amber sugar fragments and two small coral danger sparks around the lower sides.
Bottom left HARD motif: the SAME Denti silhouette, size, crown and face, unarmed, determined friendly expression, surrounded by a bolder sweeping coral/amber broken sugar ring, three sharp but rounded candy shards. Keep the face large, clear and fully readable.
Bottom right HELL motif: the SAME Denti silhouette, size, crown and face, unarmed, determined expression, framed by a stronger dark plum and coral magical flame sweep with a few amber enamel sparks. Charming cartoon danger, no horror and no gore.
The differences communicate increasing danger around the same hero, NOT four classes or four boss characters. Do not equip armor or weapons. Preserve two root legs, two little arms, recognizable black oval eyes, pink cheeks, and the molar body. Glossy ivory enamel and warm gold painted highlights, soft volume, crisp burgundy outlines, strong simple silhouettes. Match a high quality cute fantasy 2D dental roguelite. Not flat vector art, not pixel art. Detail must remain clean when the whole cell is reduced to 130px. Keep silhouettes centered and visually weighted alike.
No letters, labels, names, numbers, card frames, buttons, UI text, watermark, landscape, ground plane, props behind the whole atlas, or baked rectangular shadow. Art only on real transparency.
```
