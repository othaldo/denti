extends "res://tests/support/test_runtime.gd"

# Native game renders with isolated saves; no reference image is overwritten.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://combat_hud_preview.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.player.position = game.arena.arena_size * 0.5
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 2}, {"id": "water_jet", "tier": 2}])
	for index in 8:
		game._spawn_enemy(EnemyCatalog.PLAQUE if index % 2 == 0 else EnemyCatalog.ACID_SPITTER)
	game._spawn_enemy(EnemyCatalog.CAVITY_COUNT)
	game._spawn_enemy(EnemyCatalog.CAVITY_EMPEROR)
	var bosses := BossEncounter.remaining(game.get_node("Enemies"))
	bosses[0].health = bosses[0].max_health * 0.62
	bosses[1].health = bosses[1].max_health * 0.24
	bosses[0].data = bosses[0].data.duplicate()
	bosses[0].data.display_name = "Karies-Graf mit einem besonders langen Herrschertitel"
	bosses[0].overtime_active = true
	bosses[0].overtime_seconds = 12
	paused = true
	var directory := "res://docs/screenshots/combat_hud"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(directory))
	var hud: GameHUD = game.hud
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(720, 1280), Vector2i(1040, 600), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		DisplayServer.window_set_size(extent)
		root.size = extent
		game.mobile_controls.visible = true
		game.mobile_controls.set_combat_active(true)
		hud._set_fps_visible(true)
		hud.fps_label.text = "FPS 60"
		hud.fps_refresh_time = INF
		game.player.stats.max_health = 100
		game.player.stats.health = 86
		game.player.stats.shield_charges = 0
		hud.update_status(game.player.stats, 12, 30, 6, 146, 12, 27, false, null, false)
		hud.chests_label.text = "0"
		for badge in hud.status_badges:
			badge.show_amount(0)
		await _capture(directory, "normal_%dx%d.png" % [extent.x, extent.y])
		game.player.stats.max_health = 9876543
		game.player.stats.health = 8765432
		game.player.stats.shield_charges = 5
		hud.update_status(game.player.stats, 123456, 987654, 18, 12345678, 30, 0, false, bosses[0], true, false, 3, true)
		hud.update_bosses(bosses)
		hud.chests_label.text = "2"
		for badge in hud.status_badges:
			badge.show_amount(5.9)
		for frame in 40:
			hud.health_vessel.advance(1.0 / 60.0)
		await _capture(directory, "bosses_%dx%d.png" % [extent.x, extent.y])
		if extent in [Vector2i(320, 568), Vector2i(1280, 720)]:
			var health := bosses[0].health
			bosses[0].health = bosses[0].max_health
			var single: Array[Enemy] = [bosses[0]]
			hud.update_bosses(single)
			await _capture(directory, "full_boss_%dx%d.png" % [extent.x, extent.y])
			bosses[0].health = health
			for count in [1, 3, 5, 123]:
				hud.update_status(game.player.stats, 12, 30, 18, 146, 12, 27, false, null, false, false, count)
				await _capture(directory, "level_plus%d_%dx%d.png" % [count, extent.x, extent.y])
	await _capture_level_details(directory, hud, game.player.stats)
	session.clear_run()
	finish()


func _capture_level_details(directory: String, hud: GameHUD, stats: PlayerStats) -> void:
	var extent := Vector2i(1024, 360)
	root.content_scale_size = extent
	DisplayServer.window_set_size(extent)
	root.size = extent
	var overlay := CanvasLayer.new()
	overlay.layer = 100
	root.add_child(overlay)
	var backdrop := ColorRect.new()
	backdrop.color = DentiUIStyle.BACKGROUND
	backdrop.size = extent
	overlay.add_child(backdrop)
	var size_caption := Label.new()
	size_caption.text = "Originalgröße · Level 48×42 px · Pille 18 px hoch, Breite nach Inhalt"
	size_caption.position = Vector2(0, 222)
	size_caption.size = Vector2(1024, 24)
	size_caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	size_caption.add_theme_font_override("font", DentiUIStyle.FONT)
	DentiUIStyle.style_hud_text(size_caption, DentiUIStyle.MUTED, 12)
	overlay.add_child(size_caption)
	var index := 0
	for count in [0, 1, 5, 123]:
		hud.update_status(stats, 12, 30, 18, 146, 12, 27, false, null, false, false, count)
		var caption := Label.new()
		caption.text = "Ohne offene Aufstiege" if count == 0 else "1 offener Aufstieg" if count == 1 else "%d offene Aufstiege" % count
		caption.position = Vector2(index * 256, 22)
		caption.size = Vector2(256, 28)
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_font_override("font", DentiUIStyle.FONT)
		DentiUIStyle.style_hud_text(caption, DentiUIStyle.INK, 16)
		overlay.add_child(caption)
		var group := Control.new()
		group.position = Vector2(index * 256 + 11, 84)
		group.theme = hud.get_node("Root").theme
		overlay.add_child(group)
		var seal := hud.level_medallion.duplicate() as Control
		group.add_child(seal)
		seal.position = Vector2.ZERO
		seal.size *= 3
		var badge := HUDPendingLevels.new()
		group.add_child(badge)
		badge.show_count(count)
		badge.position = (hud.pending_badge.position - hud.level_medallion.position) * 3
		badge.size *= 3
		for number: Label in [seal.get_child(0), badge.label]:
			number.add_theme_font_size_override("font_size", number.get_theme_font_size("font_size") * 3)
			number.add_theme_constant_override("outline_size", number.get_theme_constant("outline_size") * 3)
		# Render the true 48px/18px HUD components beneath the enlarged detail.
		var actual_seal := hud.level_medallion.duplicate() as Control
		group.add_child(actual_seal)
		actual_seal.position = Vector2(78, 170)
		var actual_badge := HUDPendingLevels.new()
		group.add_child(actual_badge)
		actual_badge.show_count(count)
		actual_badge.position = actual_seal.position + hud.pending_badge.position - hud.level_medallion.position
		index += 1
	for frame in 4:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(directory.path_join("level_details_3x.png")))
	overlay.queue_free()


func _capture(directory: String, filename: String) -> void:
	for frame in 8:
		await process_frame
	(current_scene.get_node("Player/Camera2D") as Camera2D).force_update_scroll()
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path(directory.path_join(filename))
	root.get_texture().get_image().save_png(path)
	print(path)
