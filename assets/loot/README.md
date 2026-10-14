# Upgrade capsule

Generated with the built-in image_gen tool. `upgrade_capsule.png` is the original transparent source; its Godot import limits the runtime texture to 128 pixels and enables mipmaps. HUD and chest drops share `CombatSpriteTextures.UPGRADE_CAPSULE`; drops retain a 32 × 32 world-space footprint. Golden rewards retain their existing tint. The old chest atlas region remains for prepared-atlas compatibility.

Final generation prompt (reference: `assets/items/item_icons_atlas.png`, style only):

> Create ONE production game inventory/drop icon for Denti Divine Dentistry. Reference image is STYLE REFERENCE ONLY: match glossy hand-painted cartoon dental items, dark plum outline, ivory highlights, turquoise and warm gold. Single divine UPGRADE CAPSULE: chunky rounded upright glass ampoule containing luminous turquoise liquid, large simple ivory UP ARROW emblem on front, substantial golden cap, tiny gold halo hovering above cap, two small sparkle accents. Slight 3/4 perspective, compact broad silhouette, readable at 22-32 pixels, arrow is dominant readable shape. Capsule fills 85% of square canvas, centered. Genuine transparent background, clean alpha edges, no floor, no cast shadow backdrop, no text, no labels, no frame, no collage. Do not reproduce the reference atlas or its objects.
