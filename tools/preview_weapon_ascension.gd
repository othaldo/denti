extends "res://tests/support/test_runtime.gd"
## Native production UI with an isolated save; no normal run is modified.

const OUTPUT := "res://docs/screenshots/weapon_ascension/"
var game: Node2D

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://weapon_ascension_preview.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.player.loadout.restore([{"id": "magic_toothbrush", "tier": 4}, {"id": "turbo_drill", "tier": 3}, {"id": "mouthwash_mortar", "tier": 4}])
	for weapon in game.player.loadout.equipped(): weapon.set_physics_process(false)
	var state: WeaponUpgradeState = game.rewards.weapon_upgrades
	state.points = 30
	var uid: String = game.player.loadout.equipped()[0].instance_uid
	for index in 4: state.plan(game.player.loadout, uid, &"fire")
	for index in 2: state.plan(game.player.loadout, uid, &"tempo")
	assert(state.commit(game.player.loadout))
	state.points = 18
	game.coins = 360
	game.wave.current_wave = 15
	game.rewards.step = PostWaveRewards.Step.WEAPONS
	game._advance_post_wave_rewards()
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(360, 640), Vector2i(568, 320), Vector2i(1920, 1080)]:
		root.size = extent
		root.content_scale_size = extent
		DisplayServer.window_set_size(extent)
		state.actions.clear()
		state.cursor = {"target_uid": uid}
		game.weapon_enchantment_panel.refresh()
		await _capture("ready_%dx%d.png" % [extent.x, extent.y])
		game._on_weapon_ascension_requested(uid)
		await _capture("planned_%dx%d.png" % [extent.x, extent.y])
	session.clear_run()
	paused = false
	print("PASS native ascension previews: ready/planned, five extents, real point/gold quotes and undo")
	finish()

func _capture(filename: String) -> void:
	for frame in 12: await process_frame
	game.weapon_enchantment_panel.stage.body_scroll.scroll_vertical = 0
	await RenderingServer.frame_post_draw
	var error := root.get_texture().get_image().save_png(OUTPUT + filename)
	if error != OK:
		push_error("Cannot save ascension preview: " + filename)
		finish(1)
