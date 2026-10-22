extends "res://tests/support/test_runtime.gd"

const OUTPUT := "res://.godot/goblin_balance/"
const PROFILES := [
	{"wave": 11, "tier": 2, "damage": 24.0, "melee": 8.0, "ranged": 4.0, "speed": 25.0},
	{"wave": 11, "tier": 3, "damage": 50.0, "melee": 14.0, "ranged": 12.0, "speed": 45.0},
	{"wave": 19, "tier": 4, "damage": 80.0, "melee": 24.0, "ranged": 18.0, "speed": 70.0},
]

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	var baseline := OS.get_cmdline_user_args().has("--baseline")
	var fixture_path := OUTPUT + ("baseline/" if baseline else "current/")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(fixture_path))
	var session: Node = root.get_node("GameSession")
	session.save_path = fixture_path + "run.json"
	session.settings_path = fixture_path + "settings.cfg"
	session.progression_path = fixture_path + "progression.cfg"
	session.report_dir = fixture_path + "reports"
	session.settings_data = SessionSettings.new()
	session.progression_data = ProgressionStore.new()
	session.resume_requested = false
	session.selected_story_mode = false
	session.reduced_ui_motion = true
	AudioServer.set_bus_mute(0, true)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	var samples: Array[Dictionary] = []
	for difficulty in [&"normal", &"hell"]:
		for profile in PROFILES:
			seed(20261022)
			session.clear_run()
			session.pending_start_weapon_id = &"magic_toothbrush"
			var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
			root.add_child(game)
			current_scene = game
			paused = true
			game.wave.set_process(false)
			game.wave.current_wave = profile.wave
			game.wave.difficulty_id = difficulty
			game.wave.active = true
			game.run_flow.enter(RunFlow.Phase.COMBAT)
			game.choice_panel.hide()
			game._clear_arena(false)
			await process_frame
			game.player.position = Vector2(850, 850)
			game.player.stats.max_health = 1000000
			game.player.stats.health = 1000000
			game.player.stats.damage_bonus = profile.damage
			game.player.stats.melee_damage = profile.melee
			game.player.stats.ranged_damage = profile.ranged
			game.player.stats.attack_speed = profile.speed
			var weapons: Array[Dictionary] = []
			for id in ["magic_toothbrush", "turbo_drill", "water_jet", "toothpick_spear", "prophylaxis_polisher"]:
				weapons.append({"id": id, "tier": profile.tier})
			game.player.loadout.restore(weapons)
			game._spawn_loot_goblin()
			var thief: Enemy = game.get_node("Enemies").get_child(-1)
			if baseline:
				var old_data := EnemyCatalog.LOOT_GOBLIN.duplicate() as EnemyData
				old_data.max_health = 180
				old_data.health_per_wave = 42
				old_data.late_health_acceleration = 1.8
				thief.max_health = old_data.max_health * WaveController.health_multiplier(old_data, profile.wave) * DifficultyCatalog.by_id(difficulty).health_factor(profile.wave)
				thief.health = thief.max_health
			thief.position = Vector2(1090, 850)
			var starting_health := thief.max_health
			var frame := 0
			paused = false
			while is_instance_valid(thief) and not thief.is_queued_for_deletion() and frame < 1200:
				game.player.position = game.player.position.move_toward(thief.position, PlayerStats.BASE_MOVE_SPEED / 60)
				await physics_frame
				frame += 1
			paused = true
			var result := {"difficulty": str(difficulty), "profile": profile, "health": starting_health, "seconds": frame / 60.0, "killed": frame < 1200}
			samples.append(result)
			print("%s W%d Mk%d: %.0f HP, %.2fs" % [difficulty, profile.wave, profile.tier, starting_health, result.seconds])
			game.free()
			await process_frame
			paused = false
	session.clear_run()
	var report := {"method": "Actual fixed 60 Hz combat against a moving goblin. Baseline-speed Denti pursues from 240 units with five configured weapons, no items/affixes and no other enemies. Normal/Hell. Baseline mode uses the old health profile with current AI; no coins are present, so scoop changes do not affect the comparison. Synthetic builds, not a complete run; no promise about maximum-power builds.", "baseline_health": baseline, "samples": samples}
	var file_name := "before.json" if baseline else "after.json"
	FileAccess.open(OUTPUT + file_name, FileAccess.WRITE).store_string(JSON.stringify(report, "\t") + "\n")
	finish()
