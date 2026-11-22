extends "res://tests/support/test_runtime.gd"
## Native enchantment picker with a selected effect at desktop and handheld extents.
## Usage: --script res://tools/preview_weapon_enchantment_picker.gd -- [--out=<dir>] [--six]

var game: Node2D
var output_path := "res://docs/screenshots/weapon_enchantment_picker/"


func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="): output_path = arg.trim_prefix("--out=").trim_suffix("/") + "/"
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://weapon_enchantment_picker_preview.json"
	session.clear_run()
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	var equipment: Array = [{"id": "fluoride_rocket", "tier": 1}]
	if "--six" in OS.get_cmdline_user_args():
		for index in 5: equipment.append({"id": "turbo_drill", "tier": 2})
	game.player.loadout.restore(equipment)
	for weapon in game.player.loadout.equipped(): weapon.set_physics_process(false)
	var state: WeaponUpgradeState = game.rewards.weapon_upgrades
	state.points = 2
	game.rewards.step = PostWaveRewards.Step.WEAPONS
	game._advance_post_wave_rewards()
	var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	DirAccess.make_dir_recursive_absolute(output_path)
	# Physical window sizes under the project's canvas_items/expand stretch.
	for extent: Vector2i in [Vector2i(1280, 720), Vector2i(1920, 1080), Vector2i(2000, 955), Vector2i(360, 640), Vector2i(568, 320)]:
		var handheld := extent.x < 720
		root.content_scale_size = extent if handheld else Vector2i(1280, 720)
		root.size = extent
		DisplayServer.window_set_size(extent)
		panel.select_weapon(0)
		for frame in 4: await process_frame
		panel.open_picker(0)
		for frame in 4: await process_frame
		panel.selected_effect = &"ice"
		panel._save_cursor()
		panel._refresh()
		for frame in 16: await process_frame
		var scroll := panel.stage.body_scroll
		var overflow := scroll.get_v_scroll_bar().max_value - scroll.size.y
		print("%dx%d scroll=%d overflow=%.0f preview_visible=%s" % [extent.x, extent.y, scroll.scroll_vertical, maxf(0, overflow),
			scroll.get_global_rect().encloses(panel.selection_preview.get_global_rect()) if is_instance_valid(panel.selection_preview) else false])
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(output_path + "picker_%dx%d.png" % [extent.x, extent.y])
		panel._back()
	session.clear_run()
	paused = false
	finish(0)
