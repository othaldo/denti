extends SceneTree

# Offline rasterization only. Combat uses ordinary atlas quads, no live shader.
const CELL := 384
const RADIUS := 176.0

func _initialize() -> void:
	var image := Image.create(CELL * 3, CELL, false, Image.FORMAT_RGBA8)
	for y in CELL:
		for x in CELL:
			var p := (Vector2(x, y) + Vector2.ONE * 0.5 - Vector2.ONE * CELL * 0.5) / RADIUS
			var r := p.length()
			var angle := p.angle()
			# A restrained liquid edge, contained inside the gameplay radius.
			var edge := 0.955 + 0.022 * sin(angle * 5.0 + 0.8) + 0.014 * sin(angle * 9.0)
			var inside := 1.0 - smoothstep(edge - 0.012, edge + 0.004, r)
			var rim := exp(-pow((r - edge + 0.012) / 0.012, 2.0))
			var ripples := exp(-pow((r - 0.69) / 0.009, 2.0)) * (0.5 + 0.5 * sin(angle * 3.0 + 1.0))
			var sheen := exp(-pow((r - 0.85) / 0.018, 2.0)) * pow(maxf(0.0, cos(angle + 2.1)), 10.0)
			var foam := 0.0
			for bubble: Vector3 in [Vector3(-0.38, -0.43, 0.055), Vector3(-0.25, -0.51, 0.027), Vector3(0.46, 0.28, 0.04)]:
				foam += exp(-pow((p.distance_to(Vector2(bubble.x, bubble.y)) - bubble.z) / 0.007, 2.0)) * 0.35
			var pool_alpha := inside * (0.11 + 0.08 * (1.0 - r) + 0.38 * rim + 0.17 * ripples + 0.4 * sheen + foam)
			var pool_color := Color(0.52, 0.92, 1.0).lerp(Color.WHITE, clampf(rim * 0.35 + sheen + foam, 0.0, 1.0))
			pool_color.a = pool_alpha
			image.set_pixel(x, y, pool_color)
			# Smooth impact ripple: clear center, narrow rim, short inward halo.
			var ripple := exp(-pow((r - 1.0) / 0.014, 2.0)) * 0.8
			ripple += exp(-pow((r - 0.97) / 0.04, 2.0)) * 0.15
			ripple += exp(-pow((r - 0.9) / 0.006, 2.0)) * 0.18
			# Four tiny glints baked into the ripple, without particle nodes.
			for glint: Vector2 in [Vector2(-0.71, -0.71), Vector2(0.71, 0.71), Vector2(-1.0, 0.0), Vector2(1.0, 0.0)]:
				var offset := (p - glint).abs()
				ripple += (1.0 - smoothstep(0.8, 1.0, offset.x / 0.025 + offset.y / 0.065)) * 0.65
			image.set_pixel(x + CELL, y, Color(1, 1, 1, clampf(ripple, 0.0, 1.0)))
			# Danger boundary is exactly r=1; decoration stays inside it.
			var boundary := exp(-pow((r - 1.0) / 0.012, 2.0)) * 0.95
			var field := (1.0 - smoothstep(0.98, 1.0, r)) * (0.055 + 0.07 * r * r)
			var inner := exp(-pow((r - 0.94) / 0.006, 2.0)) * 0.28
			var ticks := pow(maxf(cos(angle * 12.0), 0.0), 24.0) * smoothstep(0.86, 0.9, r) * (1.0 - smoothstep(0.97, 0.98, r)) * 0.35
			image.set_pixel(x + CELL * 2, y, Color(1, 1, 1, clampf(boundary + field + inner + ticks, 0.0, 1.0)))
	var error := image.save_png("res://assets/vfx/ground_effects.png")
	print("Ground effect atlas: ", image.get_size(), ", save result: ", error)
	quit(0 if error == OK else 1)
