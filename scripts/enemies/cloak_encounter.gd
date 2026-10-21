class_name CloakEncounter
extends Node2D
## One authoritative clock drives warnings, damage and the sampled skeletal pose.

enum State { APPROACH, WARNING, STRIKE, STEP, RECOVERY }
const SAVE_VERSION := 1
const RIG: PackedScene = preload("res://scenes/enemies/count_cloak_rig.tscn")
var enemy: Enemy
var profile: CloakEncounterData
var rig: CountCloakRig
var state := State.APPROACH
var remaining := 0.6
var elapsed := 0.0
var strike_index := 0
var count := 2
var hit_mask := 0
var cycle := 0
var variant := CloakStrikeData.Kind.FAN
var origin := Vector2.ZERO
var direction := Vector2.DOWN
var half_angle := deg_to_rad(40.0)
var active: bool:
	get: return state in [State.WARNING, State.STRIKE, State.STEP]

func _ready() -> void:
	add_to_group("cloak_encounters")
	z_index = -2
	rig = RIG.instantiate()
	rig.name = &"CloakRig"
	# Keep Enemy's existing hit/death tint, bob and uniform death scale.
	enemy.sprite.texture = null
	rig.scale = Vector2.ONE * profile.visual_scale / enemy.sprite_base_scale.x
	rig.position = Vector2(0, 45) * profile.visual_scale / enemy.sprite_base_scale.x
	enemy.sprite.add_child(rig)
	sync_visual()

func cancel() -> void:
	state = State.APPROACH
	remaining = profile.recovery_seconds
	elapsed = 0
	hit_mask = 0
	variant = CloakStrikeData.Kind.FAN
	sync_visual()
	queue_redraw()

func begin() -> void:
	strike_index = 0
	count = (3 if enemy.boss_phase >= 1 else 2) + profile.action_bonus
	hit_mask = 0
	elapsed = 0
	cycle += 1
	_warn(enemy.target.global_position)

func _warn(target_position: Vector2) -> void:
	state = State.WARNING
	variant = _variant_for(strike_index)
	remaining = profile.warning(strike_index)
	origin = enemy.global_position
	direction = origin.direction_to(target_position)
	if direction.is_zero_approx(): direction = Vector2.DOWN
	half_angle = profile.half_angle_at(target_position, enemy.target.arena.arena_size, variant)
	enemy.special_phase = Enemy.SpecialPhase.COOLDOWN
	enemy.attack_performed.emit(&"boss_warning")
	sync_visual()
	queue_redraw()

func advance(delta: float) -> void:
	if enemy.dying or enemy.health <= 0 or enemy.target == null:
		return
	if enemy.boss_phase_timer > 0:
		sync_visual()
		return
	var dt := maxf(delta, 0)
	if state == State.APPROACH:
		elapsed += dt
		remaining = maxf(remaining - dt * minf(enemy.overtime_attack_factor(), 1.4), 0)
		var reserved := _reserved()
		var goal := _placement_goal(reserved)
		_move_toward(goal, dt)
		var positioned := enemy.global_position.distance_to(goal) <= profile.position_tolerance
		var in_range := enemy.global_position.distance_to(enemy.target.global_position) <= profile.placement_distance(enemy.target.global_position, enemy.target.arena.arena_size) + profile.position_tolerance
		# A pursuing melee player must not make the Graf retreat indefinitely.
		if remaining <= 0 and not reserved and (positioned or elapsed >= profile.position_seconds and in_range):
			begin()
		sync_visual()
		return
	var spent := 0.0
	# Split long frames at each authoritative boundary, including every new aim.
	while dt > 0.000001:
		var rate := minf(enemy.overtime_attack_factor(), 1.4) if state == State.RECOVERY else 1.0
		var step := minf(dt, remaining / rate)
		var before := _stage_elapsed()
		if state == State.STEP:
			_move_toward(_placement_goal(), step)
		elif state == State.RECOVERY:
			# Preserve a stationary breath before gently closing the gap again.
			var walking := maxf(before + step * rate - maxf(before, profile.recovery_settle_seconds), 0) / rate
			_move_toward(_placement_goal(_reserved()), walking, profile.recovery_move_factor)
		remaining = maxf(remaining - step * rate, 0)
		elapsed += step
		if state == State.STRIKE:
			var first := maxf(before, profile.hit_start)
			var last := minf(before + step, profile.hit_end)
			if before < profile.hit_start and before + step >= profile.hit_start:
				enemy.attack_performed.emit(&"boss_pulse")
			if first < last and (hit_mask & (1 << strike_index)) == 0:
				if _hits(spent + first - before, spent + last - before):
					hit_mask |= 1 << strike_index
					enemy.target.take_hit(enemy.attack_damage, enemy.inflicted_statuses)
		spent += step
		dt -= step
		if remaining <= 0.000001:
			_next(spent)
			if state == State.APPROACH: break
	sync_visual()
	queue_redraw()

func _next(seconds_in_frame: float) -> void:
	match state:
		State.WARNING:
			state = State.STRIKE
			remaining = profile.strike_seconds
		State.STRIKE:
			strike_index += 1
			state = State.STEP if strike_index < count else State.RECOVERY
			remaining = profile.step_seconds if state == State.STEP else profile.recovery_seconds
		State.STEP:
			_warn(HazardGeometry.player_at(enemy.target, seconds_in_frame))
		State.RECOVERY:
			state = State.APPROACH
			remaining = 0
			elapsed = 0

func _variant_for(index: int) -> int:
	if index >= 3: return posmod(index, 3)
	if index == 0: return CloakStrikeData.Kind.FAN
	if index >= 2: return CloakStrikeData.Kind.RING
	return CloakStrikeData.Kind.THRUST if count == 3 or cycle % 2 == 1 else CloakStrikeData.Kind.RING

func _hits(first: float, last: float) -> bool:
	var shape := profile.strike(variant)
	if variant == CloakStrikeData.Kind.RING:
		return HazardGeometry.swept_ring(enemy.target, origin, shape.inner_radius, shape.reach, first, last)
	return HazardGeometry.swept_sector(enemy.target, origin, direction, shape.reach, half_angle, first, last)

func _reserved() -> bool:
	for other in get_tree().get_nodes_in_group("cloak_encounters"):
		if other != self and other.active and other.enemy.health > 0: return true
	return false

func _placement_goal(reserved := false) -> Vector2:
	var target_position := enemy.target.global_position
	var arena := enemy.target.arena.arena_size
	var planning_kind := _variant_for(strike_index) if state == State.STEP else CloakStrikeData.Kind.FAN
	var radius := profile.placement_distance(target_position, arena, planning_kind)
	if reserved: radius = maxf(radius, 260.0)
	var away := target_position.direction_to(enemy.global_position)
	if away.is_zero_approx(): away = -direction
	var margin := DentiArena.WALL_WIDTH + enemy.data.radius + 6
	var low := Vector2.ONE * margin
	var high := arena - low
	var best := (target_position + away * radius).clamp(low, high)
	var shortest := INF
	# Pick the nearest legal point on the optimal ring, rather than clamping its
	# radius against a wall. Never cross through Denti to reach the opposite side.
	for index in maxi(profile.position_samples, 4):
		var candidate := target_position + away.rotated(TAU * float(index) / maxi(profile.position_samples, 4)) * radius
		if candidate != candidate.clamp(low, high): continue
		var near := Geometry2D.get_closest_point_to_segment(target_position, enemy.global_position, candidate)
		var clearance := minf(enemy.global_position.distance_to(target_position), enemy.data.radius + HazardGeometry.PLAYER_RADIUS + 6)
		if near.distance_to(target_position) < clearance - 0.01: continue
		var travel := enemy.global_position.distance_squared_to(candidate)
		if travel < shortest:
			shortest = travel
			best = candidate
	return best

func _move_toward(goal: Vector2, delta: float, speed_factor := 1.0) -> void:
	var next := enemy.global_position.move_toward(goal, enemy._movement_speed() * profile.chase_factor * speed_factor * delta)
	var margin := DentiArena.WALL_WIDTH + enemy.data.radius + 6
	enemy.global_position = next.clamp(Vector2.ONE * margin, enemy.target.arena.arena_size - Vector2.ONE * margin)

func _stage_elapsed() -> float:
	match state:
		State.WARNING: return profile.warning(strike_index) - remaining
		State.STRIKE: return profile.strike_seconds - remaining
		State.STEP: return profile.step_seconds - remaining
		State.RECOVERY: return profile.recovery_seconds - remaining
	return 0

func sync_visual() -> void:
	if not is_instance_valid(rig): return
	rig.sample(0)
	if not is_instance_valid(enemy.target): return
	match state:
		State.WARNING:
			var progress := 1.0 - remaining / profile.warning(strike_index)
			if strike_index > 0 and progress < 0.25:
				_sample_strike(_variant_for(strike_index - 1), strike_index - 1, 1, 1)
				var previous := rig.capture_pose()
				_sample_strike(variant, strike_index, progress, 0)
				rig.blend_from(previous, progress / 0.25)
			else:
				_sample_strike(variant, strike_index, progress, 0)
		State.STRIKE:
			var progress := 1.0 - remaining / profile.strike_seconds
			_sample_strike(variant, strike_index, 1, progress)
		State.STEP: _sample_strike(variant, strike_index - 1, 1, 1)
		State.RECOVERY:
			_sample_strike(variant, count - 1, 1, 1)
			var previous := rig.capture_pose()
			rig.sample(0)
			rig.blend_from(previous, 1.0 - remaining / profile.recovery_seconds)
	var stride := 0.0
	if state == State.STEP:
		stride = sin(PI * clampf(_stage_elapsed() / profile.step_seconds, 0, 1)) * clampf(enemy.global_position.distance_to(_placement_goal()) / 20.0, 0, 1)
	elif state == State.APPROACH:
		stride = clampf(enemy.global_position.distance_to(_placement_goal(_reserved())) / 28.0, 0, 1)
	elif state == State.RECOVERY and _stage_elapsed() > profile.recovery_settle_seconds:
		var progress := (_stage_elapsed() - profile.recovery_settle_seconds) / maxf(profile.recovery_seconds - profile.recovery_settle_seconds, 0.001)
		stride = sin(PI * clampf(progress, 0, 1)) * clampf(enemy.global_position.distance_to(_placement_goal(_reserved())) / 28.0, 0, 1)
	rig.apply_stride(elapsed, stride)

func _sample_strike(kind: int, index: int, preparation: float, release: float) -> void:
	if kind != CloakStrikeData.Kind.FAN:
		rig.sample_strike(kind, preparation, release)
		return
	var left := index % 2 == 0
	var time := lerpf(0.22, 1.0, preparation) if left else lerpf(1.24, 1.88, preparation)
	if release > 0: time = lerpf(1.0, 1.24, release) if left else lerpf(1.88, 2.15, release)
	rig.sample(time)

func save_data() -> Dictionary:
	return {"version": SAVE_VERSION, "state": int(state), "remaining": remaining, "elapsed": elapsed, "strike_index": strike_index, "count": count, "hit_mask": hit_mask, "cycle": cycle, "variant": variant, "half_angle": half_angle, "origin": SnapshotValues.vector_data(origin), "direction": SnapshotValues.vector_data(direction)}

func restore(saved: Dictionary) -> void:
	if int(saved.get("version", 0)) != SAVE_VERSION:
		cancel()
	else:
		state = clampi(int(saved.get("state", 0)), 0, 4) as State
		count = clampi(int(saved.get("count", 2)), 1, maxi(3, 3 + profile.action_bonus))
		strike_index = clampi(int(saved.get("strike_index", 0)), 0, count - 1 if state in [State.WARNING, State.STRIKE, State.STEP] else count)
		var limit := profile.recovery_seconds
		match state:
			State.WARNING: limit = profile.warning(strike_index)
			State.STRIKE: limit = profile.strike_seconds
			State.STEP: limit = profile.step_seconds
		remaining = clampf(float(saved.get("remaining", 0)), 0, limit)
		elapsed = maxf(float(saved.get("elapsed", 0)), 0)
		hit_mask = clampi(int(saved.get("hit_mask", 0)), 0, (1 << count) - 1)
		cycle = maxi(int(saved.get("cycle", 0)), 0)
		# Saves from the single-shape version finish their already announced fan.
		variant = clampi(int(saved.get("variant", 0)), 0, 2)
		origin = SnapshotValues.read_vector(saved.get("origin", [0, 0]))
		direction = SnapshotValues.read_vector(saved.get("direction", [0, 1]))
		if not is_equal_approx(direction.length_squared(), 1.0): direction = direction.normalized()
		if direction.is_zero_approx(): direction = Vector2.DOWN
		var shape := profile.strike(variant)
		half_angle = clampf(float(saved.get("half_angle", deg_to_rad(shape.half_angle_degrees))), deg_to_rad(shape.edge_half_angle_degrees), deg_to_rad(shape.half_angle_degrees))
	enemy.special_phase = Enemy.SpecialPhase.COOLDOWN
	enemy.boss_radial_volleys_remaining = 0
	enemy.boss_phase_burst_fired = true
	if enemy.dying: cancel()
	sync_visual()
	queue_redraw()

func _draw() -> void:
	if not active or enemy.dying or enemy.health <= 0 or state == State.STEP: return
	draw_set_transform_matrix(global_transform.affine_inverse())
	CloakStrikeArea.paint(self)
