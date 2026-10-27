extends "res://tests/support/test_runtime.gd"

const OUTPUT := "res://docs/screenshots/weapon_skins/"
var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://weapon_skins_preview.json"
	session.progression_path = "user://weapon_skins_preview.cfg"
	session.clear_run()
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.set_process(false)
	game.player.loadout.restore([
		_entry(&"magic_toothbrush", &"fire", 3), _entry(&"turbo_drill", &"ice", 2),
		_entry(&"enamel_mirror", &"", 2), _entry(&"cavity_grinder", &"wet", 4)])
	var state: WeaponUpgradeState = game.rewards.weapon_upgrades
	state.points = 5
	game.rewards.step = PostWaveRewards.Step.WEAPONS
	game._advance_post_wave_rewards()
	var panel: WeaponEnchantmentPanel = game.weapon_enchantment_panel
	for extent in [Vector2i(1280, 720), Vector2i(360, 640)]:
		root.content_scale_size = extent
		root.size = extent
		panel.select_weapon(0)
		await _capture("upgrades_%dx%d.png" % [extent.x, extent.y])
		panel.select_weapon(2)
		panel.open_picker(0)
		panel.selected_effect = &"poison"
		panel._save_cursor()
		panel._refresh()
		await _capture("element_preview_%dx%d.png" % [extent.x, extent.y])
		assert(panel.current_data().element_skin == &"poison")
		panel._back()
	panel.hide()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = root.content_scale_size
	game._open_shop()
	await _capture("shop_1280x720.png")
	game.shop_panel.hide()
	game.in_shop = false
	game.rewards.step = PostWaveRewards.Step.COMBAT
	game.player.loadout.restore([
		_entry(&"turbo_drill", &"fire"), _entry(&"enamel_mirror", &"ice"),
		_entry(&"prophylaxis_polisher", &"poison"), _entry(&"amalgam_slingshot", &"electric"),
		_entry(&"plaque_scaler", &"bleed"), _entry(&"water_jet", &"wet")])
	game._refresh_hud()
	var enemy: Enemy
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		game._create_enemy(WaveController.PLAQUE, game.player.global_position + direction * 110)
		enemy = game.get_node("Enemies").get_child(-1)
		enemy.health = 100000
		enemy.max_health = 100000
		enemy.set_physics_process(false)
	var targets: Array[Enemy] = [enemy]
	for weapon in game.player.loadout.equipped():
		weapon.set_physics_process(false)
		weapon._begin_attack(targets)
		weapon.attack_time = weapon.attack_duration * 0.5
		weapon.update_visual()
	var camera: Camera2D = game.player.get_node("Camera2D")
	camera.zoom = Vector2.ONE * 1.5
	camera.reset_smoothing()
	camera.force_update_scroll()
	await _capture("combat_1280x720.png")
	session.clear_run()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.progression_path))
	paused = false
	print("PASS native weapon skins: shop, upgrades, element preview, portrait and six-element combat")
	finish()


func _entry(id: StringName, element: StringName, tier: int = 4) -> Dictionary:
	return {"id": str(id), "tier": tier,
		"affixes": WeaponUpgrades.advance([], element, WeaponCatalog.by_id(id), tier) if element != &"" else []}


func _capture(filename: String) -> void:
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for frame in 12:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + filename)
