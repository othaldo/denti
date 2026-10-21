class_name CaramelEncounter
extends Node2D
## One clock owns each locked aim, ballistic flight, impact and expiring floor pool.

enum State { APPROACH, WINDUP, FLIGHT, FOLLOWUP, RECOVERY, HEART_WINDUP, HEART_RELEASE, RUSH_WINDUP, RUSH_ACTIVE, BURST_WINDUP, BURST_RELEASE }
const SAVE_VERSION := 2
var enemy: Enemy
var profile: CaramelEncounterData
var rig: PrinceCaramelRig
var hearts: CaramelHeartVolley
var attack_kind := CaramelEncounterData.Attack.BOMBS
var salvo_index := 0
var salvo_count := 1
var rays: Array[Vector2] = []
var aim := Vector2.RIGHT
var rush_origin := Vector2.ZERO
var rush_end := Vector2.ZERO
var rush_hit := false
var state := State.APPROACH
var remaining := 0.65
var elapsed := 0.0
var throw_index := 0
var count := 2
var cycle := 0
var origin := Vector2.ZERO
var destination := Vector2.ZERO
var pools: Array[Dictionary] = []
var splash_at := Vector2.ZERO
var splash_remaining := 0.0
var active: bool:
	get: return state not in [State.APPROACH, State.RECOVERY]

func _ready() -> void:
	add_to_group("caramel_encounters")
	z_index = -2
	remaining = profile.approach_seconds
	rig = PrinceCaramelRig.new()
	rig.name = &"CaramelRig"
	enemy.sprite.texture = null
	rig.scale = Vector2.ONE * profile.visual_scale / enemy.sprite_base_scale.x
	rig.position = Vector2(0, 46) * profile.visual_scale / enemy.sprite_base_scale.x
	enemy.sprite.add_child(rig)
	hearts = CaramelHeartVolley.new()
	hearts.name = &"CaramelHearts"
	hearts.encounter = self
	add_child(hearts)
	sync_visual()

func cancel(clear_pools := true) -> void:
	state = State.APPROACH
	remaining = profile.approach_seconds
	throw_index = 0
	splash_remaining = 0
	rays.clear()
	if hearts != null: hearts.clear()
	if clear_pools: pools.clear()
	sync_visual()
	queue_redraw()

func begin(seconds_in_frame := -1.0, forced_attack: int = -1) -> void:
	attack_kind = clampi(forced_attack, 0, 2) if forced_attack >= 0 else profile.attack_for_cycle(cycle)
	count = profile.throws_for_phase(enemy.boss_phase)
	throw_index = 0
	cycle += 1
	match attack_kind:
		CaramelEncounterData.Attack.BOMBS: _warn(seconds_in_frame)
		CaramelEncounterData.Attack.HEART_FAN:
			salvo_index = 0
			salvo_count = profile.salvos_for_phase(enemy.boss_phase)
			_warn_fan(seconds_in_frame)
		CaramelEncounterData.Attack.SUGAR_RUSH: _warn_rush(seconds_in_frame)

func _warn(seconds_in_frame: float) -> void:
	state = State.WINDUP
	remaining = profile.windup_seconds
	origin = enemy.global_position + Vector2(38, -42)
	var at := HazardGeometry.player_at(enemy.target, seconds_in_frame) if seconds_in_frame >= 0 else enemy.target.global_position
	if throw_index % 2 == 1:
		at += (enemy.target.velocity * profile.followup_lead_seconds).limit_length(profile.maximum_lead)
	var margin := DentiArena.PLAYER_MARGIN
	destination = at.clamp(Vector2.ONE * margin, enemy.target.arena.arena_size - Vector2.ONE * margin)
	var view := enemy.get_canvas_transform().affine_inverse() * enemy.get_viewport_rect()
	var padding := minf(profile.impact_radius, minf(view.size.x, view.size.y) * 0.25)
	var visible_aim := view.grow(-padding)
	destination = destination.clamp(visible_aim.position, visible_aim.end).clamp(Vector2.ONE * margin, enemy.target.arena.arena_size - Vector2.ONE * margin)
	enemy.special_phase = Enemy.SpecialPhase.COOLDOWN
	enemy.attack_performed.emit(&"boss_warning")

func advance(delta: float) -> void:
	if enemy.dying or enemy.health <= 0 or enemy.target == null: return
	var left := maxf(delta, 0)
	var spent := 0.0
	# Pools keep expiring during a health phase; no new attacks begin there.
	if enemy.boss_phase_timer > 0:
		_age_pools(left)
		hearts.advance(left, 0)
		sync_visual()
		queue_redraw()
		return
	while left > 0.000001:
		var rate := minf(enemy.overtime_attack_factor(), 1.4) if state in [State.APPROACH, State.RECOVERY] else 1.0
		var step := minf(left, maxf(remaining, 0) / rate)
		_age_pools(step)
		hearts.advance(step, spent)
		if state == State.APPROACH: _move(step)
		if profile.move_between_volleys:
			if state in [State.FOLLOWUP, State.HEART_RELEASE]: _move(step, profile.reposition_speed_factor)
			elif state == State.RECOVERY:
				var before := profile.recovery_seconds - remaining
				var walking := maxf(before + step * rate - maxf(before, profile.recovery_settle_seconds), 0) / rate
				_move(walking, profile.reposition_speed_factor)
		if state == State.RUSH_ACTIVE: _rush_step(step, spent)
		remaining = maxf(remaining - step * rate, 0)
		elapsed += step
		spent += step
		left -= step
		if remaining <= 0.000001:
			_next(spent)
	sync_visual()
	queue_redraw()

func _next(seconds_in_frame: float) -> void:
	match state:
		State.APPROACH:
			if _reserved() or not _cooking_bounds().has_point(enemy.global_position): remaining = 0.15
			else: begin(seconds_in_frame)
		State.WINDUP:
			rig.sample(elapsed, 1, 0, false)
			origin = rig.projectile_origin()
			state = State.FLIGHT
			remaining = profile.flight_seconds
			enemy.attack_performed.emit(&"boss_charge")
		State.FLIGHT:
			_land(seconds_in_frame)
			throw_index += 1
			state = State.FOLLOWUP if throw_index < count else State.RECOVERY
			remaining = profile.followup_seconds if state == State.FOLLOWUP else profile.recovery_seconds
		State.FOLLOWUP: _warn(seconds_in_frame)
		State.RECOVERY:
			state = State.APPROACH
			remaining = profile.approach_seconds
		State.HEART_WINDUP:
			hearts.fire(enemy.global_position, rays, &"heart_fan")
			enemy.attack_performed.emit(&"boss_pulse")
			state = State.HEART_RELEASE
			remaining = profile.heart_release_seconds
		State.HEART_RELEASE:
			salvo_index += 1
			if salvo_index < salvo_count: _warn_fan(seconds_in_frame)
			else: _recover()
		State.RUSH_WINDUP:
			state = State.RUSH_ACTIVE
			remaining = profile.rush_seconds
			enemy.contact_timer = 0
			enemy.attack_performed.emit(&"boss_charge")
		State.RUSH_ACTIVE: _warn_burst(seconds_in_frame)
		State.BURST_WINDUP:
			hearts.fire(enemy.global_position, rays, &"heart_burst")
			enemy.attack_performed.emit(&"boss_pulse")
			state = State.BURST_RELEASE
			remaining = profile.burst_release_seconds
		State.BURST_RELEASE:
			salvo_index += 1
			if salvo_index < salvo_count: _warn_burst(seconds_in_frame)
			else: _recover()

func _recover() -> void:
	state = State.RECOVERY
	remaining = profile.recovery_seconds
	rays.clear()

func _aim_at(seconds_in_frame: float) -> Vector2:
	return HazardGeometry.player_at(enemy.target, seconds_in_frame) if seconds_in_frame >= 0 else enemy.target.global_position

func _warn_fan(seconds_in_frame: float) -> void:
	state = State.HEART_WINDUP
	remaining = profile.heart_warning_seconds if salvo_index == 0 else profile.heart_followup_warning
	aim = enemy.global_position.direction_to(_aim_at(seconds_in_frame))
	if aim.is_zero_approx(): aim = Vector2.DOWN
	# The follow-up is visibly offset and re-aimed, with its own full preparation.
	if salvo_index > 0: aim = aim.rotated(deg_to_rad(profile.fan_step_degrees * (0.5 if salvo_index % 2 == 1 else -0.5)))
	rays = EnemyProjectilePatterns.fan_directions(aim, profile.fan_count(enemy.boss_phase), deg_to_rad(profile.fan_step_degrees))
	enemy.attack_performed.emit(&"boss_warning")

func _warn_rush(seconds_in_frame: float) -> void:
	state = State.RUSH_WINDUP
	remaining = profile.rush_warning_seconds
	rush_origin = enemy.global_position
	salvo_index = 0
	salvo_count = profile.burst_salvos()
	var target_position := _aim_at(seconds_in_frame)
	aim = rush_origin.direction_to(target_position)
	if aim.is_zero_approx(): aim = Vector2.DOWN
	var distance := minf(profile.rush_distance, rush_origin.distance_to(target_position) + profile.rush_overshoot)
	var margin := DentiArena.WALL_WIDTH + enemy.data.radius + 6
	rush_end = (rush_origin + aim * distance).clamp(Vector2.ONE * margin, enemy.target.arena.arena_size - Vector2.ONE * margin)
	aim = rush_origin.direction_to(rush_end)
	rush_hit = false
	enemy.attack_performed.emit(&"boss_warning")

func rush_movement(seconds: float) -> Vector2:
	if state != State.RUSH_ACTIVE: return Vector2.ZERO
	var speed := rush_origin.distance_to(rush_end) / profile.rush_seconds
	return enemy.global_position.move_toward(rush_end, speed * minf(seconds, remaining)) - enemy.global_position

func _rush_step(delta: float, seconds_in_frame: float) -> void:
	var before := enemy.global_position
	var progress := clampf(1.0 - (remaining - delta) / profile.rush_seconds, 0, 1)
	var after := rush_origin.lerp(rush_end, progress)
	enemy.global_position = after
	if not rush_hit and enemy.contact_timer <= 0 and HazardGeometry.moving_circle(enemy.target, before, after, enemy.data.radius, seconds_in_frame, seconds_in_frame + delta):
		rush_hit = true
		enemy.try_contact_hit()

func _warn_burst(seconds_in_frame: float) -> void:
	state = State.BURST_WINDUP
	remaining = profile.burst_warning_seconds
	# Uniform complete rings; neither rotation nor missing shots follow Denti.
	var offset := deg_to_rad(profile.burst_rotation_degrees * cycle) + (PI / profile.burst_count(enemy.boss_phase) if salvo_index > 0 else 0.0)
	rays = EnemyProjectilePatterns.circle_directions(profile.burst_count(enemy.boss_phase), offset)
	enemy.attack_performed.emit(&"boss_warning")

func _land(seconds_in_frame: float) -> void:
	if enemy.target.damage_circle_at(destination, profile.impact_radius + HazardGeometry.PLAYER_RADIUS, seconds_in_frame):
		enemy.target.take_hit(enemy.attack_damage, enemy.inflicted_statuses)
	splash_at = destination
	splash_remaining = 0.30
	_make_pool_room()
	pools.append({"at": destination, "life": profile.pool_seconds})
	enemy.attack_performed.emit(&"boss_pulse")

func _make_pool_room() -> void:
	# A shared budget also bounds a double-Prince endless encounter and its saves.
	var all: Array = get_tree().get_nodes_in_group("caramel_encounters")
	var total := 0
	var oldest: CaramelEncounter
	var oldest_life := INF
	var oldest_index := -1
	for encounter: CaramelEncounter in all:
		total += encounter.pools.size()
		for index in encounter.pools.size():
			if encounter.pools[index].life < oldest_life:
				oldest = encounter
				oldest_life = encounter.pools[index].life
				oldest_index = index
	if total >= profile.max_pools and oldest != null:
		oldest.pools.remove_at(oldest_index)
		oldest.queue_redraw()

func _age_pools(delta: float) -> void:
	splash_remaining = maxf(splash_remaining - delta, 0)
	for index in range(pools.size() - 1, -1, -1):
		pools[index].life -= delta
		if pools[index].life <= 0: pools.remove_at(index)

func speed_factor_at(at: Vector2) -> float:
	if enemy.dying or enemy.health <= 0 or enemy.is_queued_for_deletion(): return 1.0
	for pool in pools:
		var aspect := PrinceCaramelArt.REGIONS[6].size.y / PrinceCaramelArt.REGIONS[6].size.x
		var relative: Vector2 = (at - pool.at) / Vector2(profile.pool_radius, profile.pool_radius * aspect)
		if pool.life > 0 and relative.length_squared() <= 1:
			return profile.movement_factor
	return 1.0

func _reserved() -> bool:
	for other: CaramelEncounter in get_tree().get_nodes_in_group("caramel_encounters"):
		if other != self and (other.active or not other.hearts.entries.is_empty()) and other.enemy.health > 0: return true
	return false

func _move(delta: float, speed_factor: float = 1.0) -> void:
	var player_at := enemy.target.global_position
	var away := player_at.direction_to(enemy.global_position)
	if away.is_zero_approx(): away = Vector2.LEFT
	# Change cooking position between volleys, but never flee melee indefinitely.
	var turn := 0.22 + profile.reposition_bias * 0.5
	var tangent := away.rotated(turn if cycle % 2 == 0 else -turn)
	var bounds := _cooking_bounds()
	var cooking_distance := clampf(enemy.global_position.distance_to(player_at), enemy.data.radius + HazardGeometry.PLAYER_RADIUS + 30, profile.preferred_distance)
	var desired := bounds.get_center()
	var score := INF
	# On a narrow phone, use the available vertical room instead of throwing
	# from far outside the view. Desktop retains the normal preferred range.
	for index in 24:
		var ray := tangent.rotated(index * TAU / 24)
		var candidate := (player_at + ray * cooking_distance).clamp(bounds.position, bounds.end)
		var distance := candidate.distance_to(player_at)
		if distance < enemy.data.radius + HazardGeometry.PLAYER_RADIUS + 20: continue
		var clearance := minf(enemy.global_position.distance_to(player_at), enemy.data.radius + HazardGeometry.PLAYER_RADIUS + 8)
		var near := Geometry2D.get_closest_point_to_segment(player_at, enemy.global_position, candidate)
		if near.distance_to(player_at) < clearance - 0.01: continue
		var cost := absf(distance - cooking_distance) + candidate.distance_to(enemy.global_position) * 0.35
		cost += absf(tangent.angle_to(player_at.direction_to(candidate))) * cooking_distance * profile.reposition_bias
		if cost < score:
			score = cost
			desired = candidate
	var margin := DentiArena.WALL_WIDTH + enemy.data.radius + 6
	desired = desired.clamp(Vector2.ONE * margin, enemy.target.arena.arena_size - Vector2.ONE * margin)
	var next := enemy.global_position.move_toward(desired, enemy._movement_speed() * profile.move_factor * speed_factor * delta)
	var closest := Geometry2D.get_closest_point_to_segment(player_at, enemy.global_position, next)
	var clearance := minf(enemy.global_position.distance_to(player_at), enemy.data.radius + HazardGeometry.PLAYER_RADIUS + 8)
	if closest.distance_to(player_at) >= clearance - 0.01:
		enemy.global_position = next

func _cooking_bounds() -> Rect2:
	var visible := enemy.get_canvas_transform().affine_inverse() * enemy.get_viewport_rect()
	var inset := Vector2(minf(110, visible.size.x * 0.3), minf(120, visible.size.y * 0.3))
	return Rect2(visible.position + inset, visible.size - inset * 2)

func sync_visual() -> void:
	if rig == null: return
	var windup := 0.0
	var release := 0.0
	if state == State.WINDUP: windup = 1.0 - remaining / profile.windup_seconds
	if state == State.FLIGHT:
		windup = 1
		release = clampf((1.0 - remaining / profile.flight_seconds) * 3, 0, 1)
	if state == State.FOLLOWUP: release = 1
	var walking := state == State.APPROACH or profile.move_between_volleys and (state in [State.FOLLOWUP, State.HEART_RELEASE] or state == State.RECOVERY and profile.recovery_seconds - remaining > profile.recovery_settle_seconds)
	rig.sample(elapsed, windup, release, walking)
	if state == State.HEART_WINDUP:
		var duration := profile.heart_warning_seconds if salvo_index == 0 else profile.heart_followup_warning
		rig.sample_heart(elapsed, 1 - remaining / duration, 0)
	elif state == State.HEART_RELEASE:
		rig.sample_heart(elapsed, 1, 1 - remaining / profile.heart_release_seconds, false, walking)
	elif state in [State.RUSH_WINDUP, State.RUSH_ACTIVE]:
		rig.sample_rush(elapsed, 1 - remaining / profile.rush_warning_seconds if state == State.RUSH_WINDUP else 1, state == State.RUSH_ACTIVE, aim)
	elif state in [State.BURST_WINDUP, State.BURST_RELEASE]:
		rig.sample_heart(elapsed, 1 - remaining / profile.burst_warning_seconds if state == State.BURST_WINDUP else 1, 0 if state == State.BURST_WINDUP else 1 - remaining / profile.burst_release_seconds, true)

func save_data() -> Dictionary:
	var fields: Array = []
	for pool in pools:
		fields.append({"position": SnapshotValues.vector_data(pool.at), "life": pool.life})
	var directions: Array = []
	for ray in rays: directions.append(SnapshotValues.vector_data(ray))
	return {"version": SAVE_VERSION, "state": int(state), "remaining": remaining, "elapsed": elapsed, "throw_index": throw_index, "count": count, "cycle": cycle, "origin": SnapshotValues.vector_data(origin), "destination": SnapshotValues.vector_data(destination), "pools": fields, "splash_at": SnapshotValues.vector_data(splash_at), "splash_remaining": splash_remaining, "attack_kind": attack_kind, "salvo_index": salvo_index, "salvo_count": salvo_count, "aim": SnapshotValues.vector_data(aim), "rush_origin": SnapshotValues.vector_data(rush_origin), "rush_end": SnapshotValues.vector_data(rush_end), "rush_hit": rush_hit, "rays": directions, "hearts": hearts.save_data()}

func restore(saved: Dictionary) -> void:
	cancel()
	var version := int(saved.get("version", 0))
	if version not in [1, SAVE_VERSION]: return
	state = clampi(int(saved.get("state", 0)), 0, 4 if version == 1 else 10) as State
	attack_kind = clampi(int(saved.get("attack_kind", 0)), 0, 2)
	salvo_count = clampi(int(saved.get("salvo_count", 1)), 1, maxi(2, profile.salvos_for_phase(2)))
	salvo_index = clampi(int(saved.get("salvo_index", 0)), 0, salvo_count)
	aim = SnapshotValues.read_vector(saved.get("aim", [1, 0]))
	rush_origin = SnapshotValues.read_vector(saved.get("rush_origin", [0, 0]))
	rush_end = SnapshotValues.read_vector(saved.get("rush_end", [0, 0]))
	rush_hit = bool(saved.get("rush_hit", false))
	for raw in saved.get("rays", []):
		if rays.size() >= profile.max_hearts: break
		rays.append(SnapshotValues.read_vector(raw))
	count = clampi(int(saved.get("count", 2)), 1, maxi(3, profile.throws_for_phase(2)))
	throw_index = clampi(int(saved.get("throw_index", 0)), 0, count)
	var limit: float = [profile.approach_seconds, profile.windup_seconds, profile.flight_seconds, profile.followup_seconds, profile.recovery_seconds, profile.heart_warning_seconds if salvo_index == 0 else profile.heart_followup_warning, profile.heart_release_seconds, profile.rush_warning_seconds, profile.rush_seconds, profile.burst_warning_seconds, profile.burst_release_seconds][state]
	remaining = clampf(float(saved.get("remaining", 0)), 0, limit)
	elapsed = maxf(float(saved.get("elapsed", 0)), 0)
	cycle = maxi(int(saved.get("cycle", 0)), 0)
	origin = SnapshotValues.read_vector(saved.get("origin", [0, 0]))
	destination = SnapshotValues.read_vector(saved.get("destination", [0, 0]))
	splash_at = SnapshotValues.read_vector(saved.get("splash_at", [0, 0]))
	splash_remaining = clampf(float(saved.get("splash_remaining", 0)), 0, 0.3)
	for entry: Dictionary in saved.get("pools", []):
		if pools.size() >= profile.max_pools: break
		var life := clampf(float(entry.get("life", 0)), 0, profile.pool_seconds)
		if life > 0:
			_make_pool_room()
			pools.append({"at": SnapshotValues.read_vector(entry.get("position", [0, 0])), "life": life})
	hearts.restore(saved.get("hearts", []))
	enemy.special_phase = Enemy.SpecialPhase.COOLDOWN
	enemy.boss_radial_volleys_remaining = 0
	enemy.boss_phase_burst_fired = true
	if enemy.dying: cancel()
	sync_visual()
	queue_redraw()

func _draw() -> void:
	if enemy.dying or enemy.health <= 0: return
	draw_set_transform_matrix(global_transform.affine_inverse())
	CaramelEncounterVisuals.draw(self)
