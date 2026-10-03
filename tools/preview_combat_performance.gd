extends SceneTree

class PreviousVisual extends Node2D:
	var data: WeaponData
	var kind: StringName = &""
	func _draw() -> void:
		if kind != &"":
			if kind == &"chest":
				draw_rect(Rect2(-13, -9, 26, 20), Color(0.33, 0.16, 0.30))
				draw_rect(Rect2(-11, -7, 22, 16), Color(0.96, 0.69, 0.28))
				draw_rect(Rect2(-11, -1, 22, 3), Color(0.52, 0.20, 0.34))
				draw_circle(Vector2.ZERO, 3, Color(1, 0.95, 0.65))
			else:
				draw_circle(Vector2.ZERO, 8, Color(0.2, 0.16, 0.2))
				draw_circle(Vector2.ZERO, 6, Color(0.35, 0.84, 0.96) if kind == &"xp" else Color(1, 0.79, 0.29))
				draw_circle(Vector2(-2, -2), 2, Color.WHITE)
			return
		if data.projectile_shape == &"rocket":
			draw_line(Vector2(-16, 0), Vector2(6, 0), Color(0.98, 0.94, 0.82), 10)
			draw_colored_polygon(PackedVector2Array([Vector2(17, 0), Vector2(5, 7), Vector2(5, -7)]), data.projectile_color)
			draw_line(Vector2(-20, 0), Vector2(-34, 0), Color(1, 0.78, 0.28, 0.65), 5)
			return
		var radius := 11.0 if data.splash_at_tier(1) > 0 or data.pierce_at_tier(1) > 0 else 7.0
		for index in 3:
			draw_circle(Vector2(-float(index + 1) * 8, 0), radius * (0.75 - index * 0.16), Color(data.projectile_color, 0.34 - index * 0.08))
		draw_circle(Vector2.ZERO, radius, Color(0.11, 0.24, 0.27, 0.42))
		draw_circle(Vector2.ZERO, radius, data.projectile_color)
		draw_circle(Vector2(-2.5, -2.5), radius * 0.32, Color.WHITE)

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://preview_combat_performance.json"
	session.resume_requested = false
	DisplayServer.window_set_size(Vector2i(1280, 720))
	root.content_scale_size = Vector2i(1280, 720)
	var scene := Node2D.new()
	root.add_child(scene)
	current_scene = scene
	var background := ColorRect.new()
	background.color = Color("252c39")
	background.size = Vector2(1280, 720)
	scene.add_child(background)
	_label(scene, "Bisherige Zeichnung", Vector2(200, 30))
	_label(scene, "Gemeinsame Sprites / Atlanten", Vector2(670, 30))
	var y := 120
	for id in [&"magic_toothbrush", &"water_jet", &"fluoride_rocket"]:
		var data := WeaponCatalog.by_id(id)
		var previous := PreviousVisual.new()
		previous.data = data
		previous.position = Vector2(410, y)
		previous.scale = Vector2.ONE * 4
		scene.add_child(previous)
		var shot := WeaponProjectile.new()
		scene.add_child(shot)
		shot.launch(Vector2(930, y), Vector2.RIGHT, 1, data)
		shot.set_physics_process(false)
		shot.scale = Vector2.ONE * 4
		_label(scene, data.display_name, Vector2(25, y - 15))
		y += 120
	for kind in [&"xp", &"coin", &"chest"]:
		var x := 250 if kind == &"xp" else 400 if kind == &"coin" else 550
		var previous := PreviousVisual.new()
		previous.kind = kind
		previous.position = Vector2(x, 565)
		previous.scale = Vector2.ONE * 4
		scene.add_child(previous)
		var sprite := Sprite2D.new()
		sprite.texture = CombatSpriteTextures.loot(kind)
		sprite.scale = Vector2.ONE * 4 / CombatSpriteTextures.RESOLUTION
		sprite.position = Vector2(x + 520, 565)
		scene.add_child(sprite)
	_label(scene, "Gleiche Formen und Größen, vierfach vergrößert", Vector2(220, 650))
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/combat_sprite_comparison.png")
	scene.free()
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	root.content_scale_size = Vector2i(1040, 600)
	menu._show_options()
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/performance_options_landscape.png")
	menu.free()
	quit()

func _label(parent: Node, message: String, at: Vector2) -> void:
	var label := Label.new()
	label.text = message
	label.position = at
	label.add_theme_font_size_override("font_size", 22)
	parent.add_child(label)
