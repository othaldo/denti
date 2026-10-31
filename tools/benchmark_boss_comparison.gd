extends "res://tests/support/test_runtime.gd"
## Compare native encounters without changing combat resources or player saves.
## Run with isolated APPDATA/XDG_DATA_HOME (see docs/BOSS_COMPARISON.md).

const STEP := 1.0 / 60.0
const PRESSURE_SECONDS := 45.0
const TTK_LIMIT := 90.0
const HEALTH_RESERVOIR := 1000000.0
const ENEMY_SCENE := preload("res://scenes/enemies/enemy.tscn")
const WAVES := [5, 10, 15, 20]
const POLICIES := ["stationary", "orbit_close", "orbit_far", "orbit_far_fast"]
const SEEDS := [13579, 24680, 97531]
const RAW_DPS := [120.0, 350.0, 1000.0, 3000.0, 1000000.0]
var game: Node2D
var hits := 0
var status_damage := 0.0
var first_hit := -1.0
var sample_time := 0.0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://benchmark_boss_comparison.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.player.loadout.restore([])
	game.player.set_physics_process(false)
	game.player.damaged.disconnect(game._on_player_damaged)
	game.player.damaged.connect(func(_at: Vector2, _amount: float):
		hits += 1
		if first_hit < 0: first_hit = sample_time)
	game.player.status_effects.ticked.connect(func(_kind: int, amount: float): status_damage += amount)
	paused = true
	var quick := "--quick" in OS.get_cmdline_user_args()
	var king_only := "--king-only" in OS.get_cmdline_user_args()
	var royals_only := "--royals-only" in OS.get_cmdline_user_args()
	var emperor_only := "--emperor-only" in OS.get_cmdline_user_args()
	var policies: Array = POLICIES.duplicate()
	if "--extended" in OS.get_cmdline_user_args(): policies.append("flee_wall")
	var sample_waves: Array = [15] if king_only else ([10, 20] if royals_only else WAVES)
	if emperor_only: sample_waves = [20]
	var report := {
		"schema": 2, "hz": 60, "pressure_seconds": PRESSURE_SECONDS, "policies": policies,
		"ttk_limit_seconds": TTK_LIMIT, "seeds": SEEDS if not quick else [SEEDS[0]],
		"method": "Isolated native bosses at waves 5/10/15/20, all difficulties. Pressure: fixed health phase 0/1/2, no player attacks, 45 seconds, stationary or continuous orbit (160/320px target radius; 230px/s, fast=299px/s), three seeds with different starting bearings. No warning-aware dodging, dash, armor, dodge, shields, healing, weapons, adds, normal enemies or overtime. Environmental slow and native contact/hazard collision remain active. Player max_health=100 preserves real hit i-frames; only current health is an oversized reservoir to accumulate damage without death. Status clocks advance explicitly. TTK: stationary player, unlimited attack reach, 10 hits/s at listed raw DPS, native armor, directional guard, damage budget and health phase pauses; 90s censoring (defeated=false is NOT a kill time). TTK and pressure are separate controlled experiments, not real run builds, win rates or a human difficulty ranking.",
		"waves": sample_waves, "stats": [], "pressure": [], "ttk": [],
	}
	report.method += " Schema 2: release counts use damaging mechanic births (Prince bomb impacts, not both launch and impact); Court releases use native verdict/portal/pulse counters. Prince projectile counts include launched bombs separately from hearts. Attack warnings exclude Court guard turns. State occupancy and stationary time are sampled at 60Hz. Optional flee_wall steers away from the boss while reserving 0.6s room to turn at walls, never reads hazards or warnings."
	for difficulty: DifficultyData in DifficultyCatalog.ALL:
		for wave_number: int in sample_waves:
			var boss := _boss(difficulty, wave_number, 320, SEEDS[0], 0)
			report.stats.append(_stats(boss, wave_number))
			boss.free()
			for phase: int in ([1] if quick else [0, 1, 2]):
				for policy: String in policies:
					for sample_seed: int in ([SEEDS[0]] if quick else SEEDS):
						report.pressure.append(_pressure(difficulty, wave_number, phase, policy, sample_seed))
			for dps: float in ([1000000.0] if quick else RAW_DPS):
				report.ttk.append(_ttk(difficulty, wave_number, dps))
			print("Measured ", difficulty.id, " wave ", wave_number)
	var output := "res://.godot/boss_comparison_quick.json" if quick else "res://docs/boss_comparison_current.json"
	if king_only: output = "res://.godot/king_pressure_quick.json" if quick else "res://docs/king_pressure_after.json"
	if royals_only: output = "res://.godot/royals_pressure_quick.json" if quick else "res://docs/royals_pressure_after.json"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--output="): output = argument.trim_prefix("--output=")
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write " + output)
		finish(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	session.clear_run()
	print("Boss comparison: ", report.pressure.size(), " pressure samples, ", report.ttk.size(), " TTK samples -> ", output)
	finish()


func _boss(difficulty: DifficultyData, wave_number: int, distance: float, sample_seed: int, phase: int) -> Enemy:
	seed(sample_seed)
	var player: Player = game.player
	player.status_effects.clear()
	player.stats.max_health = 100
	# Do not inflate max_health: Player.take_hit derives i-frames from it.
	player.stats.health = HEALTH_RESERVOIR
	player.stats.armor = 0
	player.stats.dodge_chance = 0
	player.stats.shield_charges = 0
	player.stats.regen = 0
	player.hurt_time = 0
	player.dodge_time = 0
	player.dash_moved = false
	player.velocity = Vector2.ZERO
	var bearing := float(SEEDS.find(sample_seed)) * TAU / 3.0
	var centre := player.arena.arena_size * 0.5
	player.global_position = centre + Vector2.from_angle(bearing) * distance * 0.5
	player.get_node("Camera2D").force_update_scroll()
	var boss: Enemy = ENEMY_SCENE.instantiate()
	boss.position = centre - Vector2.from_angle(bearing) * distance * 0.5
	boss.configure(WaveController.boss_for_wave(wave_number), player, wave_number, difficulty.id)
	game.get_node("Enemies").add_child(boss)
	boss.set_simulation_enabled(false)
	boss.boss_phase = phase
	boss.health = boss.max_health * (1.0 - float(phase) / 3.0)
	hits = 0
	status_damage = 0
	first_hit = -1
	sample_time = 0
	return boss


func _stats(boss: Enemy, wave_number: int) -> Dictionary:
	var result := {
		"difficulty": str(boss.difficulty.id), "wave": wave_number, "boss": boss.data.display_name,
		"hp": boss.max_health, "damage_reduction": boss.damage_reduction,
		"effective_hp_before_mechanics": boss.max_health / (1 - boss.damage_reduction),
		"attack_damage": boss.attack_damage, "contact_damage": boss.contact_damage,
		"move_speed": boss.move_speed, "guard_hp_per_second": boss.max_health / boss.data.boss_guard_recharge_seconds,
		"guard_recharge_seconds": boss.data.boss_guard_recharge_seconds,
		"health_phase_pause": boss.data.boss_phase_duration,
	}
	if boss.cloak_encounter != null:
		var p := boss.cloak_encounter.profile
		result["profile"] = {"phase1_strikes": 3 + p.action_bonus, "recovery": p.recovery_seconds, "warning": p.warning_seconds, "followup_warning": p.followup_warning_seconds, "chase_factor": p.chase_factor}
	elif boss.caramel_encounter != null:
		var p := boss.caramel_encounter.profile
		result["profile"] = {"phase1_bombs": p.throws_for_phase(1), "phase1_fan_rays": p.fan_count(1), "phase1_fan_salvos": p.salvos_for_phase(1), "recovery": p.recovery_seconds, "warning": p.heart_warning_seconds, "projectile_speed": p.heart_speed, "rush_distance": p.rush_distance, "reposition_speed_factor": p.reposition_speed_factor, "bomb_frequency": p.bomb_frequency, "bomb_interval": p.bomb_interval()}
	elif boss.acid_king_encounter != null:
		var p := boss.acid_king_encounter.profile
		result["profile"] = {"phase1_rows": p.rows(1), "phase1_shards": p.shard_count(1), "channels": p.channel_count, "shifts": p.shifts, "recovery": p.recovery_seconds, "warning": p.warning_seconds, "projectile_speed": p.shards.speed, "move_factor": p.move_factor, "flow_movement_factor": p.flow_movement_factor, "pursuit_seconds": p.pursuit_seconds, "pursuit_move_factor": p.pursuit_move_factor, "pursuit_distance": p.pursuit_distance, "shift_lead_seconds": p.shift_lead_seconds, "shift_lead_distance": p.shift_lead_distance, "alternate_shift_axis": p.alternate_shift_axis, "combined_phase": p.combined_phase}
		result.profile.merge({"spit_rays": p.spit_count(), "spit_warning": p.spit_warning_seconds, "spit_speed": p.spit.speed, "spit_lifetime": p.spit.lifetime, "stomp_sequences": p.stomp_sequences, "stomp_chase_seconds": p.stomp_chase_seconds})
	elif boss.crown_court_encounter != null:
		var p := boss.crown_court_encounter.profile
		result["profile"] = {"phase1_verdicts": p.verdicts(1), "phase1_portals": p.portals(1), "phase1_pulses": p.pulses(1), "recovery": p.recovery_seconds, "warning": p.warning_seconds, "projectile_speed": p.shots.speed, "move_factor": p.movement_factor, "portal_drift_factor": p.portal_drift_factor}
		result.profile.merge({"last_phase_verdicts": p.verdicts(2), "last_phase_portals": p.portals(2), "last_phase_pulses": p.pulses(2), "max_verdicts": p.max_verdicts, "max_portals": p.max_portals, "max_pulses": p.max_pulses, "turn_seconds": p.turn_seconds, "open_seconds": p.open_seconds, "position_seconds": p.position_seconds, "reposition_seconds": p.reposition_seconds, "court_start_distance": boss.crown_court_encounter.court_start_distance(), "court_radius": p.court_radius})
		result.profile.merge({"followup_warning": p.followup_warning_seconds, "portal_lead_distance": p.portal_lead_distance, "needle_warning": p.needle_warning_seconds, "needle_rays": p.needle_count(), "needle_speed": p.needles.speed, "needle_lifetime": p.needles.lifetime, "guard_turn_during_open": true})
	return result


func _pressure(difficulty: DifficultyData, wave_number: int, phase: int, policy: String, sample_seed: int) -> Dictionary:
	var radius := 160.0 if policy == "orbit_close" else 320.0
	var boss := _boss(difficulty, wave_number, radius, sample_seed, phase)
	var counters := {"warnings": 0, "releases": 0, "last_release": 0.0, "max_release_gap": 0.0, "bombs_launched": 0}
	boss.attack_performed.connect(func(kind: StringName):
		if kind == &"boss_warning": counters.warnings += 1
		elif kind in [&"boss_pulse", &"boss_charge", &"acid"]:
			if boss.caramel_encounter != null and kind == &"boss_charge" and boss.caramel_encounter.state != CaramelEncounter.State.RUSH_ACTIVE:
				counters.bombs_launched += 1
				return
			counters.releases += 1
			counters.max_release_gap = maxf(counters.max_release_gap, sample_time - counters.last_release)
			counters.last_release = sample_time)
	var speed := PlayerStats.BASE_MOVE_SPEED * (1.3 if policy == "orbit_far_fast" else 1.0)
	var boss_distance := 0.0
	var player_distance := 0.0
	var near_seconds := 0.0
	var ranged_seconds := 0.0
	var slow_seconds := 0.0
	var peak_projectiles := 0
	var prince_shots := 0
	var attack_kinds := {}
	var state_seconds := {}
	var stationary_seconds := 0.0
	var court_attack_warnings := 0
	var verdicts_in_sector := 0
	var court_in_range_seconds := 0.0
	for frame in roundi(PRESSURE_SECONDS / STEP):
		sample_time = (frame + 1) * STEP
		var player: Player = game.player
		player.hurt_time = maxf(player.hurt_time - STEP, 0)
		player.dodge_time = maxf(player.dodge_time - STEP, 0)
		var before := player.global_position
		var slow := player.floor_movement_factor()
		if slow < 1: slow_seconds += STEP
		if policy != "stationary":
			var outward := boss.global_position.direction_to(before)
			var correction := clampf((radius - before.distance_to(boss.global_position)) / 80, -1, 1)
			var direction := _flee_direction(player, boss, speed * slow) if policy == "flee_wall" else (outward.orthogonal() + outward * correction).normalized()
			player.global_position = (before + direction * speed * slow * STEP).clamp(Vector2.ONE * DentiArena.PLAYER_MARGIN, player.arena.arena_size - Vector2.ONE * DentiArena.PLAYER_MARGIN)
		player.velocity = (player.global_position - before) / STEP
		player_distance += before.distance_to(player.global_position)
		player.get_node("Camera2D").force_update_scroll()
		var boss_before := boss.global_position
		var prince_state := boss.caramel_encounter.state if boss.caramel_encounter != null else -1
		var court_releases := _court_releases(boss)
		var court_warnings := boss.crown_court_encounter.warnings if boss.crown_court_encounter != null else 0
		var court_verdicts := boss.crown_court_encounter.verdicts_fired if boss.crown_court_encounter != null else 0
		boss._physics_process(STEP)
		player.status_effects.advance(STEP)
		boss_distance += boss_before.distance_to(boss.global_position)
		if boss_before.distance_to(boss.global_position) < 0.01: stationary_seconds += STEP
		var state_name := _state_name(boss)
		state_seconds[state_name] = state_seconds.get(state_name, 0.0) + STEP
		var distance := boss.global_position.distance_to(player.global_position)
		if distance <= 160: near_seconds += STEP
		if distance <= 600: ranged_seconds += STEP
		var shots := 0
		if boss.cloak_encounter != null:
			var attack := boss.cloak_encounter
			if attack.active: attack_kinds[str(attack.variant)] = true
		elif boss.caramel_encounter != null:
			var attack := boss.caramel_encounter
			if attack.active: attack_kinds[str(attack.attack_kind)] = true
			shots = attack.hearts.entries.size()
			if attack.state == CaramelEncounter.State.FLIGHT: shots += 1
			for bomb in attack.bombs.entries:
				if bomb.launched: shots += 1
			if attack.state != prince_state and attack.state in [CaramelEncounter.State.HEART_RELEASE, CaramelEncounter.State.BURST_RELEASE]: prince_shots += attack.rays.size()
		elif boss.acid_king_encounter != null:
			var attack := boss.acid_king_encounter
			if attack.active: attack_kinds[str(attack.attack_kind)] = true
			shots = attack.volley.entries.size() + attack.spit.entries.size()
		elif boss.crown_court_encounter != null:
			var attack := boss.crown_court_encounter
			if attack.active: attack_kinds[str(attack.attack_kind)] = true
			shots = attack.shots.entries.size() + attack.lances.entries.size() + attack.needles.entries.size()
			var released := _court_releases(boss) - court_releases
			if released > 0:
				counters.releases += released
				counters.max_release_gap = maxf(counters.max_release_gap, sample_time - counters.last_release)
				counters.last_release = sample_time
			if attack.warnings > court_warnings and attack.state not in [CrownCourtEncounter.State.TURN, CrownCourtEncounter.State.OPEN]: court_attack_warnings += attack.warnings - court_warnings
			if distance <= attack.court_start_distance(): court_in_range_seconds += STEP
			if attack.verdicts_fired > court_verdicts:
				for side in [0, 1]:
					if HazardGeometry.circle_sector(player.global_position, attack.origin, Vector2.from_angle(attack.edict_angle + side * PI), attack.profile.court_radius, deg_to_rad(attack.profile.court_half_angle)):
						verdicts_in_sector += 1
						break
		peak_projectiles = maxi(peak_projectiles, shots)
	var projectiles: int = prince_shots + counters.bombs_launched
	if boss.acid_king_encounter != null: projectiles = boss.acid_king_encounter.volley.fired + boss.acid_king_encounter.spit.fired
	if boss.crown_court_encounter != null:
		projectiles = boss.crown_court_encounter.shots.fired + boss.crown_court_encounter.lances.fired + boss.crown_court_encounter.needles.fired
		counters.warnings = boss.crown_court_encounter.warnings
	var result := {
		"difficulty": str(difficulty.id), "wave": wave_number, "phase": phase, "policy": policy, "seed": sample_seed,
		"seconds": PRESSURE_SECONDS, "damage_taken": HEALTH_RESERVOIR - game.player.stats.health,
		"direct_hits": hits, "status_damage": status_damage, "first_hit_seconds": first_hit,
		"warnings": counters.warnings, "projectiles_fired": projectiles, "peak_projectiles": peak_projectiles,
		"attack_releases": counters.releases, "max_release_gap_seconds": maxf(counters.max_release_gap, PRESSURE_SECONDS - counters.last_release),
		"boss_distance": boss_distance, "player_distance": player_distance,
		"melee_uptime": near_seconds / PRESSURE_SECONDS, "ranged_uptime": ranged_seconds / PRESSURE_SECONDS,
		"slow_seconds": slow_seconds, "attack_kinds": attack_kinds.keys(),
		"stationary_seconds": stationary_seconds, "state_seconds": state_seconds,
		"attack_warnings": court_attack_warnings if boss.crown_court_encounter != null else counters.warnings,
	}
	if boss.caramel_encounter != null:
		result.merge({"bombs_launched": counters.bombs_launched, "heart_projectiles_fired": prince_shots})
	if boss.crown_court_encounter != null:
		var attack := boss.crown_court_encounter
		result.merge({"verdicts_fired": attack.verdicts_fired, "portals_fired": attack.portals_fired, "pulses_fired": attack.pulses_fired, "verdicts_target_in_sector_at_release": verdicts_in_sector, "court_in_range_seconds": court_in_range_seconds})
		result["needle_projectiles_fired"] = attack.needles.fired
	boss.free()
	return result


func _court_releases(boss: Enemy) -> int:
	var court := boss.crown_court_encounter
	return court.verdicts_fired + court.portals_fired + court.pulses_fired if court != null else 0


func _state_name(boss: Enemy) -> String:
	if boss.cloak_encounter != null: return CloakEncounter.State.keys()[boss.cloak_encounter.state]
	if boss.caramel_encounter != null: return CaramelEncounter.State.keys()[boss.caramel_encounter.state]
	if boss.acid_king_encounter != null: return AcidKingEncounter.State.keys()[boss.acid_king_encounter.state]
	return CrownCourtEncounter.State.keys()[boss.crown_court_encounter.state]


func _flee_direction(player: Player, boss: Enemy, speed: float) -> Vector2:
	var at := player.global_position
	var low := Vector2.ONE * DentiArena.PLAYER_MARGIN
	var high := player.arena.arena_size - low
	var away := boss.global_position.direction_to(at)
	var best := away
	var score := -INF
	for index in 32:
		var direction := Vector2.from_angle(index * TAU / 32)
		var projected := at + direction * speed * 0.6
		if projected != projected.clamp(low, high): continue
		var value := direction.dot(away) + direction.dot(player.velocity.normalized()) * 0.2
		if value > score: score = value; best = direction
	return best


func _ttk(difficulty: DifficultyData, wave_number: int, dps: float) -> Dictionary:
	var boss := _boss(difficulty, wave_number, 320, SEEDS[0], 0)
	var blocked_seconds := 0.0
	var spent_budget_seconds := 0.0
	for frame in roundi(TTK_LIMIT / STEP):
		sample_time = (frame + 1) * STEP
		game.player.hurt_time = maxf(game.player.hurt_time - STEP, 0)
		game.player.get_node("Camera2D").force_update_scroll()
		boss._physics_process(STEP)
		if boss.boss_phase_timer > 0: blocked_seconds += STEP
		if boss.boss_damage_budget < boss.max_health * 0.01: spent_budget_seconds += STEP
		if frame % 6 == 0:
			boss.take_damage(dps * 0.1, null, false, &"", [], game.player.global_position.direction_to(boss.global_position))
		if boss.dying: break
	var result := {
		"difficulty": str(difficulty.id), "wave": wave_number, "raw_dps": dps,
		"defeated": boss.dying, "seconds": sample_time, "remaining_hp_fraction": boss.health / boss.max_health,
		"phase": boss.boss_phase, "phase_pause_seconds": blocked_seconds,
		"low_damage_budget_seconds": spent_budget_seconds,
	}
	boss.free()
	return result
