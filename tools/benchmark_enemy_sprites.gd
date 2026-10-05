extends SceneTree

# Native pixel oracle: render the same frozen actors through the original
# separate source textures and shared atlas cells. Headless cannot validate GPU output.
const TYPES: Array[EnemyData] = [WaveController.PLAQUE, WaveController.BACTERIA, WaveController.SUGAR, WaveController.ACID_SPITTER, WaveController.POISON_GERM, WaveController.GUM_BITER]
const SOURCES := ["plaque", "bacteria", "sugar", "acid_spitter", "poison_germ", "gum_biter"]

func _initialize() -> void:
	call_deferred("_run")

func _settle() -> void:
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run this pixel benchmark with a native renderer")
		quit(1)
		return
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	paused = true
	var view := SubViewport.new()
	view.size = Vector2i(512, 400)
	view.world_2d = World2D.new()
	view.disable_3d = true
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var index := EnemySpatialIndex.new()
	view.add_child(index)
	var enemies: Array[Enemy] = []
	var textures: Array[Texture2D] = []
	var originals: Array[Texture2D] = []
	for number in 110:
		var enemy: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
		enemy.configure(TYPES[number % TYPES.size()], null, 17)
		enemy.position = Vector2(35 + number % 11 * 40, 35 + number / 11 * 35)
		index.add_child(enemy)
		enemy.inflicted_statuses.clear()
		enemy.queue_redraw()
		enemy.set_process(false)
		enemy.set_simulation_enabled(false)
		enemies.append(enemy)
		textures.append(enemy.sprite.texture)
		originals.append(load("res://assets/enemies/%s.png" % SOURCES[number % SOURCES.size()]))
	index.set_process(false)
	index.set_physics_process(false)
	var shown := Sprite2D.new()
	shown.texture = view.get_texture()
	shown.centered = false
	root.add_child(shown)
	var failed := false
	for scenario in 3:
		index.transform = Transform2D(0, Vector2.ONE, 0, Vector2.ZERO) if scenario == 0 else Transform2D(0.035, Vector2(0.94, 0.90), 0.015, Vector2(7, 5))
		index.modulate = Color.WHITE if scenario < 2 else Color(0.9, 1, 0.8, 0.75)
		for number in enemies.size():
			var enemy := enemies[number]
			enemy.rotation = 0.12 * sin(number * 0.7) if scenario > 0 else 0
			enemy.scale = Vector2(0.8 + number % 3 * 0.15, 1.1) if scenario > 0 else Vector2.ONE
			enemy.animation_time = number * 0.32
			enemy._process(0.03)
			enemy.sprite.flip_h = number % 2 == 0
			enemy.sprite.flip_v = scenario > 0 and number % 7 == 0
			enemy.sprite.offset = Vector2(70, -60) if scenario > 0 and number % 5 == 0 else Vector2.ZERO
			enemy.modulate = Color(1.6, 1.3, 1.1, 0.65) if scenario > 0 and number % 3 == 0 else Color.WHITE
			enemy.self_modulate = Color(0.2, 0.3, 0.4, 0.5) # Parent self_modulate must not tint its child sprite.
			enemy.sprite.self_modulate = Color(1.0, 0.9, 0.8, 0.8) if scenario == 2 else Color.WHITE
		index.shadow_batch.update()
		for number in enemies.size():
			enemies[number].sprite.texture = originals[number]
		await _settle()
		var before := view.get_texture().get_image()
		before.convert(Image.FORMAT_RGBA8)
		var reference_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		for number in enemies.size():
			enemies[number].sprite.texture = textures[number]
		await _settle()
		var after := view.get_texture().get_image()
		after.convert(Image.FORMAT_RGBA8)
		var batched_calls := Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
		var first := before.get_data()
		var second := after.get_data()
		var total := 0
		var worst := 0
		for byte in first.size():
			var difference := absi(int(first[byte]) - int(second[byte]))
			total += difference
			worst = maxi(worst, difference)
		var average := float(total) / first.size()
		print(JSON.stringify({"scenario": scenario, "enemies": enemies.size(), "reference_draw_calls": reference_calls, "atlas_draw_calls": batched_calls, "mean_byte_difference": average, "max_byte_difference": worst}))
		if average > 0.01 or worst > 8 or batched_calls >= reference_calls:
			failed = true
		if "--capture" in OS.get_cmdline_user_args():
			DirAccess.make_dir_recursive_absolute("res://.godot/enemy-sprite-compare")
			before.save_png("res://.godot/enemy-sprite-compare/reference_%d.png" % scenario)
			after.save_png("res://.godot/enemy-sprite-compare/atlas_%d.png" % scenario)
	shown.free()
	view.free()
	await process_frame
	if failed:
		push_error("Shared-atlas enemy sprites changed pixels beyond the documented GPU precision tolerance or failed to reduce draw calls")
	quit(1 if failed else 0)
