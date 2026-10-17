extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _label(parent: Node, message: String, at: Vector2, size: int = 22) -> void:
	var label := Label.new()
	label.text = message
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("fff1ce"))
	label.add_theme_color_override("font_shadow_color", Color("302a3b"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)

func _drop(parent: Node2D, kind: StringName, at: Vector2, factor: float = 1.0) -> Loot:
	var drop: Loot = load("res://scenes/game/loot.tscn").instantiate()
	drop.configure(kind, 1, null)
	drop.position = at
	drop.scale = Vector2.ONE * factor
	drop.process_mode = Node.PROCESS_MODE_DISABLED
	parent.add_child(drop)
	return drop

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Loot art preview requires native rendering")
		quit(1)
		return
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1000, 800)
	root.content_scale_size = root.size
	var scene := Node2D.new()
	root.add_child(scene)
	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = DentiArena.FLOOR
	floor_sprite.centered = false
	floor_sprite.scale = Vector2(root.size) / floor_sprite.texture.get_size()
	scene.add_child(floor_sprite)
	_label(scene, "DENTI · XP UND GOLD", Vector2(35, 22), 28)
	for index in 2:
		var x := 90 + index * 470
		_label(scene, "XP · Schmelzkristall" if index == 0 else "Gold · Zahnprägung", Vector2(x, 85), 24)
		_drop(scene, &"xp" if index == 0 else &"coin", Vector2(x + 90, 175), 4)
		_drop(scene, &"xp" if index == 0 else &"coin", Vector2(x + 270, 175))
		_label(scene, "4×", Vector2(x + 75, 250), 18)
		_label(scene, "Spielgröße", Vector2(x + 225, 250), 18)
	_label(scene, "150 gemischte Drops · normale Spielgröße", Vector2(35, 315), 22)
	var random := RandomNumberGenerator.new()
	random.seed = 92247
	for index in 150:
		var at := Vector2(48 + index % 15 * 64, 380 + index / 15 * 36)
		at += Vector2(random.randf_range(-17, 17), random.randf_range(-10, 10))
		_drop(scene, &"xp" if index % 3 != 0 else &"coin", at)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/loot_art_preview.png")
	scene.free()
	# Isolated alternating XP/coin rendering: no backdrop, labels or other art.
	var dense := Node2D.new()
	root.add_child(dense)
	for index in 200:
		_drop(dense, &"xp" if index % 2 == 0 else &"coin", Vector2(40 + index % 20 * 48, 50 + index / 20 * 60))
	for frame in 8:
		await process_frame
		await RenderingServer.frame_post_draw
	print("200 alternating XP/gold drops: ", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), " draw calls, ", dense.get_child_count(), " loot sprites")
	dense.free()
	quit()
