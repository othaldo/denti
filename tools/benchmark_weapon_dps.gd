extends SceneTree

# Actual attacks at 60 Hz, including projectiles, focus, innate crit and bleed.
# Anchored targets isolate throughput; knockback, enemy AI and guard are excluded.
const SECONDS := 30.0
const STEP := 1.0 / 60.0
const TARGET_HP := 1000000.0
const SCENARIOS := ["close", "single", "pack", "lane", "boss", "edge"]
var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	_setup()
	var report := {"seconds": SECONDS, "hz": 60, "seed": 13579,
		"method": "One weapon, tiers I-IV, default stats (5% crit), no items/relics. Anchored immortal targets at 50% HP (no repeated fresh-target cut bonus), no AI/armor/guard/knockback displacement. Close=45px; single/boss=65% range; pack=five targets at 65% range, angles 0,+/-12,+/-24 degrees; lane=five collinear targets at 25/40/55/70/85% range; edge=full range (contact weapons only). Real projectiles/contact/bleed/focus; direct and bleed damage counted separately. Includes initial attack staggering and projectile flight; not a win-rate or TTK test.",
		"estimates": [], "measurements": []}
	for data in WeaponCatalog.ALL:
		for tier in range(1, 5):
			var stats := PlayerStats.new()
			report.estimates.append({"weapon": str(data.id), "name": data.display_name, "tier": tier,
				"roots": data.hands, "family": data.damage_stat, "range": data.range_at_tier(tier),
				"dps": data.estimated_dps(tier, stats), "dps_per_root": data.estimated_dps(tier, stats) / data.hands})
			stats.free()
			for scenario in SCENARIOS:
				if scenario == "edge" and not WeaponMotion.is_contact(data):
					continue
				report.measurements.append(_measure(data, tier, scenario))
		print("Measured " + data.display_name)
	var before := OS.get_cmdline_user_args().has("--before")
	var output := "res://docs/balance_weapon_dps_%s.json" % ("before" if before else "after")
	var file := FileAccess.open(output, FileAccess.WRITE)
	if file == null:
		push_error("Cannot write " + output)
		quit(1)
		return
	file.store_string(JSON.stringify(report, "\t") + "\n")
	file.close()
	_cleanup()
	print("Weapon DPS report: " + output)
	quit(0)


func _setup() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://benchmark_weapon_dps.json"
	session.resume_requested = false
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	paused = true
	game.player.attack_performed.disconnect(game.sound.play_attack)


func _cleanup() -> void:
	root.get_node("GameSession").clear_run()
	game.free()
	paused = false


func _measure(data: WeaponData, tier: int, scenario: String) -> Dictionary:
	seed(13579)
	for container in ["Enemies", "Projectiles", "EnemyProjectiles"]:
		for node in game.get_node(container).get_children():
			node.free()
	game.boss = null
	game.player.loadout.restore([{"id": str(data.id), "tier": tier}])
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	weapon.set_physics_process(false)
	var distance := 45.0 if scenario == "close" else data.range_at_tier(tier) * (1.0 if scenario == "edge" else 0.65)
	var targets: Array[Enemy] = []
	var positions: Array[Vector2] = []
	var totals := {"direct": 0.0, "bleed": 0.0, "hits": 0}
	var angles: Array = [0.0, 12.0, -12.0, 24.0, -24.0] if scenario == "pack" else ([0.0, 0.0, 0.0, 0.0, 0.0] if scenario == "lane" else [0.0])
	for index in angles.size():
		var target_distance := data.range_at_tier(tier) * (0.25 + float(index) * 0.15) if scenario == "lane" else distance
		var position: Vector2 = game.player.global_position + Vector2.RIGHT.rotated(deg_to_rad(angles[index])) * target_distance
		game._create_enemy(WaveController.BOSS if scenario == "boss" else WaveController.PLAQUE, position)
		var enemy: Enemy = game.get_node("Enemies").get_child(-1)
		enemy.damaged.disconnect(game._on_enemy_damaged)
		enemy.data = enemy.data.duplicate()
		enemy.data.boss_guard_recharge_seconds = 0.0
		enemy.boss_phase = 2
		enemy.health = TARGET_HP * 0.5
		enemy.max_health = TARGET_HP
		enemy.damage_reduction = 0.0
		enemy.target = null
		enemy.set_physics_process(false)
		enemy.damage_recorded.connect(func(amount: float, _id: StringName, proc: StringName) -> void:
			if proc == &"bleed":
				totals.bleed += amount
			else:
				totals.direct += amount
				totals.hits += 1)
		targets.append(enemy)
		positions.append(position)
	for frame in int(SECONDS / STEP):
		for index in targets.size():
			targets[index].global_position = positions[index]
			targets[index].spatial_index.update(targets[index])
		weapon._physics_process(STEP)
		for projectile: WeaponProjectile in game.get_node("Projectiles").get_children():
			if not projectile.is_queued_for_deletion():
				projectile._physics_process(STEP)
			if projectile.is_queued_for_deletion():
				projectile.free()
		for enemy in targets:
			enemy._physics_process(STEP)
	var dps := (float(totals.direct) + float(totals.bleed)) / SECONDS
	return {"weapon": str(data.id), "tier": tier, "scenario": scenario, "distance": distance,
		"direct_dps": float(totals.direct) / SECONDS, "bleed_dps": float(totals.bleed) / SECONDS,
		"total_dps": dps, "dps_per_root": dps / data.hands, "hits": totals.hits}
