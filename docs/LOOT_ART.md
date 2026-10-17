# XP and gold drop sprites

XP now uses a turquoise enamel crystal in the shape of a molar; currency uses a
thick golden coin with a tooth relief. The silhouettes and blue/gold palettes
remain distinct at normal pickup size.

Assets generated with the built-in imagegen tool:

- Original transparent source: `assets/loot/drop_art_source.png`
- Prepared XP sprite: `assets/loot/xp_crystal.png`
- Prepared gold sprite: `assets/loot/gold_tooth_coin.png`
- Native preview: `docs/screenshots/loot_art_preview.png`

The compact sprites are 64 × 64 RGBA with transparent margins and a baked contact
shadow. Their visible height is approximately 18 / 19 game pixels. Each drop
keeps its existing single Sprite2D. The source sheet is not loaded during combat.
Both small sprites are packed into the existing player-projectile/loot atlas;
its dimensions remain 1024 × 308 and its region count remains 13. The menu's
existing texture warmup includes them. There are no extra emitters or callbacks.

Pickup distances, magnet movement, quantities, rewards, wave collection and
save data are unchanged. The upgrade capsule retains its existing artwork.

Rebuild after changing the source artwork:

```text
godot --headless --path . --script tools/bake_loot_art.gd
godot --headless --path . --script tools/bake_combat_textures.gd
godot --headless --editor --path . --import --quit
godot --path . --script tools/preview_loot_art.gd
```

Validation: 7/7 related suites passed (loot pressure, loot spatial index,
wave loot collection, post-wave rewards, combat performance, prepared combat
textures and boss projectile warmup). The native preview includes 150 mixed
drops at normal game size. Its separate isolated test of 200 alternating XP/gold
drops rendered with one draw call on the desktop OpenGL renderer. This is an
isolated rendering measurement, not a full-scene or browser FPS claim.

## Generation prompt

Built-in imagegen, `transparent_background=true`.
Style reference: `assets/vfx/projectile_art_source.png`.

> Use case: stylized-concept. Asset type: ONE game-ready sprite sheet of two collectible ground drops for Denti, a humorous painted cartoon dental arena survivor. Reference image 1 is STYLE REFERENCE ONLY: glossy painterly highlights, dimensional shading, bold warm outlines, strong small-size silhouettes. Do not copy any of its projectiles. Composition: transparent landscape 1536x1024 canvas, TWO EQUAL COLUMNS, one row, each 768x1024. Left sprite centered precisely at (384,512), right sprite centered precisely at (1152,512). Each object fully inside its own cell, isolated, transparent generous margin all around, each about420px tall and380px wide. LEFT: XP collectible, a single upright faceted TURQUOISE ENAMEL CRYSTAL shaped like a little molar tooth with TWO short separated root tips. A compact tooth silhouette carved from luminous cyan blue crystal, deep teal beveled edges, broad simple blue facets and creamy white specular highlight at upper left. No face, no eyes, no gold, no crown. RIGHT: gold currency collectible, ONE thick shiny golden coin tilted very slightly to reveal its ridged amber edge, broad polished raised golden rim, simple ivory-gold embossed MOLAR TOOTH on the coin face. Strong warm dark ochre outer contour and bright yellow-gold broad highlights. No text, no numerals, no letters, no extraneous symbols. The coin must clearly read as a real dimensional collectible coin, not a flat round UI button. Style: charming hand-painted cartoon game items with clean strong outer silhouette, simple broad shading, very readable when reduced to 20-24 pixels. No background, no floor, no pedestal, no UI card, no frame, no labels, no sparkles detached from the objects, no particles, no glow cloud, no long tails, no motion streaks, no projectiles, no weapons. Genuine transparency outside both objects. Light source upper left. Deliver the two finished sprites aligned and fully separated.
