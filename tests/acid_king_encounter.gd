extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []
var game: Node2D
var boss: Enemy
var attack: AcidKingEncounter

func _initialize() -> void: call_deferred("_run")
func _check(ok: bool, message: String) -> void:
	if ok: return
	failures.append(message)
	push_error(message)

func _fresh(kind: int = 0, phase: int = 0) -> void:
	attack.cancel()
	attack.cycle = 0
	boss.boss_phase = phase
	boss.boss_phase_timer = 0
	boss.contact_timer = 0
	boss.global_position = Vector2(770, 620)
	game.player.global_position = Vector2(1050, 650)
	game.player.velocity = Vector2.ZERO
	game.player.stats.health = 10000
	game.player.hurt_time = 0
	game.player.dash_moved = false
	game.player.get_node("Camera2D").force_update_scroll()
	attack.begin(kind)

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://acid_king_test.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	game.wave.current_wave = 15
	game.wave.set_process(false)
	game.player.set_physics_process(false)
	game.player.loadout.restore([])
	game.player.stats.max_health = 10000
	game.player.stats.health = 10000
	game.player.stats.shield_charges = 0
	game.player.stats.dodge_chance = 0
	game._create_enemy(EnemyCatalog.CAVITY_KING, Vector2(770, 620))
	boss = game.boss
	attack = boss.acid_king_encounter
	boss.set_simulation_enabled(false)
	game.get_node("Enemies").set_physics_process(false)
	paused = true
	_check(attack != null and attack.rig.bones.size() == 6, "King is not using the modular collector encounter")
	for bone: Bone2D in attack.rig.bones.values(): _check(bone.scale == Vector2.ONE, "rig stretches painted anatomy")
	_fresh()
	var planned := attack.pending.duplicate(true)
	game.player.global_position += Vector2(200, 220)
	attack.advance(attack.profile.warning_seconds - 0.001)
	_check(attack.fields.is_empty() and attack.pending == planned and game.player.stats.health == 10000, "river moved its warning or dealt premature damage")
	attack.advance(0.001)
	_check(attack.fields.size() == 2 and attack.fields[0].at == planned[0].at, "river activation differs from its warning")
	_fresh()
	attack.advance(attack.profile.warning_seconds + 0.01)
	_check(game.player.stats.health < 10000, "river omitted the lane through stationary Denti")
	var hit_health: float = game.player.stats.health
	game.player.hurt_time = 0
	attack.advance(0.1)
	_check(game.player.stats.health == hit_health, "river damage repeats every frame instead of its tick interval")
	# An ordinary dash still crosses dangerous acid; final endpoints are both clear.
	game.player.hurt_time = 0
	var field := attack.fields[0]
	var cross := Vector2.RIGHT if attack.axis == 0 else Vector2.DOWN
	game.player.motion_start = field.at - cross * 120
	game.player.motion_end = field.at + cross * 120
	game.player.global_position = game.player.motion_end
	game.player.motion_tick = Engine.get_physics_frames()
	game.player.dash_motion_seconds = 0.16
	game.player.dash_moved = true
	attack.fields[0].cooldown = 0
	attack.advance(0.16)
	_check(game.player.stats.health < hit_health, "dash tunneled through the river")
	# The rounded visible cap is also the collision cap. Camera movement cannot
	# extend a locked world-space channel or reveal a newly clipped endpoint.
	game.player.dash_moved = false
	var fixed_ends := AcidKingVisuals.channel_ends(field)
	var along := fixed_ends[0].direction_to(fixed_ends[1])
	for tip in [0, 1]:
		var outward := along * (-1 if tip == 0 else 1)
		game.player.global_position = fixed_ends[tip] + outward * 42
		_check(HazardGeometry.swept_capsule(game.player, fixed_ends[0], fixed_ends[1], 24, 0, 0.01), "rounded acid cap omitted its visible tip")
		game.player.global_position = fixed_ends[tip] + outward * 46
		_check(not HazardGeometry.swept_capsule(game.player, fixed_ends[0], fixed_ends[1], 24, 0, 0.01), "acid damages beyond its rounded end plus player radius")
		game.player.global_position = fixed_ends[tip] + outward * 35 + cross * 35
		_check(not HazardGeometry.swept_capsule(game.player, fixed_ends[0], fixed_ends[1], 24, 0, 0.01), "acid cap still has a rectangular collision corner")
		game.player.get_node("Camera2D").force_update_scroll()
		_check(AcidKingVisuals.channel_ends(attack.fields[0]) == fixed_ends, "camera movement changed a world-space river endpoint")
	_fresh(AcidKingEncounter.Attack.TIDE)
	attack.advance(attack.profile.warning_seconds + attack.profile.shift_flow_seconds)
	_check(attack.state == AcidKingEncounter.State.WARN_SHIFT and attack.pending.size() == 2, "tide did not warn its next banks")
	planned = attack.pending.duplicate(true)
	attack.advance(attack.profile.old_channel_fade + 0.001)
	_check(attack.fields.is_empty() and attack.state == AcidKingEncounter.State.WARN_SHIFT, "old banks did not drain before the shift")
	game.player.global_position += Vector2(200, -120)
	attack.advance(attack.remaining)
	_check(attack.fields.size() == 2 and attack.fields[0].at == planned[0].at, "shift chased Denti or changed its promised location")
	# One long frame splits at every fissure, so newly launched shards only move
	# for the time after their own impact.
	_fresh(AcidKingEncounter.Attack.STOMP)
	var row_origin: Vector2 = attack.rows[0].at
	var direction: Vector2 = EnemyProjectilePatterns.fan_directions(attack.aim, attack.profile.shard_count(0), deg_to_rad(18))[0]
	game.player.global_position += Vector2(0, 500)
	var fired_before := attack.volley.fired
	attack.advance(attack.profile.stomp_warning_seconds + 0.12)
	_check(attack.volley.fired - fired_before == attack.profile.shard_count(0), "fissure shots were emitted early or silently skipped")
	_check(attack.volley.entries[0].at.is_equal_approx(row_origin + direction * attack.profile.shards.speed * 0.12), "long frame advanced shards before their birth")
	_fresh(AcidKingEncounter.Attack.STOMP)
	game.player.global_position = attack.rows[0].at
	attack.advance(attack.profile.stomp_warning_seconds - 0.001)
	_check(game.player.stats.health == 10000 and attack.volley.entries.is_empty(), "stomp hit during its preparation")
	attack.advance(0.011)
	_check(game.player.stats.health < 10000 and attack.rows[0].hit, "stomp missed stationary Denti")
	hit_health = game.player.stats.health
	var hit_save := EnemySnapshot.capture(boss)
	EnemySnapshot.restore(boss, hit_save)
	game.player.hurt_time = 0
	attack.advance(0.02)
	_check(game.player.stats.health == hit_health, "resume replayed an already resolved fissure impact")
	# Core exposure changes real incoming damage, without changing the HP pool.
	_fresh()
	boss.boss_phase = 2
	boss.health = boss.max_health
	boss.boss_damage_budget = boss.max_health
	var original_max := boss.max_health
	var closed := boss.take_damage(20)
	attack.state = AcidKingEncounter.State.OPEN
	boss.boss_damage_budget = boss.max_health
	var exposed := boss.take_damage(20)
	_check(exposed > closed * 1.4 and boss.max_health == original_max, "open collector core does not create an actual counterattack window")
	# All states and live owned hazards survive pause/snapshot restore exactly.
	for kind in [0, 1, 2]:
		_fresh(kind, 2)
		for seconds in [0.2, 0.85, 0.3, 0.5, 0.9, 1.1, 1.6]:
			attack.advance(seconds)
			var before := attack.save_data()
			var saved := EnemySnapshot.capture(boss)
			_check(not RunSaveData.normalize({"wave": 15, "player": {}, "enemies": [saved]}).is_empty(), "normalization rejected valid King state")
			EnemySnapshot.restore(boss, saved)
			_check(attack.save_data() == before, "King snapshot changed its warning, rows or live hazards")
	var frozen := attack.save_data()
	await process_frame
	await process_frame
	_check(attack.save_data() == frozen, "paused King continued the attack clock")
	for bad in [{"rows": [1]}, {"fields": [{"at": [1, 2], "half_size": [3]}]}, {"projectiles": [{"position": [1, 2], "velocity": [0, "bad"], "life": 1, "damage": 1}]}, {"state": "bad"}, {"rows": [{"at": [1, 2], "direction": [1, 0], "delay": 0, "fired": [], "hit": false}]}]:
		_check(RunSaveData.normalize({"wave": 15, "player": {}, "enemies": [{"acid_king": bad}]}).is_empty(), "invalid King save entered the runtime")
	_fresh()
	attack.restore({})
	_check(attack.state == AcidKingEncounter.State.POSITION and not attack.active and attack.fields.is_empty(), "legacy King save immediately activated new hazards")
	# Actual game reload while both old banks and the next warning are present.
	_fresh(AcidKingEncounter.Attack.TIDE)
	attack.advance(attack.profile.warning_seconds + attack.profile.shift_flow_seconds + 0.1)
	var pending_save := attack.save_data()
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	boss = game.boss
	attack = boss.acid_king_encounter
	game.player.set_physics_process(false)
	game.get_node("Enemies").set_physics_process(false)
	boss.set_simulation_enabled(false)
	paused = true
	_check(attack.state == AcidKingEncounter.State.WARN_SHIFT and attack.pending.size() == pending_save.pending.size() and attack.fields.size() == pending_save.fields.size(), "actual King reload lost the in-flight bank transition")
	BossAttackController.start_boss_phase(boss)
	_check(attack.fields.is_empty() and attack.pending.is_empty() and attack.volley.entries.is_empty() and boss.boss_phase_burst_fired, "King phase transition retained hazards or added generic salvos")
	_fresh(AcidKingEncounter.Attack.STOMP, 2)
	attack.advance(attack.profile.stomp_warning_seconds + 0.1)
	boss.health = 1
	boss.boss_damage_budget = boss.max_health
	boss.take_damage(1000)
	_check(boss.dying and attack.volley.entries.is_empty() and attack.fields.is_empty(), "dead King retained damaging hazards")
	session.clear_run()
	if failures.is_empty(): print("PASS acid_king_encounter: fixed rivers, drained shifts, staggered fissures, swept dash hazards, timed shards, exposure, pause, legacy and actual save/resume")
	finish(0 if failures.is_empty() else 1)
