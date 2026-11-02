extends RefCounted
## A common virtual 1280x720 viewport, independent of native rendering/speed.
## No spawn plan, future aim, hidden cooldowns, or combat RNG is exposed.

const VIEW_HALF := Vector2(640, 360)
const MAX_ENEMIES := 32
const MAX_PROJECTILES := 64
const BOSS_OBSERVATION = preload("res://tools/balance/bots/boss_observation.gd")
var previous_positions: Dictionary = {}
var previous_frame := -1

func reset() -> void:
	previous_positions.clear()
	previous_frame = -1

func capture(game, frame: int) -> Dictionary:
	var player: Player = game.player
	var at := player.global_position
	var arena := player.arena.arena_size
	var half := VIEW_HALF.min(arena * 0.5)
	# The actual camera follows Denti even near walls. Do not shift the sensor
	# inward there: that would reveal enemies outside the displayed viewport.
	var visible_area := Rect2(at - half, half * 2)
	var enemies: Array[Dictionary] = []
	var projectiles: Array[Dictionary] = []
	var hazards: Array[Dictionary] = []
	var loot: Array[Vector2] = []
	var positions: Dictionary = {}
	for enemy: Enemy in game.get_node("Enemies").get_children():
		if enemy.health <= 0 or enemy.is_queued_for_deletion(): continue
		# A floor warning/projectile can be visible while its owner is offscreen.
		BOSS_OBSERVATION.capture(enemy, visible_area, hazards, projectiles)
		if not visible_area.grow(enemy.data.radius).has_point(enemy.global_position): continue
		var id := enemy.get_instance_id()
		var velocity := Vector2.ZERO
		if previous_positions.has(id) and frame > previous_frame:
			velocity = (enemy.global_position - Vector2(previous_positions[id])) * 60.0 / (frame - previous_frame)
		positions[id] = enemy.global_position
		enemies.append({"position": enemy.global_position, "velocity": velocity.limit_length(650), "radius": enemy.data.radius, "boss": enemy.data.is_boss})
		if enemy.special_phase == Enemy.SpecialPhase.WARNING:
			if enemy.active_special_attack == EnemyData.SpecialAttack.DASH or enemy.active_special_attack == EnemyData.SpecialAttack.BOSS and enemy.boss_move == Enemy.BossMove.CHARGE:
				hazards.append({"shape": "capsule", "position": enemy.to_global(enemy.warning_lane_start()), "end": enemy.to_global(enemy.warning_lane_end()), "radius": enemy.warning_lane_half_width(), "time": enemy.special_timer})
			elif enemy.active_special_attack == EnemyData.SpecialAttack.PULSE:
				hazards.append({"shape": "circle", "position": enemy.global_position, "radius": enemy.data.attack_radius, "time": enemy.special_timer})
		var cloak := enemy.cloak_encounter
		if cloak != null and cloak.state in [CloakEncounter.State.WARNING, CloakEncounter.State.STRIKE]:
			var shape := cloak.profile.strike(cloak.variant)
			var age := cloak.profile.strike_seconds - cloak.remaining if cloak.state == CloakEncounter.State.STRIKE else 0.0
			if cloak.state == CloakEncounter.State.WARNING or age < cloak.profile.hit_end:
				hazards.append({"shape": "sector", "position": cloak.origin, "direction": cloak.direction,
					"radius": shape.reach, "inner": shape.inner_radius,
					"angle": PI if cloak.variant == CloakStrikeData.Kind.RING else cloak.half_angle,
					"time": cloak.remaining + cloak.profile.hit_start if cloak.state == CloakEncounter.State.WARNING else maxf(cloak.profile.hit_start - age, 0),
					"duration": cloak.profile.hit_end - maxf(age, cloak.profile.hit_start)})
	previous_positions = positions
	previous_frame = frame
	for projectile: AcidProjectile in game.get_node("EnemyProjectiles").get_children():
		if projectile.lifetime <= 0 or projectile.is_queued_for_deletion() or not visible_area.grow(projectile.hit_radius).has_point(projectile.global_position): continue
		projectiles.append({"position": projectile.global_position, "velocity": projectile.direction * projectile.speed, "radius": projectile.hit_radius, "life": projectile.lifetime})
	for drop: Loot in game.get_node("Loot").get_children():
		if not drop.is_queued_for_deletion() and visible_area.has_point(drop.global_position): loot.append(drop.global_position)
	enemies.sort_custom(func(a: Dictionary, b: Dictionary): return at.distance_squared_to(a.position) < at.distance_squared_to(b.position))
	projectiles.sort_custom(func(a: Dictionary, b: Dictionary): return at.distance_squared_to(a.position) < at.distance_squared_to(b.position))
	var reach := INF
	for weapon: WeaponInstance in player.loadout.equipped(): reach = minf(reach, weapon.data.range_at_tier(weapon.tier))
	return {"frame": frame, "position": at, "velocity": player.velocity, "arena": arena, "speed": player.stats.move_speed,
		"reach": reach if is_finite(reach) else 100.0, "health": player.stats.health / player.stats.max_health,
		"dash_distance": player.dash.config.distance, "dash_seconds": player.dash.config.duration, "dash_ready": player.dash.ready_to_dash(),
		"enemies": enemies.slice(0, MAX_ENEMIES), "projectiles": projectiles.slice(0, MAX_PROJECTILES), "hazards": hazards, "loot": loot}
