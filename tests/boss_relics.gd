extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_boss_relics_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.current_wave = 5
	game.wave.active = false
	game.rewards.earn_level()
	game.rewards.queue_chest(&"metal_crown", 4)
	game._begin_loot_collection()
	if game.rewards.step != PostWaveRewards.Step.LEVELS or game.choice_panel.mode != &"upgrade":
		_fail("boss relic appeared before pending level-up")
		return
	game.choice_panel._on_choice_pressed(0)
	if game.rewards.step != PostWaveRewards.Step.CHESTS or game.choice_panel.mode != &"chest":
		_fail("boss relic appeared before chest decision")
		return
	game.choice_panel._on_choice_pressed(1)
	if game.rewards.step != PostWaveRewards.Step.RELICS or game.choice_panel.mode != &"relic" or game.rewards.pending_relics.size() != 3 or game.shop_panel.visible:
		_fail("milestone boss did not offer three relics after other rewards")
		return
	var wave_five_options: Array[String] = game.rewards.pending_relics.duplicate()
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if not paused or game.rewards.step != PostWaveRewards.Step.RELICS or game.choice_panel.mode != &"relic" or game.rewards.pending_relics != wave_five_options:
		_fail("resume rerolled or lost the relic choice")
		return
	game.choice_panel._on_choice_pressed(0)
	if game.relics.owned.size() != 1 or game.relics.owned[0] != wave_five_options[0] or game.rewards.step != PostWaveRewards.Step.SHOP or not game.shop_panel.visible:
		_fail("relic selection did not grant one relic before opening shop")
		return
	var first_relic: String = game.relics.owned[0]
	for milestone in [10, 15]:
		game.shop_panel.visible = false
		game.in_shop = false
		game.rewards.begin_wave()
		game.wave.current_wave = milestone
		game.wave.active = false
		game._begin_loot_collection()
		if game.rewards.step != PostWaveRewards.Step.RELICS or game.rewards.pending_relics.size() != 3 or game.rewards.pending_relics.has(first_relic):
			_fail("later milestone offered fewer than three choices or repeated an owned relic")
			return
		game.choice_panel._on_choice_pressed(0)
	if game.relics.owned.size() != 3 or game.relics.owned[0] == game.relics.owned[1] or game.relics.owned[1] == game.relics.owned[2]:
		_fail("relics were not unique across milestone bosses")
		return
	if not game.relics.has_relic(&"tidal_seal"):
		game.relics.acquire(&"tidal_seal")
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2(200.0, 0.0))
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2(250.0, 0.0))
	var target: Enemy = game.get_node("Enemies").get_child(-2)
	var neighbor: Enemy = game.get_node("Enemies").get_child(-1)
	var water_weapon: WeaponData = WeaponCatalog.by_id(&"water_jet")
	for hit in 4:
		game.relics.on_weapon_hit(target, 15.0, water_weapon, false)
	if neighbor.wet_time > 0.0:
		_fail("water relic triggered before its fifth hit")
		return
	game.relics.on_weapon_hit(target, 15.0, water_weapon, false)
	if neighbor.wet_time <= 0.0 or neighbor.health >= neighbor.max_health:
		_fail("fifth water hit did not create the damaging wet wave")
		return
	if not game.relics.has_relic(&"shattered_halo"):
		game.relics.acquire(&"shattered_halo")
	game.player.stats.grant_shield(1)
	# Exercise a shield block, independently of randomly acquired dodge bonuses.
	game.player.stats.take_damage(10.0, false)
	if game.relics.damage_factor() != 1.3:
		_fail("shield block did not trigger the relic damage window")
		return
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if game.relics.damage_factor() != 1.3 or game.relics.owned.size() < 3:
		_fail("relic ownership or active effect did not survive resume")
		return
	game.shop_panel.visible = false
	game.in_shop = false
	game.rewards.begin_wave()
	game.wave.current_wave = 20
	game.wave.active = false
	game._begin_loot_collection()
	if game.rewards.step != PostWaveRewards.Step.END or game.choice_panel.mode != &"end":
		_fail("final boss offered a relic after the run ended")
		return
	session.clear_run()
	paused = false
	print("Denti boss relics test passed")
	quit(0)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
