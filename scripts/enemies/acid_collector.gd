class_name AcidCollector
extends Node2D
## Schlacko lobs fixed, warned acid globules. Its owner advances every hazard.

enum State { ARRIVAL, FOLLOW, WARNING, FLIGHT, RECOVERY }
var enemy: Enemy
var profile: AcidCollectorData
var state := State.ARRIVAL
var remaining := 1.2
var budget := 0.0
var origin := Vector2.ZERO
var destination := Vector2.ZERO
var pools: Array[Dictionary] = []

func _ready() -> void:
	remaining = profile.arrival_seconds
	budget = enemy.max_health * profile.burst_fraction
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	enemy.died.connect(func(_enemy: Enemy, _amount: float) -> void: pools.clear(); queue_redraw())

func suspended() -> bool:
	var owner := enemy.boss_objective_owner
	return not is_instance_valid(owner) or owner.health <= 0 or owner.acid_king_encounter.companion_suspended()

func limit(amount: float) -> float: return minf(amount, budget)
func spend(amount: float) -> void: budget = maxf(budget - amount, 0)

func pause_attack() -> void:
	state = State.FOLLOW
	remaining = profile.resume_seconds
	pools.clear()
	queue_redraw()

func _bounded(at: Vector2) -> Vector2:
	var bounds := enemy.boss_objective_owner.acid_king_encounter._visible_bounds()
	bounds = bounds.intersection(Rect2(Vector2.ONE * 60, enemy.target.arena.arena_size - Vector2.ONE * 120))
	return at.clamp(bounds.position, bounds.end)

func advance(delta: float) -> void:
	if enemy.health <= 0 or enemy.is_queued_for_deletion(): return
	if suspended(): return
	budget = minf(budget + enemy.max_health * delta / profile.minimum_lifetime, enemy.max_health * profile.burst_fraction)
	var left := maxf(delta, 0)
	var spent := 0.0
	while left > 0.000001 and enemy.health > 0:
		var step := minf(left, maxf(remaining, 0))
		_tick_pools(step, spent)
		if state == State.FOLLOW:
			var away := enemy.target.global_position.direction_to(enemy.global_position)
			if away.is_zero_approx(): away = Vector2.RIGHT
			enemy.global_position = enemy.global_position.move_toward(_bounded(enemy.target.global_position + away * profile.preferred_distance), enemy._movement_speed() * step)
		remaining = maxf(remaining - step, 0)
		left -= step
		spent += step
		if remaining <= 0.000001: _next(spent)
	queue_redraw()

func _next(seconds: float) -> void:
	match state:
		State.ARRIVAL, State.RECOVERY:
			state = State.FOLLOW
			remaining = profile.follow_seconds
		State.FOLLOW:
			state = State.WARNING
			remaining = profile.warning_seconds
			origin = enemy.global_position
			destination = _bounded(enemy.target.global_position + (enemy.target.velocity * profile.lead_seconds).limit_length(profile.lead_distance))
			enemy.attack_performed.emit(&"boss_warning")
		State.WARNING:
			state = State.FLIGHT
			remaining = profile.flight_seconds
		State.FLIGHT:
			if HazardGeometry.swept_capsule(enemy.target, destination, destination, profile.impact_radius, seconds, seconds): enemy.target.take_hit(enemy.attack_damage * profile.impact_damage_factor)
			while pools.size() >= profile.max_pools: pools.pop_front()
			pools.append({"at": destination, "life": profile.pool_seconds, "cooldown": profile.pool_tick_seconds})
			state = State.RECOVERY
			remaining = profile.recovery_seconds

func _tick_pools(delta: float, first: float) -> void:
	for pool in pools:
		var left := minf(delta, pool.life)
		var spent := first
		while left > 0.000001:
			var step := minf(left, pool.cooldown if pool.cooldown > 0.000001 else profile.pool_tick_seconds)
			if pool.cooldown <= 0.000001 and HazardGeometry.swept_capsule(enemy.target, pool.at, pool.at, profile.impact_radius, spent, spent + step):
				enemy.target.take_hit(enemy.attack_damage * profile.pool_damage_factor)
				pool.cooldown = profile.pool_tick_seconds
			pool.cooldown = maxf(pool.cooldown - step, 0)
			pool.life = maxf(pool.life - step, 0)
			left -= step
			spent += step
	pools = pools.filter(func(pool: Dictionary) -> bool: return pool.life > 0.000001)

func save_data() -> Dictionary:
	var saved_pools: Array = []
	for pool in pools: saved_pools.append({"position": SnapshotValues.vector_data(pool.at), "life": pool.life, "cooldown": pool.cooldown})
	return {"state": int(state), "remaining": remaining, "budget": budget, "origin": SnapshotValues.vector_data(origin), "destination": SnapshotValues.vector_data(destination), "pools": saved_pools}

func restore(saved: Dictionary) -> void:
	state = clampi(int(saved.get("state", 0)), 0, State.RECOVERY) as State
	remaining = clampf(float(saved.get("remaining", profile.arrival_seconds)), 0, 4)
	budget = clampf(float(saved.get("budget", 0)), 0, enemy.max_health * profile.burst_fraction)
	origin = SnapshotValues.read_vector(saved.get("origin", [0, 0]))
	destination = SnapshotValues.read_vector(saved.get("destination", [0, 0]))
	pools.clear()
	for raw: Dictionary in saved.get("pools", []):
		if pools.size() >= profile.max_pools: break
		pools.append({"at": SnapshotValues.read_vector(raw.position), "life": clampf(float(raw.life), 0, profile.pool_seconds), "cooldown": clampf(float(raw.cooldown), 0, profile.pool_tick_seconds)})
	queue_redraw()

static func valid(saved: Variant) -> bool:
	if not saved is Dictionary or not saved.get("pools", []) is Array: return false
	for key in ["state", "remaining", "budget"]:
		if saved.has(key) and not AcidKingSnapshot._number(saved[key]): return false
	for key in ["origin", "destination"]:
		if saved.has(key) and not AcidKingSnapshot._vector(saved[key]): return false
	for pool in saved.get("pools", []):
		if not pool is Dictionary or not AcidKingSnapshot._vector(pool.get("position")): return false
		for key in ["life", "cooldown"]:
			if not AcidKingSnapshot._number(pool.get(key)): return false
	return true

func _draw() -> void:
	if enemy.health <= 0: return
	var base := global_transform.affine_inverse()
	if suspended():
		return
	for pool in pools:
		WarningEffects.circle(self, pool.at, profile.impact_radius, 1, Color(0.65, 0.9, 0.16, clampf(pool.life / 0.6, 0, 1)), base, WarningEffects.BATCH.Phase.ACTIVE)
		AcidKingVisuals._art(self, 8, pool.at, profile.impact_radius * 1.5, Color(1, 1, 1, 0.5 * clampf(pool.life / 0.6, 0, 1)), base)
	if state in [State.WARNING, State.FLIGHT]:
		var progress: float = 1 - (remaining + (profile.flight_seconds if state == State.WARNING else 0)) / (profile.warning_seconds + profile.flight_seconds)
		WarningEffects.circle(self, destination, profile.impact_radius, progress, Color("b7ed38"), base)
		if state == State.FLIGHT:
			var t := 1 - remaining / profile.flight_seconds
			AcidKingVisuals._art(self, 8, origin.lerp(destination, t) - Vector2(0, sin(t * PI) * 70), 38, Color.WHITE, base)
	elif state == State.ARRIVAL:
		WarningEffects.circle(self, enemy.global_position, 58, 1 - remaining / profile.arrival_seconds, Color("b7ed38"), base)
