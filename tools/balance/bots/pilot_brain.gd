extends RefCounted
## Deterministic delayed perception. This RNG never consumes combat/shop draws.

const PROFILE = preload("res://tools/balance/bots/pilot_profile.gd")
const HAZARDS = preload("res://tools/balance/bots/pilot_hazards.gd")
const PROFILES := {
	"novice": preload("res://tools/balance/bots/novice.tres"),
	"regular": preload("res://tools/balance/bots/regular.tres"),
	"expert": preload("res://tools/balance/bots/expert.tres"),
}
const STRATEGIES := ["aggressive", "kite", "collector", "boss", "orbit"]
const PLAYER_RADIUS := 18.0
const WARNING_SPEEDS := [1.0, 0.65, 0.35]
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
	if strategy == "orbit":
		# Deliberately blind control: fixed manual-looking movement, no attacks,
		# loot, warnings or dash decisions. This is not a novice human model.
		var angle := float(frame) / 60 * 0.65
		var target := Vector2(observation.get("arena", Vector2(2400, 1400))) * 0.5 + Vector2(cos(angle) * 300, sin(angle) * 200)
		if not observation.is_empty(): direction = Vector2(observation.position).direction_to(target)
		return direction
	if frame % int(profile.decision_ticks) == 0:
		pending.append({"ready": frame + int(profile.reaction_ticks), "world": observation})
	if pending.is_empty() or int(pending[0].ready) > frame:
		return direction
	var world: Dictionary = _predict_observation(pending.pop_front().world, frame)
	decisions += 1
	observed_warnings += world.hazards.size() if profile.reads_warnings else 0
	observed_projectiles += world.projectiles.size()
	var desired := goal_direction(world)
	var best := Vector2.ZERO
	var best_cost := INF
	var speeds := WARNING_SPEEDS if profile.reads_warnings and not world.hazards.is_empty() else [1.0]
	for index in range(-1, 16):
		for speed: float in speeds:
			var candidate := Vector2.ZERO if index < 0 else Vector2.RIGHT.rotated(TAU * index / 16.0) * speed
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
		result += _projectile_risk(projectile, at, velocity, seconds) * 2
	if profile.reads_warnings:
		for hazard: Dictionary in world.hazards:
			result += HAZARDS.risk(hazard, at, velocity, seconds)
	return result

func dash_risk(world: Dictionary, candidate: Vector2) -> float:
	var result := 0.0
	# Dash contact remains dangerous in Denti: check the whole path, not just landing.
	var start: Vector2 = world.position
	var end := start + candidate.normalized() * float(world.dash_distance)
	var margin := DentiArena.PLAYER_MARGIN + 8
	if end != end.clamp(Vector2.ONE * margin, Vector2(world.arena) - Vector2.ONE * margin): return 1000
	for enemy: Dictionary in world.enemies:
		var near := Geometry2D.get_closest_point_to_segment(enemy.position, start, end)
		if near.distance_to(enemy.position) < float(enemy.radius) + PLAYER_RADIUS: result += 3
	var seconds := maxf(float(world.get("dash_seconds", 0.15)), 0.001)
	var velocity := (end - start) / seconds
	for projectile: Dictionary in world.projectiles:
		result += _projectile_risk(projectile, start, velocity, seconds) * 2
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

static func _projectile_risk(projectile: Dictionary, at: Vector2, velocity: Vector2, seconds: float) -> float:
	var delay := maxf(float(projectile.get("delay", 0)), 0)
	var active := minf(seconds - delay, float(projectile.life))
	if active <= 0: return 0
	return _collision_risk(projectile.position - at - velocity * delay, Vector2(projectile.velocity) - velocity,
		float(projectile.radius) + 6, active)

static func _hazard_contains(hazard: Dictionary, point: Vector2) -> bool:
	return HAZARDS.contains(hazard, point)

func _predict_observation(observed: Dictionary, frame: int) -> Dictionary:
	var world := observed.duplicate(true)
	var age := maxf((frame - int(world.get("frame", frame))) / 60.0, 0)
	world.position += Vector2(world.get("velocity", Vector2.ZERO)) * age
	for enemy: Dictionary in world.enemies: enemy.position += Vector2(enemy.velocity) * age
	for projectile: Dictionary in world.projectiles:
		var delay := float(projectile.get("delay", 0))
		var flying := maxf(age - delay, 0)
		projectile.position += Vector2(projectile.velocity) * flying
		projectile.life = maxf(float(projectile.life) - flying, 0)
		projectile.delay = maxf(delay - age, 0)
	for hazard: Dictionary in world.hazards: hazard.time = float(hazard.time) - age
	return world

func metrics() -> Dictionary:
	return {"decisions": decisions, "mistakes": mistakes, "dash_requests": dash_requests,
		"observed_warnings": observed_warnings, "observed_projectiles": observed_projectiles, "action_digest": action_digest}
