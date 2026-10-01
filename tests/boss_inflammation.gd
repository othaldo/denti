extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _check_frame_art() -> bool:
	var frames := BossInflammationAura.FRAMES
	var source: Image = (frames.get_frame_texture(&"inflamed", 0) as AtlasTexture).atlas.get_image()
	for index in frames.get_frame_count(&"inflamed"):
		var frame := frames.get_frame_texture(&"inflamed", index) as AtlasTexture
		if not frame.filter_clip or frame.get_size() != Vector2(480, 480) or frame.margin.position.x < 15 or frame.margin.position.y < 15:
			_fail("aura frame lacks a stable padded frame or isolated source region")
			return false
		var image := source.get_region(Rect2i(frame.region))
		if image.get_pixel(image.get_width() / 2, image.get_height() / 2).a > 0.1:
			_fail("aura fills its center and can obscure the tooth")
			return false
		for x in image.get_width():
			if image.get_pixel(x, 0).a > 0.1 or image.get_pixel(x, image.get_height() - 1).a > 0.1:
				_fail("aura flame crosses the top/bottom of an animation cell")
				return false
		for y in image.get_height():
			if image.get_pixel(0, y).a > 0.1 or image.get_pixel(image.get_width() - 1, y).a > 0.1:
				_fail("aura flame crosses the side of an animation cell")
				return false
	return true


func _run() -> void:
	if not _check_frame_art():
		return
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_boss_inflammation_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.player.loadout.restore([])
	var colors: Array[Color] = []
	var previous_intensity := 0.0
	var previous_size := 0.0
	var shared_frames: SpriteFrames
	for wave in [5, 10, 15, 20]:
		game._create_enemy(WaveController.boss_for_wave(wave), game.player.global_position + Vector2(500, 0))
		var boss: Enemy = game.boss
		boss.set_physics_process(false)
		boss.is_enraged = true
		boss.sync_inflammation_aura()
		var aura: BossInflammationAura = boss.inflammation_aura
		if aura.visible or colors.has(boss.data.inflammation_color) or boss.data.inflammation_intensity <= previous_intensity or boss.data.inflammation_aura_size <= previous_size:
			_fail("boss rank does not have a distinct stronger aura, or half-health rage activated it")
			return
		colors.append(boss.data.inflammation_color)
		previous_intensity = boss.data.inflammation_intensity
		previous_size = boss.data.inflammation_aura_size
		boss.start_overtime()
		if not aura.visible or not aura.is_playing() or aura.z_index >= boss.sprite.z_index or aura.sprite_frames.get_frame_count(&"inflamed") != 8:
			_fail("inflammation lacks an eight-frame animation behind the boss")
			return
		if shared_frames != null and shared_frames != aura.sprite_frames:
			_fail("bosses duplicate the shared animation resource")
			return
		shared_frames = aura.sprite_frames
		var initial_size := aura.scale.x
		var initial_alpha := aura.modulate.a
		var initial_speed := aura.speed_scale
		boss.advance_overtime(60)
		var capped_size := aura.scale.x
		if capped_size <= initial_size or aura.modulate.a <= initial_alpha or aura.speed_scale <= initial_speed:
			_fail("inflammation does not visually intensify during overtime")
			return
		boss.advance_overtime(600)
		if not is_equal_approx(aura.scale.x, capped_size) or aura.modulate.a > 1.0:
			_fail("visual escalation grows without bounds and can obscure the arena")
			return
		var starting_frame := aura.frame
		await create_timer(0.13).timeout
		if aura.frame == starting_frame:
			_fail("inflammation animation does not advance")
			return
		boss._process(0.0)
		if not aura.position.is_equal_approx(boss.sprite.position + Vector2(0, -boss.data.radius * 0.12)):
			_fail("inflammation does not follow the floating tooth")
			return
		boss.sync_inflammation_aura(0.0, 0.5)
		if aura.modulate.a >= initial_alpha:
			_fail("inflammation does not fade during boss death")
			return
		boss.sync_inflammation_aura(0.0, 1.0)
		if aura.visible or aura.is_playing():
			_fail("inflammation keeps playing after the death animation")
			return
		boss.queue_free()
		await process_frame
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2(500, 0))
	var normal: Enemy = game.get_node("Enemies").get_child(-1)
	if normal.inflammation_aura != null:
		_fail("ordinary enemies allocate a boss aura")
		return
	session.clear_run()
	print("Denti boss inflammation test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
