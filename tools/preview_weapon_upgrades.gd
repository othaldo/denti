extends "res://tests/support/test_runtime.gd"
## Native production view, with a separate preview save and real upgrade rules.

const OUTPUT := "res://docs/screenshots/weapon_upgrades/"
var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://weapon_upgrades_preview.json"
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
	game.player.loadout.restore([
		{"id": "magic_toothbrush", "tier": 3}, {"id": "turbo_drill", "tier": 2},
		{"id": "enamel_mirror", "tier": 1}, {"id": "mouthwash_mortar", "tier": 4}])
	var state: WeaponUpgradeState = game.rewards.weapon_upgrades
	state.points = 100
	var weapons: Array[WeaponInstance] = game.player.loadout.equipped()
	var builds := [[{ "id": &"fire", "level": 4}, {"id": &"tempo", "level": 2}], [{"id": &"bleed", "level": 3}], [{"id": &"crit", "level": 10}], [{"id": &"wet", "level": 2}]]
	for index in weapons.size():
		weapons[index].set_physics_process(false)
		for effect: Dictionary in builds[index]:
			for rank in int(effect.level): assert(state.plan(game.player.loadout, weapons[index].instance_uid, effect.id))
	assert(state.commit(game.player.loadout))
	state.points = 3
	game.rewards.step = PostWaveRewards.Step.WEAPONS
	game._advance_post_wave_rewards()
	var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	if "--interactive" in OS.get_cmdline_user_args(): return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for extent in [Vector2i(1280, 720), Vector2i(1040, 600), Vector2i(360, 640), Vector2i(320, 568), Vector2i(568, 320), Vector2i(720, 1280), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		DisplayServer.window_set_size(extent)
		panel.select_weapon(0)
		await _capture("overview_%dx%d.png" % [extent.x, extent.y])
		assert(panel.upgrade_buttons.size() == 4 and panel.upgrade_buttons[3].disabled)
		assert(panel.upgrade_buttons[3].text == "Ab Mk IV")
		assert(panel.stage.panel.get_global_rect().encloses(panel.finish_button.get_global_rect()))
		panel.open_picker(2)
		panel.selected_effect = &"crit_damage"
		panel._save_cursor()
		panel._refresh()
		await _capture("picker_%dx%d.png" % [extent.x, extent.y])
		panel._back()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(root.size)
	panel.select_weapon(2)
	await _capture("mk_i_and_max.png")
	# The normal project stretch must also keep physical controls usable.
	root.size = Vector2i(1920, 1080)
	DisplayServer.window_set_size(root.size)
	panel.select_weapon(0)
	await _capture("project_stretch_1920x1080.png")
	session.clear_run()
	print("PASS native production upgrade views: Mk gates, maximum rank, seven extents, real project scaling and text bounds")
	paused = false
	finish(0)


func _capture(filename: String) -> void:
	for frame in 12: await process_frame
	_check_bounds(game.weapon_enchantment_panel.body)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + filename)


func _check_bounds(parent: Control) -> void:
	for child in parent.get_children():
		if child is Label and not Rect2(Vector2.ZERO, parent.size).grow(1).encloses(child.get_rect()):
			push_error("Text exceeds its surface: " + child.text)
			quit(1)
			return
		if child is Control: _check_bounds(child)
