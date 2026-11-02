class_name CrownCourtEncounter
extends Node2D
## One clock owns guard turns, fixed judgments, portal releases and pulse cadence.
# Append new states; existing save-state numbers keep their meaning.
enum State { POSITION, TURN, EDICT_WARN, EDICT_HIT, PORTAL_WARN, PORTAL_FLIGHT, NERVE_WARN, NERVE_RELEASE, OPEN, RECOVERY, REPOSITION }
enum Attack { EDICT, PORTAL, NERVE }
const SAVE_VERSION := 2
var enemy: Enemy
var profile: CrownCourtData
var rig: EmperorCourtRig
var shots: BossPaintedVolley
var lances: BossPaintedVolley
var needles: BossPaintedVolley
var needle_rays: Array[Vector2] = []
var state := State.POSITION
var attack_kind := Attack.EDICT
var remaining := 0.65
var elapsed := 0.0
var cycle := 0
var step_index := 0
var facing := Vector2.DOWN
var turn_from := 0.0
var turn_to := 0.0
var origin := Vector2.ZERO
var edict_angle := 0.0
var portal_a := Vector2.ZERO
var portal_b := Vector2.ZERO
var verdict_hit := false
var combo := false
# An old verdict warning must not gain an unannounced portal when restored.
var portal_combo := false
var portal_followup := false
var legacy_sequence := false
var guard_remaining := 0.0
var guard_delay := 0.0
var warnings := 0
var verdicts_fired := 0
var portals_fired := 0
var pulses_fired := 0
var movement := 0.0
var floor_damage := 0.0
var active: bool:
	get: return state not in [State.POSITION, State.TURN, State.OPEN, State.RECOVERY]
var exposed: bool:
	get: return state in [State.NERVE_WARN, State.NERVE_RELEASE, State.OPEN]

func _ready() -> void:
	add_to_group("crown_court_encounters")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	z_index = -2
	remaining = profile.position_seconds
	enemy.sprite.texture = null
	rig = EmperorCourtRig.new()
	rig.scale = Vector2.ONE / enemy.sprite_base_scale.x
	rig.position = Vector2(0, 50) / enemy.sprite_base_scale.x
	enemy.sprite.add_child(rig)
	shots = _batch(profile.shots)
	lances = _batch(profile.lance)
	needles = _batch(profile.needles)
	sync_visual()

func _batch(data: BossProjectileData) -> BossPaintedVolley:
	var batch := BossPaintedVolley.new()
	batch.enemy = enemy
	batch.profile = data
	batch.texture = EmperorCourtArt.texture(7)
	batch.orient_to_velocity = true
	add_child(batch)
	return batch

func damage_factor(incoming: Vector2, directional: bool = true) -> float:
	if exposed: return profile.open_damage_factor
	if not directional: return 1.0
	var toward := -incoming.normalized() if not incoming.is_zero_approx() else enemy.global_position.direction_to(enemy.target.global_position)
	return profile.guard_damage_factor if facing.dot(toward) >= cos(deg_to_rad(profile.guard_half_angle)) else 1.0

func cancel() -> void:
	state = State.POSITION
	remaining = profile.position_seconds
	combo = false
	portal_combo = false
	portal_followup = false
	legacy_sequence = false
	guard_remaining = 0.0
	guard_delay = 0.0
	verdict_hit = false
	if shots != null: shots.clear()
	if lances != null: lances.clear()
	if needles != null: needles.clear()
	needle_rays.clear()
	sync_visual()
	queue_redraw()

func begin(forced: int = -1, seconds: float = -1) -> void:
	legacy_sequence = false
	portal_followup = false
	attack_kind = clampi(forced, 0, 2) as Attack if forced >= 0 else posmod(cycle, 3) as Attack
	cycle += 1
	step_index = 0
	origin = enemy.global_position
	combo = false
	portal_combo = false
	if attack_kind == Attack.EDICT: _edict(seconds)
	elif attack_kind == Attack.PORTAL: _portal(seconds)
	else: _nerve(seconds)

func _warn() -> void:
	warnings += 1
	enemy.attack_performed.emit(&"boss_warning")

func _edict(seconds: float = -1) -> void:
	if not _court_in_range(seconds):
		_reposition(Attack.EDICT)
		return
	state = State.EDICT_WARN
	portal_combo = legacy_sequence and enemy.boss_phase >= profile.combo_phase and step_index >= profile.verdicts(enemy.boss_phase) - 1
	remaining = edict_warning_duration()
	_lock_verdict(seconds)
	if portal_combo: _lock_portal(seconds)
	_warn()

func _lock_verdict(seconds: float = -1) -> void:
	origin = enemy.global_position
	var at := HazardGeometry.player_at(enemy.target, seconds) if seconds >= 0 else enemy.target.global_position
	if not legacy_sequence:
		at += (enemy.target.velocity * profile.verdict_lead_seconds).limit_length(profile.verdict_lead_distance)
	var direction := origin.direction_to(at)
	# Aim the damaging sector at Denti once; the warning never tracks afterward.
	edict_angle = (facing if direction.is_zero_approx() else direction).angle()
	verdict_hit = false

func _portal(seconds: float = -1, followup: bool = false) -> void:
	portal_followup = followup
	state = State.PORTAL_WARN
	remaining = profile.portal_warning_seconds
	_lock_portal(seconds)
	_warn()

func _lock_portal(seconds: float = -1) -> void:
	CrownPortalPattern.plan(self, seconds)

func _nerve(seconds: float = -1) -> void:
	if _needs_court(Attack.NERVE, step_index) and not _court_in_range(seconds):
		_reposition(Attack.NERVE)
		return
	state = State.NERVE_WARN
	origin = enemy.global_position
	remaining = profile.nerve_warning_seconds
	# New fights combine the ring with dodgeable flying needles. The old
	# immediate floor sector plus a dense ring could seal slow corner exits.
	combo = legacy_sequence and enemy.boss_phase >= 2 and step_index == 0
	needle_rays.clear()
	if not legacy_sequence and not combo and step_index % 2 == 0:
		var at := HazardGeometry.player_at(enemy.target, seconds) if seconds >= 0 else enemy.target.global_position
		at += (enemy.target.velocity * profile.needle_lead_seconds).limit_length(profile.needle_lead_distance)
		var direction := origin.direction_to(at)
		if direction.is_zero_approx(): direction = facing
		needle_rays = EnemyProjectilePatterns.fan_directions(direction, profile.needle_count(), profile.needle_spacing)
	if enemy.boss_phase >= 2 and step_index == 0:
		_lock_verdict(seconds)
	remaining = nerve_warning_duration()
	_warn()

func advance(delta: float) -> void:
	if enemy.dying or enemy.health <= 0 or enemy.target == null: return
	if enemy.boss_phase_timer > 0: return
	var left := maxf(delta, 0)
	var spent := 0.0
	while left > 0.000001:
		var step := minf(left, maxf(remaining, 0))
		_tick_guard(step)
		shots.advance(step, spent)
		lances.advance(step, spent)
		needles.advance(step, spent)
		if state == State.EDICT_HIT or state == State.NERVE_RELEASE and combo: _hit_verdict(step, spent)
		if state == State.POSITION: _move(step)
		elif state == State.PORTAL_FLIGHT: _move(step, profile.portal_drift_factor)
		elif state == State.REPOSITION: _move(step, profile.reposition_move_factor)
		elif state == State.OPEN:
			var before := profile.open_seconds - remaining
			var walking := maxf(before + step - maxf(before, profile.recovery_settle_seconds), 0)
			_move(walking, profile.recovery_move_factor)
		elif state == State.RECOVERY: _move(step, profile.recovery_move_factor)
		remaining = maxf(remaining - step, 0)
		elapsed += step
		left -= step
		spent += step
		if state == State.TURN:
			facing = Vector2.from_angle(lerp_angle(turn_from, turn_to, smoothstep(0, 1, 1 - remaining / profile.turn_seconds)))
		if remaining <= 0.000001: _next(spent)
	sync_visual()
	queue_redraw()

func _next(seconds: float) -> void:
	match state:
		State.POSITION:
			if _reserved(): remaining = 0.15
			else: begin(-1, seconds)
		State.TURN:
			facing = Vector2.from_angle(turn_to)
			state = State.POSITION
			remaining = profile.position_seconds
		State.EDICT_WARN:
			state = State.EDICT_HIT
			remaining = profile.impact_seconds
			verdicts_fired += 1
			if portal_combo: _fire_portal()
			for side in [0, 1]:
				var step_angle := deg_to_rad(profile.court_half_angle * 2 / maxi(profile.fan_count() - 1, 1))
				var rays := EnemyProjectilePatterns.fan_directions(Vector2.from_angle(edict_angle + side * PI), profile.fan_count(), step_angle)
				if legacy_sequence: shots.fire(origin, rays, &"court_shard")
				else: needles.fire(origin, rays, &"imperial_judgment")
		State.EDICT_HIT:
			step_index += 1
			if not legacy_sequence and enemy.boss_phase >= profile.combo_phase and step_index >= profile.verdicts(enemy.boss_phase): _portal(seconds, true)
			elif step_index < profile.verdicts(enemy.boss_phase): _reposition(Attack.EDICT)
			elif portal_combo:
				step_index = 0
				_reposition(Attack.NERVE)
			elif enemy.boss_phase >= 1:
				step_index = 0
				_portal(seconds)
			else: _open()
		State.PORTAL_WARN:
			var distance := portal_a.distance_to(portal_b)
			_fire_portal()
			state = State.PORTAL_FLIGHT
			remaining = maxf(distance / profile.lance.speed, 0.01)
		State.PORTAL_FLIGHT:
			if portal_followup:
				portal_followup = false
				if step_index < profile.verdicts(enemy.boss_phase): _reposition(Attack.EDICT)
				else:
					step_index = 0
					_reposition(Attack.NERVE)
			else:
				step_index += 1
				if step_index < profile.portals(enemy.boss_phase): _reposition(Attack.PORTAL)
				else: _open()
		State.NERVE_WARN:
			state = State.NERVE_RELEASE
			remaining = profile.impact_seconds
			pulses_fired += 1
			shots.fire(origin, EnemyProjectilePatterns.circle_directions(profile.rays(enemy.boss_phase), pulse_angle()), &"nerve")
			if not needle_rays.is_empty(): needles.fire(origin, needle_rays, &"imperial_needle")
			needle_rays.clear()
		State.NERVE_RELEASE:
			step_index += 1
			if step_index < profile.pulses(enemy.boss_phase): _reposition(Attack.NERVE)
			else: _open()
		State.REPOSITION:
			if attack_kind == Attack.EDICT: _edict(seconds)
			elif attack_kind == Attack.PORTAL: _portal(seconds)
			else: _nerve(seconds)
		State.OPEN:
			state = State.RECOVERY
			remaining = profile.recovery_seconds
		State.RECOVERY:
			if legacy_sequence:
				state = State.TURN
				remaining = profile.turn_seconds
				_plan_guard()
				_warn()
			else:
				state = State.POSITION
				remaining = profile.position_seconds

func edict_warning_duration() -> float:
	if portal_combo: return profile.combo_warning_seconds
	return profile.followup_warning_seconds if not legacy_sequence and step_index > 0 else profile.warning_seconds

func nerve_warning_duration() -> float:
	return profile.needle_warning_seconds if not needle_rays.is_empty() else profile.nerve_warning_seconds

func _reposition(kind: Attack) -> void:
	attack_kind = kind
	state = State.REPOSITION
	remaining = profile.reposition_seconds
	combo = false
	portal_combo = false
	needle_rays.clear()

func _fire_portal() -> void:
	lances.fire(portal_a, [portal_a.direction_to(portal_b)], &"portal_lance")
	if not lances.entries.is_empty(): lances.entries[-1].life = minf(portal_a.distance_to(portal_b) / profile.lance.speed, profile.lance.lifetime)
	portals_fired += 1

func _open() -> void:
	state = State.OPEN
	remaining = profile.open_seconds
	combo = false
	portal_combo = false
	if not legacy_sequence:
		_plan_guard()
		guard_remaining = profile.turn_seconds
		guard_delay = profile.recovery_settle_seconds
		_warn()

func _plan_guard() -> void:
	turn_from = facing.angle()
	turn_to = turn_from + deg_to_rad(profile.guard_turn_degrees) * (1 if cycle % 2 else -1)

func _tick_guard(delta: float) -> void:
	if guard_remaining <= 0: return
	var active_seconds := maxf(delta - guard_delay, 0)
	guard_delay = maxf(guard_delay - delta, 0)
	if active_seconds <= 0: return
	guard_remaining = maxf(guard_remaining - active_seconds, 0)
	facing = Vector2.from_angle(lerp_angle(turn_from, turn_to, smoothstep(0, 1, 1 - guard_remaining / profile.turn_seconds)))

func pulse_angle() -> float:
	return cycle * profile.nerve_cycle_radians + step_index * profile.nerve_step_radians

func _hit_verdict(delta: float, first: float) -> void:
	if verdict_hit: return
	for side in [0, 1]:
		if HazardGeometry.swept_sector(enemy.target, origin, Vector2.from_angle(edict_angle + side * PI), profile.court_radius, deg_to_rad(profile.court_half_angle), first, first + delta):
			var before := enemy.target.stats.health
			enemy.target.take_hit(enemy.attack_damage * profile.verdict_damage_factor, enemy.inflicted_statuses)
			floor_damage += maxf(before - enemy.target.stats.health, 0)
			verdict_hit = true
			break

func _reserved() -> bool:
	for other: CrownCourtEncounter in get_tree().get_nodes_in_group("crown_court_encounters"):
		if other != self and other.enemy.target == enemy.target and other.enemy.health > 0 and (other.active or not other.shots.entries.is_empty() or not other.lances.entries.is_empty() or not other.needles.entries.is_empty()): return true
	return false

func court_start_distance() -> float:
	return minf(profile.court_approach_distance + profile.court_position_tolerance, profile.court_radius)

func _court_in_range(seconds: float = -1) -> bool:
	var at := HazardGeometry.player_at(enemy.target, seconds) if seconds >= 0 else enemy.target.global_position
	return enemy.global_position.distance_squared_to(at) <= pow(court_start_distance(), 2)

func _needs_court(kind: int, index: int) -> bool:
	return kind == Attack.EDICT or kind == Attack.NERVE and enemy.boss_phase >= 2 and index == 0

func _move(delta: float, speed_factor: float = 1.0) -> void:
	var target := enemy.target.global_position
	var away := target.direction_to(enemy.global_position)
	if away.is_zero_approx(): away = Vector2.LEFT
	var next_kind := posmod(cycle, 3) if state == State.POSITION else int(attack_kind)
	var next_index := 0 if state == State.POSITION else step_index
	var closing_for_court := state in [State.POSITION, State.REPOSITION] and _needs_court(next_kind, next_index)
	var wanted := minf(profile.court_approach_distance, court_start_distance()) if closing_for_court else profile.preferred_distance
	# Close distant gaps without retreating from a player who stays in melee.
	var distance := clampf(enemy.global_position.distance_to(target), enemy.data.radius + HazardGeometry.PLAYER_RADIUS + 5, wanted)
	var visible := enemy.get_canvas_transform().affine_inverse() * enemy.get_viewport_rect()
	var inset := Vector2(minf(130, visible.size.x * 0.28), minf(140, visible.size.y * 0.28))
	var bounds := Rect2(visible.position + inset, visible.size - inset * 2)
	var desired := (target + (away if closing_for_court else away.rotated(0.22)) * distance).clamp(bounds.position, bounds.end)
	var margin := Vector2.ONE * (DentiArena.WALL_WIDTH + enemy.data.radius + 6)
	desired = desired.clamp(margin, enemy.target.arena.arena_size - margin)
	var next := enemy.global_position.move_toward(desired, enemy._movement_speed() * profile.movement_factor * speed_factor * delta)
	var clearance := minf(enemy.global_position.distance_to(target), enemy.data.radius + HazardGeometry.PLAYER_RADIUS + 5)
	if Geometry2D.get_closest_point_to_segment(target, enemy.global_position, next).distance_to(target) >= clearance - 0.01:
		movement += enemy.global_position.distance_to(next)
		enemy.global_position = next

func sync_visual() -> void:
	if rig == null: return
	var duration := edict_warning_duration()
	if state == State.PORTAL_WARN: duration = profile.portal_warning_seconds
	elif state == State.NERVE_WARN: duration = nerve_warning_duration()
	var progress := clampf(1 - remaining / duration, 0, 1) if state in [State.EDICT_WARN, State.PORTAL_WARN, State.NERVE_WARN] else 0.0
	rig.sample(elapsed, progress, int(attack_kind), facing, exposed)

func _draw() -> void:
	if enemy.dying or enemy.health <= 0: return
	CrownCourtVisuals.draw(self)

func save_data() -> Dictionary: return CrownCourtSnapshot.capture(self)
func restore(saved: Dictionary) -> void: CrownCourtSnapshot.restore(self, saved)
