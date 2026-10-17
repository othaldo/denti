extends SceneTree

class Samples extends Node2D:
	var modern := false
	func _draw() -> void:
		var water := Vector2(180, 180)
		var burst := Vector2(440, 180)
		var warning := Vector2(740, 180)
		if modern:
			GroundEffects.draw(self, GroundEffects.Shape.POOL, water, 72, Color.WHITE)
			GroundEffects.draw(self, GroundEffects.Shape.RIPPLE, burst, 86, Color(1, 0.83, 0.35))
			GroundEffects.draw(self, GroundEffects.Shape.DANGER, warning, 100, Color(1, 0.34, 0.29))
		else:
			draw_circle(water, 72, Color(0.18, 0.79, 0.87, 0.14))
			CombatDrawCache.arc(self, water, 72, 0, TAU, 32, Color(0.28, 0.94, 1, 0.5), 3)
			CombatDrawCache.arc(self, burst, 86, 0, TAU, 36, Color(1, 0.83, 0.35), 4)
			CombatDrawCache.circle(self, warning, 100, Color(0.95, 0.36, 0.28, 0.13))
			CombatDrawCache.arc(self, warning, 100, 0, TAU, 64, Color(0.73, 0.20, 0.19, 0.85), 4)
		CombatDrawCache.arc(self, warning, 92, -PI / 2, PI * 0.8, 64, Color(1, 0.72, 0.27), 4)

class DensePools extends Node2D:
	var modern := false
	func _draw() -> void:
		for index in 60:
			var at := Vector2(60 + index % 10 * 90, 70 + index / 10 * 105)
			if modern:
				GroundEffects.draw(self, GroundEffects.Shape.POOL, at, 40, Color.WHITE)
			else:
				draw_circle(at, 40, Color(0.18, 0.79, 0.87, 0.14))
				CombatDrawCache.arc(self, at, 40, 0, TAU, 32, Color(0.28, 0.94, 1, 0.5), 3)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1000, 750)
	root.content_scale_size = Vector2i(1000, 750)
	var scene := Node2D.new()
	root.add_child(scene)
	var backdrop := Sprite2D.new()
	backdrop.texture = DentiArena.FLOOR
	backdrop.centered = false
	backdrop.scale = Vector2(1000, 750) / backdrop.texture.get_size()
	scene.add_child(backdrop)
	for row in 2:
		var samples := Samples.new()
		samples.modern = row == 1
		samples.position.y = row * 350
		scene.add_child(samples)
		_label(scene, "BISHER" if row == 0 else "NEU · VORBEREITETE TEXTUREN", Vector2(50, 25 + row * 350))
		for index in 3:
			_label(scene, ["Spülpfütze", "Heiliger Impuls", "Gegnerische Warnfläche"][index], Vector2([105, 360, 625][index], 295 + row * 350), 18)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/ground_effects_comparison.png")
	scene.free()
	if "--benchmark" in OS.get_cmdline_user_args():
		for modern in [false, true]:
			var pools := DensePools.new()
			pools.modern = modern
			root.add_child(pools)
			for frame in 8:
				await process_frame
				await RenderingServer.frame_post_draw
			print("60 pools, textured=", modern, ", draw calls=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
			pools.free()
	quit()

func _label(parent: Node, text: String, at: Vector2, font_size: int = 22) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("fff1ce"))
	label.add_theme_color_override("font_shadow_color", Color("302a3b"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)
