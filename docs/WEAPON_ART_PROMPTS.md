# Prompts zur Waffenüberarbeitung

Verwendeter Modus: eingebautes Imagegen, transparente PNGs. Kein CLI/API-Fallback. Die generierten Ausgangsbilder sind unter `assets/weapons/reference/` erhalten. `tools/pack_weapon_art.py` schneidet die gemalten Objekte aus und packt Icons und Animationsteile; es zeichnet keine Ersatzgrafiken.

## Waffen und Schleuderteile

Referenzen: `assets/weapons/weapon_icons_expansion.png`, `crown_launcher.png`, `mouthwash_mortar.png`.

```text
Use case: stylized-concept
Asset type: transparent painted weapon sprite atlas for Denti, a 2D cartoon dental arena game.
Input images: existing weapon expansion atlas and crown launcher and mouthwash mortar are STYLE and recognizable material references.
Primary request: create cleaner replacement weapon sprites matching the glossy hand painted ivory ceramic, turquoise rubber, gold trim, dark warm brown outlines. Strong simple silhouettes readable at 60 pixels, coherent 2D side view, limited ornament, no gradients outside objects. Genuine transparent background. No text, no grid lines, no shadows outside objects.
Composition: square 1536x1536 atlas, exactly THREE equal columns and THREE equal rows, each cell 512x512. Center each complete weapon in its cell with at least 45 pixels padding. All gun muzzles point diagonally up-right around 25 degrees. Consistent painted lighting from upper left.
ROW 1 left: crown launcher, simple ivory/turquoise short cannon, TWO readable red grips beneath it, a single small golden dental crown sitting clearly inside its open launch cup; no crossbow struts, no rear wheel, no floating crown, no rococo.
ROW 1 center: mouthwash mortar, heavy short wide mortar nozzle and ONE clear mint-green mouthwash reservoir behind it, TWO simple red grips beneath. No charms, no leaf logo, no spray or droplets, no ribbon.
ROW 1 right: water jet, slim pistol with ONE turquoise grip, blue transparent water reservoir at rear, a long bent silver dental nozzle ending up-right. NO water outside nozzle, no droplets. Keep it distinctly slimmer than mortar.
ROW 2 left: fluoride sprayer, compact ONE-grip dental spray gun with small GREEN square fluid bottle on top and short gold-rim nozzle. No liquid or mist outside gun, no second grip.
ROW 2 center: water turbine, TWO-grip ivory/turquoise gun with one prominent circular BLUE transparent turbine chamber and simple silver nozzle up-right, no tank on top. No water outside gun, no excess buttons.
ROW 2 right: amalgam slingshot, symmetric UPRIGHT ivory/gold Y-shaped fork with turquoise lower grip, TWO dark rubber elastic strands from the fork tips to a central dark leather pouch containing a silver metal pellet. Fork tips near normalized (0.23,0.20) and (0.77,0.20); pouch near (0.50,0.38), hand grip (0.50,0.78). Make the pouch visibly distinct from an ornamental medal, no tooth emblem on pouch.
ROW 3 left: EXACT SAME slingshot fork and turquoise grip as directly above-right, upright, same scale, matching fork tips and hand grip positions in its own cell, but EMPTY FORK: completely remove both elastic strands, leather pouch and silver pellet. This is the static body animation layer.
ROW 3 center: ONLY the isolated leather pouch holding silver pellet from the complete slingshot above, centered in cell; pouch about 105 pixels wide, 75 high. No bands, no handle. This is a separate animation layer.
ROW 3 right: leave entirely transparent/empty.
Constraints: clean alpha cutouts, no environmental backgrounds, no lettering, no labels, no sparkles, no baked attack VFX. Preserve dental toy weapon charm. Layer cells are parts of the SAME slingshot; do not invent extra weapons.
```

## Separate Arbeitsköpfe

Referenz: `assets/weapons/weapon_icons_expansion.png`.

```text
Use case: stylized-concept
Asset type: transparent 2D dental game weapon animation PARTS atlas.
Primary request: paint exactly FOUR separate sprites in a 2 by 2 equal-cell square grid, warm outlined glossy ivory ceramic/turquoise/gold style matching the reference atlas. Transparent background, no labels or grid. Each cell 512 square, 1024 square image total. These are animation parts, NOT complete weapons.
TOP LEFT: BODY ONLY of the cavity grinder: compact two-grip ivory/turquoise powered dental tool, gold accents, one red button. View pointing diagonally up-right 25 degrees. Two plain handles under a short oval motor housing. At upper right a small gray axle ending at normalized cell position (0.78,0.30). NO grinding disc, NO saw blade, no teeth wheel; axle ends ready for separately composited working head.
TOP RIGHT: BODY ONLY of prophylaxis polisher: ONE slender turquoise/ivory handle angled diagonally up-right ending in a silver curved right angle neck. Gold trim and restrained red accent. Silver axle/stub terminates at normalized cell position (0.78,0.25). NO purple rubber cup and NO brush head: those will be separately composited. Do not make gun with trigger or reservoir.
BOTTOM LEFT: ONLY isolated circular grinder working face, centered in cell, diameter about 230 pixels. Face seen directly front-on as a true circle, silver ridged dental grinding burr with small golden center hub and six simple radial dark grooves. Flat circular perimeter, not gear teeth, no shaft, handle or housing, no backplate. Must rotate cleanly in 2D with stable circular silhouette. Warm brown outline, painted metal shading subtle.
BOTTOM RIGHT: ONLY isolated circular PURPLE rubber polishing cup working face, centered in cell, diameter about 230 pixels. Front-on perfect circle, plum rim and six restrained lighter lavender curved internal ribs, dark recessed center. No axle, no housing, no handle, no side cylinder. Must rotate cleanly with stable circular silhouette.
Constraints: keep parts disjoint with generous transparent padding in their cells. No shadows outside shapes, no sparkles, no text. Exactly two body cells and two isolated circular rotor cells. Strong clean silhouettes readable at sixty pixels. Match previous glossy cartoon dental equipment, NOT realistic product photographs.
```

## Korrektur der Krone

Referenz: erste generierte Waffenübersicht. Das korrigierte Ergebnis ist `assets/weapons/reference/weapon_refinement_generated.png`.

```text
Use case: precise-object-edit
Asset type: existing transparent 3x3 dental weapon sprite atlas.
Primary request: change ONLY the object INSIDE the muzzle cup of the TOP LEFT weapon. It currently contains a tiny golden tooth, but this weapon is a CROWN LAUNCHER. Replace that golden tooth with a clear small GOLDEN ROYAL CROWN with three visible triangular prongs, a thick golden circular band, tiny turquoise gem. The crown sits partly inside the muzzle cup but its distinctive three prongs are visible. Small, readable, upright crown, not a tooth and not an insignia. Keep the gun body, two grips, cup geometry, dimensions, colors, all other seven sprites, empty cell and exact cell placements UNCHANGED. Preserve true alpha transparency. Do not add any text, effects or other decoration.
```
