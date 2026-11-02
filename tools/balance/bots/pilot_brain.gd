extends RefCounted
## Deterministic delayed perception. This RNG never consumes combat/shop draws.

const PROFILE = preload("res://tools/balance/bots/pilot_profile.gd")
const PROFILES := {
	"novice": preload("res://tools/balance/bots/novice.tres"),
	"regular": preload("res://tools/balance/bots/regular.tres"),
	"expert": preload("res://tools/balance/bots/expert.tres"),
}
const STRATEGIES := ["aggressive", "kite", "collector", "boss"]
const PLAYER_RADIUS := 18.0
var profile: PROFILE
var strategy := "kite"
var rng := RandomNumberGenerator.new()
var pending: Array[Dictionary] = []
var direction := Vector2.ZERO
var dash := false
var decisions := 0
var mistakes := 0
var dash_requests := 0
var observed_warnings := 0
var observed_projectiles := 0
var action_digest := 5381

func configure(skill: String, tactic: String, sample_seed: int) -> void:
	profile = PROFILES[skill]
	strategy = tactic
	rng.seed = sample_seed + 15485863

func begin_wave() -> void:
	pending.clear()
	direction = Vector2.ZERO
	dash = false

func step(frame: int, observation: Dictionary) -> Vector2:
	dash = false
	if frame % int(profile.decision_ticks) == 0:
		pending.append({"ready": frame + int(profile.reaction_ticks), "world": observation})
	if pending.is_empty() or int(pending[0].ready) > frame:
		return direction
	var world: Dictionary = pending.pop_front().world
	decisions += 1
	observed_warnings += world.hazards.size() if profile.reads_warnings else 0
	observed_projectiles += world.projectiles.size()
	var desired := goal_direction(world)
	var best := Vector2.ZERO
	var best_cost := INF
	for index in range(-1, 16):
		var candidate := Vector2.ZERO if index < 0 else Vector2.RIGHT.rotated(TAU * index / 16.0)
		var cost := candidate.distance_squared_to(desired) + danger(world, candidate) * float(profile.avoidance_weight)
		if cost < best_cost:
			best_cost = cost
			best = candidate
	# Draw twice on every decision, even on the error-free profile.
	var error_roll := rng.randf()
	var error_angle := rng.randf_range(-1, 1)
	if error_roll < float(profile.mistake_chance):
		best = best.rotated(deg_to_rad(float(profile.mistake_angle_degrees)) * error_angle)
		mistakes += 1
	direction = best
	var standing_danger := danger(world, Vector2.ZERO)
	# A dash is requested only if the full route is visibly safer than staying.
	dash = profile.uses_dash and bool(world.get("dash_ready", false)) and not direction.is_zero_approx() and standing_danger >= float(profile.dash_danger_threshold) and dash_risk(world, direction) < standing_danger * 0.65
	if dash: dash_requests += 1
	action_digest = ((action_digest * 33) ^ (roundi(direction.angle() * 1000) + (1 if dash else 0))) & 0x7fffffff
	return direction

func goal_direction(world: Dictionary) -> Vector2:
	var at: Vector2 = world.position
	var selected: Dictionary = {}
	var distance := INF
	for enemy: Dictionary in world.enemies:
		var score := at.distance_squared_to(enemy.position)
		if strategy == "boss" and enemy.boss: score -= 10000000
		if score < distance:
			distance = score
			selected = enemy
	if strategy == "collector" and not world.loot.is_empty():
		var goal: Vector2 = world.loot[0]
		for point: Vector2 in world.loot:
			if at.distance_squared_to(point) < at.distance_squared_to(goal): goal = point
		return at.direction_to(goal)
	if selected.is_empty():
		return at.direction_to(Vector2(world.arena) * 0.5).rotated(0.55)
	var offset: Vector2 = selected.position - at
	var inward := offset.normalized() if not offset.is_zero_approx() else Vector2.RIGHT
	var ratio := 0.50 if strategy == "aggressive" else 0.85
	var desired_range := float(selected.radius) + float(world.reach) * ratio
	var radial := clampf((offset.length() - desired_range) / 90.0, -1, 1)
	return (inward * radial + inward.orthogonal() * (0.30 if strategy == "aggressive" else 0.65)).limit_length(1)

func danger(world: Dictionary, candidate: Vector2, horizon: float = -1) -> float:
	var seconds := float(profile.prediction_seconds) if horizon < 0 else horizon
	var at: Vector2 = world.position
	var velocity: Vector2 = candidate * float(world.speed)
	var end := at + velocity * seconds
	var margin := DentiArena.PLAYER_MARGIN + 8
	if end != end.clamp(Vector2.ONE * margin, Vector2(world.arena) - Vector2.ONE * margin): return 1000
	var result := 0.0
	for enemy: Dictionary in world.enemies:
		result += _collision_risk(enemy.position - at, Vector2(enemy.velocity) - velocity, float(enemy.radius) + PLAYER_RADIUS + 10, seconds)
	for projectile: Dictionary in world.projectiles:
		result += _collision_risk(projectile.position - at, Vector2(projectile.velocity) - velocity, float(projectile.radius) + 6, minf(seconds, float(projectile.life))) * 2
	if profile.reads_warnings:
		for hazard: Dictionary in world.hazards:
			if float(hazard.time) > seconds: continue
			for fraction in [0.0, 0.5, 1.0]:
				if _hazard_contains(hazard, at + velocity * seconds * fraction):
					result += 2.0
					break
	return result

func dash_risk(world: Dictionary, candidate: Vector2) -> float:
	var result := 0.0
	# Dash contact remains dangerous in Denti: check the whole path, not just landing.
	var start: Vector2 = world.position
	var end := start + candidate * float(world.dash_distance)
	var margin := DentiArena.PLAYER_MARGIN + 8
	if end != end.clamp(Vector2.ONE * margin, Vector2(world.arena) - Vector2.ONE * margin): return 1000
	for enemy: Dictionary in world.enemies:
		var near := Geometry2D.get_closest_point_to_segment(enemy.position, start, end)
		if near.distance_to(enemy.position) < float(enemy.radius) + PLAYER_RADIUS: result += 3
	var seconds := maxf(float(world.get("dash_seconds", 0.15)), 0.001)
	var velocity := (end - start) / seconds
	for projectile: Dictionary in world.projectiles:
		result += _collision_risk(projectile.position - start, Vector2(projectile.velocity) - velocity, float(projectile.radius) + 6, minf(seconds, float(projectile.life))) * 2
	if profile.reads_warnings:
		for hazard: Dictionary in world.hazards:
			for step in 5:
				var time := seconds * step / 4.0
				if float(hazard.time) <= time and _hazard_contains(hazard, start + velocity * time):
					result += 2
					break
	var landing := world.duplicate()
	landing.position = end
	return result + danger(landing, Vector2.ZERO, 0.2)

static func _collision_risk(offset: Vector2, velocity: Vector2, radius: float, seconds: float) -> float:
	var time := clampf(-offset.dot(velocity) / maxf(velocity.length_squared(), 0.001), 0, seconds)
	var distance := (offset + velocity * time).length()
	return maxf(1.0 - distance / maxf(radius, 1), 0.0) * (1.0 + 0.3 / (time + 0.2))

static func _hazard_contains(hazard: Dictionary, point: Vector2) -> bool:
	if hazard.get("shape", "circle") == "capsule":
		return Geometry2D.get_closest_point_to_segment(point, hazard.position, hazard.end).distance_to(point) <= float(hazard.radius) + PLAYER_RADIUS
	var offset: Vector2 = point - Vector2(hazard.position)
	var distance := offset.length()
	if distance > float(hazard.radius) + PLAYER_RADIUS or distance < maxf(float(hazard.get("inner", 0)) - PLAYER_RADIUS, 0): return false
	if hazard.get("shape", "circle") == "sector" and distance > PLAYER_RADIUS:
		return absf(Vector2(hazard.direction).angle_to(offset)) <= float(hazard.angle) + asin(minf(PLAYER_RADIUS / distance, 1))
	return true

func metrics() -> Dictionary:
	return {"decisions": decisions, "mistakes": mistakes, "dash_requests": dash_requests,
		"observed_warnings": observed_warnings, "observed_projectiles": observed_projectiles, "action_digest": action_digest}
