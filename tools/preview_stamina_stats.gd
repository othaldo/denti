extends "res://tests/support/test_runtime.gd"

const OUTPUT := "res://.godot/stamina_stats"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://stamina_stats_preview.json"
	session.resume_requested = false
	session.clear_run()
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.coins = 1000
	var upgrades: Array[UpgradeData] = []
	for id in ["zahnglueck", "wurzelkraft", "speichel", "fernschaden"]:
		var upgrade: UpgradeData = load("res://data/upgrades/%s.tres" % id)
		upgrades.append(upgrade.with_tier(1).with_stat_context(game.player.stats))
	game.choice_panel.show_upgrades(upgrades)
	game.choice_panel.update_level_reroll(1000, 24, 31)
	paused = true
	await _capture("cards_desktop", Vector2i(1280, 720))
	await _capture("cards_phone", Vector2i(360, 640))
	game.choice_panel.hide()
	game.game_menu.open_pause()
	game.game_menu._show_stats()
	await _capture("stats_phone", Vector2i(360, 640))
	game.player.stats.apply_upgrade(&"dash_recovery_bonus", 100)
	game.game_menu._show_stats()
	await _capture("stats_200", Vector2i(360, 640))
	game.game_menu.hide()
	# Compare the generated artwork with the existing set at actual UI sizes.
	var panel := PanelContainer.new()
	panel.theme = DentiUIStyle.make_theme()
	panel.custom_minimum_size = Vector2(480, 200)
	panel.add_theme_stylebox_override("panel", DentiUIStyle._box(DentiUIStyle.PANEL, DentiUIStyle.LINE, 0, 0))
	var layer := CanvasLayer.new()
	layer.layer = 100
	root.add_child(layer)
	layer.add_child(panel)
	var content := Control.new()
	panel.add_child(content)
	var sizes := [23, 40, 56]
	var indices := [2, 7, 5, 11]
	for row in sizes.size():
		var side: int = sizes[row]
		var label := DentiUIComponents.label(content, "%d px" % side, 14)
		label.autowrap_mode = TextServer.AUTOWRAP_OFF
		label.position = Vector2(12, 12 + row * 58)
		label.size = Vector2(60, 30)
		for column in indices.size():
			var art := TextureRect.new()
			art.texture = DentiUIIcons.stat(indices[column])
			art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			art.position = Vector2(100 + column * 80, row * 58)
			art.size = Vector2(side, side)
			content.add_child(art)
	await _capture("icon_sizes", Vector2i(480, 200))
	session.clear_run()
	finish()

func _capture(label: String, extent: Vector2i) -> void:
	root.content_scale_size = extent
	root.size = extent
	DisplayServer.window_set_size(extent)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(OUTPUT.path_join(label + ".png")))
