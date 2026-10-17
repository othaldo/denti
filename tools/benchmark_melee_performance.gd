extends SceneTree

# CPU comparison of legal six-root loadouts. Rendering, enemy AI, hit callbacks,
# item procs and loot are excluded. Restore enemy positions outside the timer so
# knockback cannot silently reduce the workload of later repetitions.
const STEP := 1.0 / 60.0
const TICKS := 600
const IDS := [&"turbo_drill", &"plaque_scaler", &"cavity_grinder", &"prophylaxis_polisher", &"toothpick_spear", &"floss_whip", &"interdental_brush", &"water_jet", &"magic_toothbrush"]
const TIMED_STRIKE: Script = preload("res://tools/profiled_weapon_strike.gd")

var game: Node2D
var hits := 0
var samples: Array[Dictionary] = []

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	if "--rendered" in OS.get_cmdline_user_args():
		await _run_rendered()
		return
	var session: Node = root.get_node("GameSession")
	session.save_path = "res://.godot/benchmark_melee_run.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.selected_difficulty_id = &"normal"
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.player.loadout.restore([])
	game.player.attack_performed.disconnect(game.sound.play_attack)
	paused = true
	await process_frame
	var index: EnemySpatialIndex = game.get_node("Enemies")
	var pool: PlayerProjectilePool = game.get_node("Projectiles")
	var profile := "--profile" in OS.get_cmdline_user_args()
	for count in ([110] if profile else [30, 110, 400]):
		var enemies: Array[Enemy] = []
		var positions := PackedVector2Array()
		for number in count:
			var at: Vector2 = game.player.global_position + Vector2.from_angle(number * 2.399963) * (45.0 + float(number % 8) * 12.0)
			game._create_enemy(WaveController.PLAQUE, at)
			var enemy: Enemy = index.get_child(-1)
			# Remove game feedback/telemetry/status callbacks uniformly for all weapons.
			for signal_name in [&"damaged", &"damage_recorded", &"weapon_hit"]:
				for connection in enemy.get_signal_connection_list(signal_name):
					enemy.disconnect(signal_name, connection.callable)
			enemy.damaged.connect(_count_hit)
			enemy.health = 1e12
			enemy.max_health = 1e12
			enemies.append(enemy)
			positions.append(at)
		for speed in ([80.0] if profile else [80.0, 300.0]):
			game.player.stats.attack_speed = speed
			for id in IDS:
				for pass_index in 4:
					seed(20261006)
					_clear_projectiles(pool)
					var loadout: Array[Dictionary] = []
					var data := WeaponCatalog.by_id(id)
					for number in int(WeaponLoadout.CAPACITY / data.hands):
						loadout.append({"id": str(id), "tier": 4})
					game.player.loadout.restore(loadout)
					var weapons: Array[WeaponInstance] = game.player.loadout.equipped()
					for weapon in weapons:
						if profile:
							weapon.strike = TIMED_STRIKE.new()
						if data.attack_mode == &"projectile":
							pool.prepare(data, 4, 64)
					# Warm up attacks and pool capacity before measuring each fresh loadout.
					for tick in 120:
						_reset_positions(enemies, positions)
						_step(weapons, pool)
					for weapon in weapons:
						if profile:
							weapon.strike.elapsed_us = 0
							weapon.strike.calls = 0
					hits = 0
					var weapons_us := 0
					var projectiles_us := 0
					var peak_projectiles := 0
					var created_before := pool.created
					for tick in TICKS:
						_reset_positions(enemies, positions)
						var started := Time.get_ticks_usec()
						for weapon in weapons:
							weapon._physics_process(STEP)
						weapons_us += Time.get_ticks_usec() - started
						started = Time.get_ticks_usec()
						for projectile in pool.get_children():
							projectile._physics_process(STEP)
						projectiles_us += Time.get_ticks_usec() - started
						peak_projectiles = maxi(peak_projectiles, pool.get_child_count())
					if pass_index == 0:
						continue
					var strike_us := 0
					var strike_calls := 0
					for weapon in weapons:
						if profile:
							strike_us += weapon.strike.elapsed_us
							strike_calls += weapon.strike.calls
					var record := {"weapon": str(id), "weapon_count": weapons.size(), "enemy_count": count, "attack_speed_bonus": speed, "pass": pass_index, "weapon_ms_per_tick": float(weapons_us) / TICKS / 1000.0, "projectile_ms_per_tick": float(projectiles_us) / TICKS / 1000.0, "total_ms_per_tick": float(weapons_us + projectiles_us) / TICKS / 1000.0, "strike_ms_per_tick_inclusive": float(strike_us) / TICKS / 1000.0, "strike_calls": strike_calls, "hits": hits, "peak_projectiles": peak_projectiles, "new_projectiles_during_measurement": pool.created - created_before}
					samples.append(record)
					print(JSON.stringify(record))
		_clear_projectiles(pool)
		for enemy in enemies:
			enemy.free()
	var report := {"engine": Engine.get_version_info().string, "profile": profile, "ticks": TICKS, "step": STEP, "method": "Paused scene; manual 60 Hz steps; tier IV legal six-root loadouts; stationary plaque at radii 45..129; no rendering/AI/loot/hit callbacks/item procs; empty inventory damage calculation retained; knockback reset outside timer; 120 warmup ticks per loadout and one discarded pass; 3 measured repetitions. Strike times include hits and overlap weapon times. Not FPS or a gameplay balance comparison.", "samples": samples}
	var output := "res://docs/melee_performance_%s.json" % ("profile" if profile else "cpu")
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write " + output)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	game.free()
	session.clear_run()
	await process_frame
	quit()

func _step(weapons: Array[WeaponInstance], pool: PlayerProjectilePool) -> void:
	for weapon in weapons:
		weapon._physics_process(STEP)
	for projectile in pool.get_children():
		projectile._physics_process(STEP)

func _reset_positions(enemies: Array[Enemy], positions: PackedVector2Array) -> void:
	for number in enemies.size():
		enemies[number].global_position = positions[number]

func _count_hit(_at: Vector2, _amount: float) -> void:
	hits += 1

func _clear_projectiles(pool: PlayerProjectilePool) -> void:
	for projectile in pool.get_children():
		projectile.retire()

func _run_rendered() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("--rendered requires a native rendering window")
		quit(1)
		return
	DisplayServer.window_set_size(Vector2i(1280, 720))
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var session: Node = root.get_node("GameSession")
	session.save_path = "res://.godot/benchmark_melee_rendered_run.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.selected_difficulty_id = &"normal"
	session.graphics_mode = session.GraphicsMode.FULL
	var results: Array[Dictionary] = []
	for pass_index in 2:
		for id in [&"turbo_drill", &"toothpick_spear", &"floss_whip", &"water_jet", &"magic_toothbrush"]:
			game = load("res://scenes/game/game.tscn").instantiate()
			var preset := TestArenaCatalog.by_code("debug profile")
			CombatDiagnostics.configure(game, preset)
			root.add_child(game)
			current_scene = game
			game.choice_panel.buttons[0].pressed.emit()
			game.wave.active = false
			game.wave.set_process(false)
			game.wave.current_wave = 17
			game.wave.remaining = 10000
			game.player.stats.max_health = 1e12
			game.player.stats.health = 1e12
			game.player.stats.attack_speed = 80
			seed(20261006)
			var data := WeaponCatalog.by_id(id)
			var loadout: Array[Dictionary] = []
			for number in int(WeaponLoadout.CAPACITY / data.hands):
				loadout.append({"id": str(id), "tier": 4})
			game.player.loadout.restore(loadout)
			for number in 110:
				game._create_enemy(WaveController.PLAQUE, game.player.global_position + Vector2.from_angle(number * 2.399963) * (45.0 + float(number % 8) * 12.0))
				var enemy: Enemy = game.get_node("Enemies").get_child(-1)
				enemy.health = 1e12
				enemy.max_health = 1e12
			game.wave.active = true
			var warmup := Time.get_ticks_usec()
			while Time.get_ticks_usec() - warmup < 2000000:
				game.autosave_timer = 0
				await process_frame
			var diagnostics: CombatDiagnostics = game.get_node("CombatDiagnostics")
			diagnostics.reset()
			var frames: Array[float] = []
			var draw_calls := 0.0
			var physics_before := Engine.get_physics_frames()
			var started := Time.get_ticks_usec()
			var previous := started
			while Time.get_ticks_usec() - started < 4000000:
				game.autosave_timer = 0
				await process_frame
				var now := Time.get_ticks_usec()
				frames.append(float(now - previous) / 1000.0)
				previous = now
				draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
			var elapsed := Time.get_ticks_usec() - started
			var cpu := diagnostics.snapshot()
			frames.sort()
			var record := {"weapon": str(id), "weapon_count": loadout.size(), "pass": pass_index + 1, "fps": float(frames.size()) * 1e6 / elapsed, "frame_ms_mean": float(elapsed) / frames.size() / 1000.0, "frame_ms_p95": frames[floori((frames.size() - 1) * 0.95)], "frame_ms_max": frames[-1], "physics_ticks": Engine.get_physics_frames() - physics_before, "draw_calls_mean": draw_calls / frames.size(), "cpu_estimated_ms_per_frame_inclusive": cpu, "enemies": game.get_node("Enemies").get_child_count(), "total_damage": game.telemetry.total_damage, "player_projectiles_end": game.get_node("Projectiles").get_child_count()}
			results.append(record)
			print(JSON.stringify(record))
			game.free()
			await process_frame
	var report := {"engine": Engine.get_version_info().string, "adapter": RenderingServer.get_video_adapter_name(), "renderer": RenderingServer.get_current_rendering_method(), "method": "Native 1280x720, full graphics, VSync/FPS limit off, normal real-time 60 Hz physics; 110 moving immortal plaque; tier IV legal six-root loadouts; +80% attack speed; no purchased items or loot; hit/status/telemetry/feedback and enemy AI active; 2 s warmup + 4 s measurement per fresh scene; 2 passes; save timer reset. Diagnostic sampling 1/10; inclusive CPU times overlap. Workloads differ by weapon and knockback; not a replay or mobile FPS prediction.", "samples": results}
	var file := FileAccess.open("res://docs/melee_performance_rendered.json", FileAccess.WRITE)
	if file == null:
		push_error("Cannot write native benchmark report")
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t"))
	file.close()
	session.clear_run()
	quit()
