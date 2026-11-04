class_name CaramelEnforcer
extends Node2D
## Brösel chases, commits to a warned rush, then throws fixed ground punches.
## The owning caramel encounter advances this clock through every boss phase.

enum State { ARRIVAL, FOLLOW, CHARGE_WARN, CHARGE, PUNCH_WARN, PUNCH, RECOVERY }
var enemy: Enemy
var profile: CaramelEnforcerData
var state := State.ARRIVAL
var remaining := 1.1
var budget := 0.0
var origin := Vector2.ZERO
var destination := Vector2.ZERO
var punches_left := 0
var hit := false

func _ready() -> void:
	remaining = profile.arrival_seconds
	budget = enemy.max_health * profile.burst_fraction
	z_index = 2

func suspended() -> bool:
	var owner := enemy.boss_objective_owner
	return not is_instance_valid(owner) or owner.health <= 0 or owner.dying

func limit(amount: float) -> float: return minf(amount, budget)
func spend(amount: float) -> void: budget = maxf(budget - amount, 0)

func pause_attack() -> void:
	state = State.FOLLOW
	remaining = profile.resume_seconds
	hit = false
	queue_redraw()

func advance(delta: float) -> void:
	if enemy.health <= 0 or enemy.is_queued_for_deletion(): return
	if suspended(): return
	budget = minf(budget + enemy.max_health * delta / profile.minimum_lifetime, enemy.max_health * profile.burst_fraction)
	var left := maxf(delta, 0)
	var spent := 0.0
	while left > 0.000001 and enemy.health > 0:
		var step := minf(left, maxf(remaining, 0))
		if state == State.FOLLOW:
			var away := enemy.target.global_position.direction_to(enemy.global_position)
			if away.is_zero_approx(): away = Vector2.RIGHT
			var goal := _bounded(enemy.target.global_position + away * profile.preferred_distance)
			enemy.global_position = enemy.global_position.move_toward(goal, enemy._movement_speed() * step)
		elif state == State.CHARGE:
			var before := enemy.global_position
			var progress := clampf(1 - (remaining - step) / profile.charge_seconds, 0, 1)
			enemy.global_position = origin.lerp(destination, progress)
			_strike(HazardGeometry.swept_capsule(enemy.target, before, enemy.global_position, profile.charge_radius, spent, spent + step))
		elif state == State.PUNCH:
			_strike(HazardGeometry.swept_capsule(enemy.target, destination, destination, profile.punch_radius, spent, spent + step))
		remaining = maxf(remaining - step, 0)
		left -= step
		spent += step
		if remaining <= 0.000001: _next()
	queue_redraw()

func _strike(touched: bool) -> void:
	if touched and not hit:
		hit = true
		enemy.target.take_hit(enemy.attack_damage * profile.damage_factor)

func _bounded(at: Vector2) -> Vector2:
	var bounds := enemy.boss_objective_owner.caramel_encounter._cooking_bounds()
	bounds = bounds.intersection(Rect2(Vector2.ONE * 60, enemy.target.arena.arena_size - Vector2.ONE * 120))
	return at.clamp(bounds.position, bounds.end)

func _next() -> void:
	match state:
		State.ARRIVAL, State.RECOVERY:
			state = State.FOLLOW
			remaining = profile.follow_seconds
		State.FOLLOW:
			punches_left = profile.punches
			if enemy.global_position.distance_to(enemy.target.global_position) <= profile.punch_trigger_distance:
				_warn_punch()
			else:
				state = State.CHARGE_WARN
				remaining = profile.charge_warning
				origin = enemy.global_position
				destination = _bounded(origin + origin.direction_to(enemy.target.global_position) * minf(origin.distance_to(enemy.target.global_position), profile.charge_distance))
				enemy.attack_performed.emit(&"boss_warning")
		State.CHARGE_WARN:
			state = State.CHARGE
			remaining = profile.charge_seconds
			hit = false
		State.CHARGE: _warn_punch()
		State.PUNCH_WARN:
			state = State.PUNCH
			remaining = profile.punch_seconds
			hit = false
		State.PUNCH:
			punches_left -= 1
			if punches_left > 0: _warn_punch()
			else:
				state = State.RECOVERY
				remaining = profile.recovery_seconds

func _warn_punch() -> void:
	state = State.PUNCH_WARN
	remaining = profile.punch_warning
	origin = enemy.global_position
	destination = _bounded(origin + origin.direction_to(enemy.target.global_position) * profile.punch_offset)
	enemy.attack_performed.emit(&"boss_warning")

func save_data() -> Dictionary:
	return {"state": int(state), "remaining": remaining, "budget": budget, "origin": SnapshotValues.vector_data(origin), "destination": SnapshotValues.vector_data(destination), "punches_left": punches_left, "hit": hit}

func restore(saved: Dictionary) -> void:
	state = clampi(int(saved.get("state", 0)), 0, State.RECOVERY) as State
	remaining = clampf(float(saved.get("remaining", profile.arrival_seconds)), 0, 4)
	budget = clampf(float(saved.get("budget", 0)), 0, enemy.max_health * profile.burst_fraction)
	origin = SnapshotValues.read_vector(saved.get("origin", [0, 0]))
	destination = SnapshotValues.read_vector(saved.get("destination", [0, 0]))
	punches_left = clampi(int(saved.get("punches_left", 0)), 0, profile.punches)
	hit = bool(saved.get("hit", false))

static func valid(saved: Variant) -> bool:
	if not saved is Dictionary: return false
	for key in ["state", "remaining", "budget", "punches_left"]:
		if saved.has(key) and not CrownCourtSnapshot._number(saved[key]): return false
	for key in ["origin", "destination"]:
		if saved.has(key) and not CrownCourtSnapshot._vector(saved[key]): return false
	return not saved.has("hit") or saved.hit is bool

func _draw() -> void:
	if enemy.health <= 0: return
	var base := global_transform.affine_inverse()
	if suspended():
		return
	elif state == State.CHARGE_WARN:
		WarningEffects.capsule(self, origin, destination, profile.charge_radius, Color("ffb85b"), 1 - remaining / profile.charge_warning, base)
	elif state == State.PUNCH_WARN:
		WarningEffects.circle(self, destination, profile.punch_radius, 1 - remaining / profile.punch_warning, Color("ffb85b"), base)
	elif state == State.PUNCH:
		draw_set_transform_matrix(base)
		draw_arc(destination, profile.punch_radius, 0, TAU, 48, Color("ffe2a5"), 5, true)
	elif state == State.ARRIVAL:
		WarningEffects.circle(self, enemy.global_position, 60, 1 - remaining / profile.arrival_seconds, Color("ffb85b"), base)
