# Weapon effects and attack warnings

**Update 20.10.2026:** Charge/Lane warnings now use fixed end caps and a tiled
middle; the Count's fans/ring share the same atlas and animated inner light.
See [current implementation, measurements and validation](TEXTURED_WARNINGS.md).
The following records the preceding painted-decal revision. Its texture size,
appearance and performance figures are historical, not the current path.

The remaining simple weapon beams, cone polygons, contact trails and enemy
warning lanes now use `AttackEffects`. Damage, aim, attack timing, wall clamping,
projectile patterns and save data are unchanged.

- Mirror: painted golden light flow, with impact bloom.
- UV lamp: painted violet plasma flow following its full existing beam segment.
- Fluoride sprayer: painted mint spray clipped to its configured circular sector.
- Contact attacks: curved painted afterimage or small working-head flash.
- Evolution, item and relic links: textured energy threads/streams.
- Charge, projectile wall and orb warnings: translucent disturbed-ground decals,
  without parallel rails. Curved cracks pulse before the attack. Red/orange and
  green still distinguish the relevant enemy effects.
- Aimed/radial fire: restrained directional wisps, with a clockwise warning timer.

The first lane revision still resembled a runway. It was replaced after visual
feedback; no continuous side rails or center aiming line remain on charges.

## Assets and runtime cost

`assets/vfx/attack_art_source.png` and `assets/vfx/charge_ground_source.png` were
generated with the built-in imagegen tool. The source images are retained.
`python tools/bake_attack_effects.py` crops, aligns, packs and prepares them into
`assets/vfx/attack_effects.png`: 1024 × 1680 RGBA, about 6.56 MiB uncompressed.
The PNG is about 413 KiB. Source sheets are never loaded by combat code.

The atlas contains four flow frames at 12 FPS, 65 prepared timer steps and the
existing circular danger mask. Timer and lane use the same underlying texture,
including in the shared enemy warning renderer. No shader, emitter, image
generation, resource loading or extra scene node is added during attacks.
Spray points and UVs are prepared when the weapon is equipped, and a tiny menu
viewport exercises the texture/sector draw paths before combat.

The decal is constrained to the existing warning width, with a soft inside fade.
The outer decorative glow of player beams is not additional damage range.

## Validation

`tests/attack_effects.gd` checks frame/gutter isolation, decal bounds and opacity,
timer direction/completion, transformed emission and target endpoints, and the
prepared spray sector. The relevant weapon, item, relic, evolution, enemy and
warmup suites pass (22/22 in the final related-suite run).

Native OpenGL comparison, `tools/benchmark_warning_lanes.gd -- --verify`: local
and shared rendering match at three warning phases under identity, skewed and
mirrored transforms (nine comparisons, mean difference 0).

The same tool's isolated 60-warning stress benchmark on an RTX 4070 measured:

| Rendering | Draw calls | CPU draw recording | Frame wall time |
| --- | ---: | ---: | ---: |
| Historical polygon + edge + timer baseline | 120 | 0.50–0.51 ms | 1.22–1.25 ms |
| Current painted decal + prepared timer | 1 | 0.20–0.21 ms | 0.46–0.48 ms |

This measures only the warning fixture with VSync disabled, not a full combat
scene or the integrated-GPU browser. It does not establish a browser FPS gain.
`--verify` compares the two current rendering paths; it intentionally no longer
requires the new artwork to equal the historical polygon pixels.

`tools/preview_attack_effects.gd` renders actual `WeaponInstance` and `Enemy`
objects into `docs/screenshots/attack_effects.png` and captures animation frames
under `.godot/attack_frames/`. The focused floor preview is
`docs/screenshots/charge_warning.gif`.

## Simultaneous warning readability

The single-enemy preview did not reveal an opacity problem: twenty crossing
projectile-wall warnings blended into an almost opaque green patch. The density
fixture now exercises 10 mixed warnings, 20 mixed warnings, 20 crossing projectile
walls, and 20 mixed warnings including two boss charges. Every fixture also has
40 actual enemy projectiles and 24 actual player projectile sprites, at normal
1280 × 720 game scale, using the real player, enemy index and camera.
The fixtures are scripted visual stress scenes with combat frozen; they do not
claim to be recorded uninterrupted gameplay.

`WarningVisualDensity` now estimates overlapping strips using a conservative
32 px world grid. Only the painted fill fades where several strips overlap;
isolated warnings keep full opacity. Eight short sections interpolate the fade
along each strip so a crowded intersection does not dim its entire length.
Timers and impact boundaries remain at their ordinary visibility, above the
painted fills. Boss fills are drawn after ordinary fills and retain a stronger
minimum visibility so major charges do not disappear in smaller attacks.
The active-warning list is reused, rather than rescanning the whole horde for
each drawing pass. Enemies, attacks, warning durations and collision geometry are
unchanged; no warning or enemy is dropped to reduce visual density.

The small grid refreshes at most every 100 ms with a stable warning count, and
immediately after membership/count changes. There is no image upload, emitter,
offscreen viewport or fullscreen shader for this adjustment. Prepared textured
quads share the existing atlas. Grouping fills before timers avoids a render
batch change for every enemy.

Validation: 15 related automated suites pass, including the new opacity and
isolated-warning regression test. Native `--verify-density` compares the sliced
and ordinary rendering paths at three phases under identity, skewed and mirrored
transforms; the largest mean pixel difference was 0.000091 (threshold 0.002).

On the same RTX 4070 desktop, an isolated fixture of 20 coincident warning strips
measured 1 draw call without overlap adjustment and 2 with it. CPU draw recording
was 0.14–0.16 ms versus 0.25–0.26 ms. The grid refresh separately measured about
0.38 ms / 0.76 ms / 2.22 ms for 10 / 20 / 60 coincident warnings, refreshed at
most ten times per second with stable count. These are desktop fixture numbers,
not browser FPS or integrated-GPU measurements. Full-scene draw-call totals also
include all the enemy/status/player/projectile art.

Reproduction:

```text
godot --path . --script tools/preview_warning_density.gd -- --tag=current
godot --path . --script tools/benchmark_warning_lanes.gd -- --density
godot --path . --script tools/benchmark_warning_lanes.gd -- --verify-density
godot --headless --path . --script tests/warning_visual_density.gd -- --benchmark
```

Screenshots: `docs/screenshots/warning_density_10_mixed.png`,
`warning_density_20_mixed.png`, `warning_density_20_crossing.png` and
`warning_density_20_boss_mix.png`. The animated comparison at game scale is
`docs/screenshots/warning_density_20.gif`.

## Generation prompts

Both prompts used the built-in tool with `transparent_background=true`.

### Painted weapon sheet

Reference: `assets/vfx/projectile_art_source.png`, style reference only.

> Use case: stylized-concept. Create ONE production sprite atlas for magical weapon VFX in the 2D painted cartoon dental arena game Denti. Input image 1 is STYLE REFERENCE ONLY: glossy hand-painted colors, warm outlines and highlights. Do not copy its projectiles, weapons or tooth emblems. True transparent background, no floor, no labels, no letters, no icons, no runes, no teeth, no objects, no UI. Atlas exactly 3 equal columns and 2 equal rows, landscape 1536x1024; every effect fully inside its 512x512 cell with clear transparent margin, no overlap. Each is an organic painterly visual effect, horizontal LEFT TO RIGHT, centered around y=256 in each cell. These are extended energy FLOWS, not projectiles or missiles, and not thin straight neon lines. Top left: rich golden-white holy light stream, long tapering flowing flame-like ribbons braided around a bright creamy core, soft amber glow, little golden motes, width about 400 and height 130. Top middle: violet lavender ultraviolet plasma stream with broad glowing white core and swirling purple wisps, depth and thick painterly highlights, width400 height150. Top right: mint-green foamy spray jet, narrow emission at left x60,y256 spreading into an airy triangular fan of translucent mist, glossy fluid ribbons and many small round droplets toward right x440, fanheight230, no nozzle. Bottom left: cyan electrical chain stream, winding forked lightning arcs with little white sparks and soft turquoise glow, width400 height140. Bottom middle: ivory-gold sword-swing crescent afterimage sweeping from left to right, elegant curved brushstroke with warm amber edge and fading small sparks, width400 height150. Bottom right: luminous ivory-white impact splash, radial organic burst of paint-like wisps and softly pointed light rays, no outlined symbol, centered and about250 diameter. Keep backgrounds genuinely transparent, not black, and isolate each effect. Painterly game-ready VFX with visible volume and distinct silhouettes.

### Disturbed ground warning

> Use case: stylized-concept. Asset: one top-down 2D game ground warning decal for an enemy about to CHARGE, for a glossy painted cartoon fantasy arena. Make a wide horizontal patch of ominous crimson pressure building INSIDE THE FLOOR: branching dark reddish cracks with molten orange-red light glowing up through them, small irregular wisps of low red dust hugging the ground, subtle curved transverse pressure ripples across the patch, a few small scattered stone chips. It is a flattened patch of disturbed ground, viewed straight from above, NOT a projectile, NOT a fireball, NOT a comet, NOT a flight trail, NOT a runway, NOT a road. NO straight parallel edge lines, NO rails, NO side borders, NO lane markings, NO arrows, NO icons, NO runes, NO text, NO character, NO weapon. Composition: landscape 1536x1024, one isolated patch centered around image y=512, spans from x110 to1420 and approximately y320 to700, fairly uniform broad width along most of its length with irregular softly fading brushy outer edges and rounded irregular ends; no narrow tail and no bulbous head. Painted mobile-game VFX art, rich warm cartoon brushwork and glowing cracks, restrained translucent red ambient fill between cracks, transparent gaps so floor beneath remains visible. Fully transparent background everywhere outside the ground decal, generous transparent margin, no opaque floor, no black background, no perspective.
