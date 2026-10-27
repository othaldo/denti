# Gemalte elementare Einschläge

Erzeugt am 27.10.2026 mit dem eingebauten Imagegen-Werkzeug,
`transparent_background: true`, ohne CLI. Stilreferenz:
`assets/ui/element_icons_atlas.png`. Originalvorlagen bleiben unverändert.

Spielasset: `assets/vfx/element_hit_splats.png`, 1536×1024 RGBA mit echtem Alpha.
Die generierte Datei wurde pixelidentisch übernommen; der Import erzeugt Mipmaps.
Zwei Reihen mit drei 512×512-Zellen: Feuer, Eis, Gift / Blutung, Elektro, Wasser.
Die sechs Profile unter `data/vfx/impacts/` wählen die Zellen aus.

Der Atlas enthält die gemalten Einschlagsmotive. Expansion, gerichteter Auswurf,
radiale Explosion, Flugbahnen, Aufsteigen, Drehung, Flackern und Ausblenden werden
vom gemeinsamen Renderer animiert. Flugpartikel nutzen zusätzlich die bereits
vorbereiteten elementaren Projektiltexturen; es entstehen keine Texturen pro Treffer.

[Native Blutungsanimation](../screenshots/element_impacts/bleed/animation.gif)
zeigt tatsächliche Projektilkollision, Explosion und einen animierten Speerstoß.
[Alle sechs Elemente](../screenshots/element_impacts/impact.png) verwenden denselben
Kampf- und Zeichenpfad.

## Verwendeter Prompt

Use case: stylized-concept. Asset type: transparent painted world VFX sprite atlas for a colorful 2D top-down cartoon dental arena game. Generate ONE NEW 1536 x 1024 PNG sheet, THREE equal square columns by TWO equal square rows, six different isolated ground-impact splatter sprites, each comfortably centered in its 512px square with at least 45px transparent safety gutter on every side. The reference is STYLE ONLY: rich hand-painted cartoon volume, crisp bold dark-plum colored contour, glossy highlights and strong saturated colors. These are effects ON THE ARENA FLOOR, NOT UI icons, emblems, medallions, characters, floating gems, bottles or tools. Ground plane seen from overhead with a slight three-quarter look, roughly radial organic footprint. Exact row-major order: TOP LEFT FIRE: an irregular charred orange-red impact scorch splat with a bright molten center and several small flames licking from the edges; not a fireball or round hazard ring. TOP MIDDLE ICE: a radial cracked pale-cyan frozen splash with a handful of sharp turquoise crystalline shards embedded around its center, dark blue fracture details, not a snowflake emblem. TOP RIGHT POISON: one irregular vivid green glossy slime puddle splashed outward, a few bulging toxic bubbles and tiny scattered slime droplets, no skull or face. BOTTOM LEFT BLEED: a stylized deep ruby-red glossy blood-like splatter puddle, broad irregular central pool with sharp outward spray streaks and a few distinct red droplets; clean cartoon symbolic liquid, no flesh, injury or gore. BOTTOM MIDDLE ELECTRIC: a compact golden-cyan branching electrical ground discharge, six jagged short radiating arc branches from a small bright core, broken organic shape, no circular ring or lightning-bolt badge. BOTTOM RIGHT WATER: a glossy blue-turquoise puddle bursting outward in a low splash crown with white foam and a few small detached water drops, clean readable watery material. Each cell contains ONE complete effect footprint, roughly comparable visible diameter, no pieces on adjacent cells. Transparent alpha outside all six silhouettes, including transparent gaps between separate drops. No solid background, no checkerboard painting, no global glow haze, no shadows outside the effect, no floor tile, no labels, no text, no numbers, no frames. Strong simple silhouettes that remain clear at 50-150 screen pixels. Keep all fragments inside their cell.
