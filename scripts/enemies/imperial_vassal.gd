class_name ImperialVassal
extends Node2D
## A unique lieutenant. The Emperor's retinue owns this clock, including tails.

enum State { FOLLOW, WARNING, ACTIVE, RECOVERY }
var enemy: Enemy
var profile: ImperialVassalData
var shots: BossPaintedVolley
var state := State.FOLLOW
var remaining := 0.9
var elapsed := 0.0
var budget := 0.0
var aim := Vector2.DOWN
var origin := Vector2.ZERO
var destination := Vector2.ZERO
var hit := false
var fired := false

func _ready() -> void:
	z_index = 1
	budget = enemy.max_health * profile.burst_fraction
	shots = BossPaintedVolley.new()
	shots.enemy = enemy
	shots.profile = profile.projectile_profile
	shots.texture = EmperorCourtArt.texture(7)
	shots.orient_to_velocity = true
	add_child(shots)
	enemy.died.connect(func(_enemy: Enemy, _amount: float) -> void: shots.clear())

func limit(amount: float) -> float:
	return minf(amount, budget)

func spend(amount: float) -> void:
	budget = maxf(budget - amount, 0)

func advance(delta: float) -> void:
	if enemy.health <= 0 or enemy.is_queued_for_deletion():
		shots.clear()
		return
	if not is_instance_valid(enemy.boss_objective_owner): return
	budget = minf(budget + enemy.max_health * delta / profile.minimum_lifetime, enemy.max_health * profile.burst_fraction)
	var left := delta
	var spent := 0.0
	while left > 0.000001 and enemy.health > 0 and not enemy.is_queued_for_deletion():
		var step := minf(left, maxf(remaining, 0))
		shots.advance(step, spent)
		if state == State.FOLLOW: _move(step)
		elif state == State.ACTIVE: _active(step, spent)
		remaining = maxf(remaining - step, 0)
		elapsed += step
		spent += step
		left -= step
		if remaining <= 0.000001: _next()
	queue_redraw()

func _move(delta: float) -> void:
	var player := enemy.target.global_position
	var away := player.direction_to(enemy.global_position)
	if away.is_zero_approx(): away = Vector2.RIGHT
	var desired := player + away * profile.preferred_distance
	if profile.role == ImperialVassalData.Role.KEEPER:
		desired = enemy.boss_objective_owner.global_position + away * 200
	var margin := Vector2.ONE * 60
	desired = desired.clamp(margin, enemy.target.arena.arena_size - margin)
	var visible := enemy.get_canvas_transform().affine_inverse() * enemy.get_viewport_rect()
	var inset := Vector2(minf(80, visible.size.x * 0.2), minf(160, visible.size.y * 0.3))
	desired = desired.clamp(visible.position + inset, visible.end - inset)
	enemy.global_position = enemy.global_position.move_toward(desired, enemy._movement_speed() * delta)

func _next() -> void:
	match state:
		State.FOLLOW:
			state = State.WARNING
			remaining = profile.warning_seconds
			origin = enemy.global_position
			aim = origin.direction_to(enemy.target.global_position)
			if aim.is_zero_approx(): aim = Vector2.DOWN
			destination = enemy.target.global_position if profile.role == ImperialVassalData.Role.JUSTICIAR else origin + aim * minf(maxf(origin.distance_to(enemy.target.global_position), 160), profile.dash_distance)
			destination = destination.clamp(Vector2.ONE * 55, enemy.target.arena.arena_size - Vector2.ONE * 55)
			hit = false
			fired = false
			enemy.attack_performed.emit(&"boss_warning")
		State.WARNING:
			state = State.ACTIVE
			remaining = profile.active_seconds
		State.ACTIVE:
			state = State.RECOVERY
			remaining = profile.cooldown_seconds
		State.RECOVERY:
			state = State.FOLLOW
			remaining = 0.35

func _active(delta: float, first: float) -> void:
	if profile.role == ImperialVassalData.Role.KEEPER:
		if not fired:
			fired = true
			shots.fire(origin, EnemyProjectilePatterns.fan_directions(aim, 3 + maxi(enemy.difficulty.boss_volley_bonus, 0), 0.2), &"imperial_keeper")
		return
	var progress := clampf(1 - (remaining - delta) / profile.active_seconds, 0, 1)
	var before := enemy.global_position
	enemy.global_position = origin.lerp(destination, progress)
	var struck := false
	if profile.role == ImperialVassalData.Role.LANCER:
		struck = HazardGeometry.swept_capsule(enemy.target, before, enemy.global_position, profile.lane_radius, first, first + delta)
	elif progress >= 0.85:
		struck = HazardGeometry.swept_capsule(enemy.target, destination, destination, profile.slam_radius, first, first + delta)
	if struck and not hit:
		hit = true
		enemy.target.take_hit(enemy.attack_damage * profile.damage_factor)

func save_data() -> Dictionary:
	return {"state": int(state), "remaining": remaining, "elapsed": elapsed, "budget": budget, "aim": SnapshotValues.vector_data(aim), "origin": SnapshotValues.vector_data(origin), "destination": SnapshotValues.vector_data(destination), "hit": hit, "fired": fired, "shots": shots.save_data()}

func restore(saved: Dictionary) -> void:
	state = clampi(int(saved.get("state", 0)), 0, State.RECOVERY) as State
	remaining = clampf(float(saved.get("remaining", 0.9)), 0, 4)
	elapsed = maxf(float(saved.get("elapsed", 0)), 0)
	budget = clampf(float(saved.get("budget", enemy.max_health * profile.burst_fraction)), 0, enemy.max_health * profile.burst_fraction)
	for key in ["aim", "origin", "destination"]: set(key, SnapshotValues.read_vector(saved.get(key, [0, 0])))
	hit = bool(saved.get("hit", false))
	fired = bool(saved.get("fired", false))
	shots.restore(saved.get("shots", []))

static func valid(saved: Variant) -> bool:
	if not saved is Dictionary: return false
	for key in ["state", "remaining", "elapsed", "budget"]:
		if saved.has(key) and not CrownCourtSnapshot._number(saved[key]): return false
	for key in ["aim", "origin", "destination"]:
		if saved.has(key) and not CrownCourtSnapshot._vector(saved[key]): return false
	for key in ["hit", "fired"]:
		if saved.has(key) and not saved[key] is bool: return false
	if not saved.get("shots", []) is Array: return false
	for shot in saved.get("shots", []):
		if not shot is Dictionary: return false
		for key in ["position", "velocity"]:
			if not CrownCourtSnapshot._vector(shot.get(key)): return false
		for key in ["life", "damage"]:
			if not CrownCourtSnapshot._number(shot.get(key)): return false
	return true

func _draw() -> void:
	if enemy.health <= 0: return
	var base := global_transform.affine_inverse()
	if state == State.WARNING:
		var progress := 1 - remaining / profile.warning_seconds
		if profile.role == ImperialVassalData.Role.LANCER: WarningEffects.capsule(self, origin, destination, profile.lane_radius, Color("f7bd66"), progress, base)
		elif profile.role == ImperialVassalData.Role.JUSTICIAR: WarningEffects.circle(self, destination, profile.slam_radius, progress, Color("d591ff"), base)
		else:
			for ray in EnemyProjectilePatterns.fan_directions(aim, 3 + maxi(enemy.difficulty.boss_volley_bonus, 0), 0.2): WarningEffects.aim(self, origin, origin + ray * 600, Color("ba8bff"), progress, base)
	draw_set_transform_matrix(base)
	var at := enemy.global_position + Vector2(-34, 53)
	draw_rect(Rect2(at - Vector2(2, 2), Vector2(72, 9)), Color("36213e"))
	draw_rect(Rect2(at, Vector2(68 * maxf(enemy.health, 0) / enemy.max_health, 5)), Color("dfb965"))
