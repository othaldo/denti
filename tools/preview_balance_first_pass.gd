extends "res://tests/support/test_runtime.gd"

var game: Node2D
const OUTPUT := "res://.godot/balance_first_pass/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://preview_balance_first_pass.json"
	session.resume_requested = false
	session.clear_run()
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	DisplayServer.window_set_size(root.size)
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.wave.active = false
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.player.stats.crit_chance = 0
	game.get_node("Enemies").set_physics_process(false)
	game.player.global_position = Vector2(960, 540)
	game.hud.get_node("Root").visible = false
	game.mobile_controls.visible = false
	game.get_node("DamageNumbers").visible = false
	var camera: Camera2D = game.player.get_node("Camera2D")
	camera.zoom = Vector2.ONE * 1.6
	camera.force_update_scroll()
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	game.player.loadout.restore([{"id": "interdental_brush", "tier": 1}])
	for offset in [Vector2(80, 0), Vector2(-65, 0), Vector2(0, -78), Vector2(0, 78)]:
		game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.set_simulation_enabled(false)
		enemy.health = 10000
		enemy.max_health = 10000
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	weapon.set_physics_process(false)
	weapon.cooldown = 0
	weapon._physics_process(0.001)
	for index in 5:
		weapon._physics_process(weapon.attack_duration * 0.14)
		await _capture("brush_%d" % index)
	game.player.loadout.restore([])
	for enemy in game.get_node("Enemies").get_children(): enemy.free()
	camera.zoom = Vector2.ONE
	game.wave.current_wave = 20
	game.player.global_position = Vector2(960, 540)
	game.player.velocity = Vector2.DOWN * PlayerStats.BASE_MOVE_SPEED
	game._create_enemy(EnemyCatalog.CAVITY_EMPEROR, Vector2(700, 540))
	var boss: Enemy = game.boss
	boss.set_simulation_enabled(false)
	boss.boss_phase = 0
	var attack := boss.crown_court_encounter
	attack.begin(CrownCourtEncounter.Attack.EDICT)
	attack.advance(0.65)
	camera.force_update_scroll()
	await _capture("verdict_warning")
	game.player.global_position += Vector2(0, -75)
	game.player.velocity = Vector2.UP * PlayerStats.BASE_MOVE_SPEED
	attack.advance(0.25)
	camera.force_update_scroll()
	await _capture("verdict_turn")
	session.clear_run()
	print("PASS native balance preview: " + OUTPUT)
	finish()


func _capture(name: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + name + ".png")
