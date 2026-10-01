extends SceneTree

# Deterministic contact attacks; no bleed ticks/player crit/enemy AI; innate weapon crit remains.
const SECONDS := 12.0
const STEP := 1.0 / 60.0
const IDS := [&"turbo_drill", &"plaque_scaler", &"toothpick_spear", &"cavity_grinder", &"prophylaxis_polisher"]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://weapon_contact_benchmark.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	paused = true
	game.player.attack_performed.disconnect(game.sound.play_attack)
	game.player.stats.crit_chance = 0.0
	var report := {"seconds": SECONDS, "method": "60 Hz; seed 13579 per case; tier I; stationary target; direct contact damage only; player crit 0, innate weapon crit/focus active; no items/AI/bleed ticks; boss guard disabled to isolate weapon throughput", "measurements": []}
	for id in IDS:
		var data := WeaponCatalog.by_id(id)
		for boss in [false, true]:
			for distance in [45.0, data.range_at_tier(1) * 0.65, data.range_at_tier(1)]:
				for side in [1.0, -1.0]:
					seed(13579)
					game.player.loadout.restore([{"id": str(id), "tier": 1}])
					var weapon: WeaponInstance = game.player.loadout.equipped()[0]
					weapon.set_physics_process(false)
					game._create_enemy(WaveController.BOSS if boss else WaveController.PLAQUE, game.player.global_position + Vector2(distance * side, 0))
					var enemy: Enemy = game.get_node("Enemies").get_child(-1)
					# Cosmetic hit numbers/SFX consume randomness and use wall-clock throttles.
					enemy.damaged.disconnect(game._on_enemy_damaged)
					enemy.health = 1000000.0
					enemy.max_health = 1000000.0
					enemy.damage_reduction = 0.0
					enemy.boss_damage_budget = 1000000.0
					enemy.boss_phase = 2
					enemy.boss_phase_timer = 0.0
					enemy.set_physics_process(false)
					var hits: Array[float] = []
					for frame in int(SECONDS / STEP):
						var before := enemy.health
						weapon._physics_process(STEP)
						if enemy.health < before:
							hits.append(before - enemy.health)
					var sum := 1000000.0 - enemy.health
					report.measurements.append({"weapon": str(id), "boss": boss, "distance": distance, "side": side, "hits": hits.size(), "direct_dps": sum / SECONDS, "estimated_dps": data.estimated_dps(1, game.player.stats), "size": WeaponLayout.visual_size(data)})
					enemy.free()
	var output := "res://.codex/weapon_contact_%s.json" % ("before" if OS.get_cmdline_user_args().has("--before") else "after")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.codex"))
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write weapon contact report: " + output)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	print("Weapon contact benchmark: " + ProjectSettings.globalize_path(output))
	session.clear_run()
	game.free()
	paused = false
	quit(0)
