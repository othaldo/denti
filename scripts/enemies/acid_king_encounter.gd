class_name AcidKingEncounter
extends Node2D
## The encounter clock owns warnings, field transitions, staggered stomps and recovery.

enum State { POSITION, WARN_CHANNEL, FLOW, WARN_SHIFT, WARN_STOMP, STOMP, RECALL, OPEN, RECOVERY }
enum Attack { CHANNELS, STOMP, TIDE }
const SAVE_VERSION := 1
const MAX_FIELDS := 2
var enemy: Enemy
var profile: AcidKingData
var rig: KingAcidRig
var volley: BossPaintedVolley
var state := State.POSITION
var remaining := 0.65
var elapsed := 0.0
var cycle := 0
var attack_kind := Attack.CHANNELS
var shift_index := 0
var axis := 0
var anchor := Vector2.ZERO
var aim := Vector2.RIGHT
var pending: Array[Dictionary] = []
var fields: Array[Dictionary] = []
var rows: Array[Dictionary] = []
var channels_created := 0
var rows_fired := 0
var damage_by_source := {"acid": 0.0, "stomp": 0.0}
var movement := 0.0
var active: bool:
	get: return state not in [State.POSITION, State.OPEN, State.RECOVERY]

func _ready() -> void:
	add_to_group("acid_king_encounters")
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR
	z_index = -2
	remaining = profile.approach_seconds
	rig = KingAcidRig.new()
	enemy.sprite.texture = null
	rig.scale = Vector2.ONE / enemy.sprite_base_scale.x
	rig.position = Vector2(0, 55) / enemy.sprite_base_scale.x
	enemy.sprite.add_child(rig)
	volley = BossPaintedVolley.new()
	volley.enemy = enemy
	volley.profile = profile.shards
	volley.texture = KingAcidArt.texture(7)
	add_child(volley)
	sync_visual()

func damage_factor() -> float:
	return profile.open_damage_factor if state == State.OPEN else profile.closed_damage_factor

func cancel() -> void:
	state = State.POSITION
	remaining = profile.approach_seconds
	pending.clear()
	fields.clear()
	rows.clear()
	if volley != null: volley.clear()
	sync_visual()
	queue_redraw()

func begin(forced: int = -1, seconds: float = -1) -> void:
	attack_kind = clampi(forced, 0, 2) as Attack if forced >= 0 else posmod(cycle, 3) as Attack
	cycle += 1
	shift_index = 0
	axis = cycle % 2
	anchor = HazardGeometry.player_at(enemy.target, seconds) if seconds >= 0 else enemy.target.global_position
	if attack_kind == Attack.STOMP: _warn_stomp(seconds)
	else:
		_plan_channels(false)
		state = State.WARN_CHANNEL
		remaining = profile.warning_seconds
		enemy.attack_performed.emit(&"boss_warning")

func advance(delta: float) -> void:
	if enemy.dying or enemy.health <= 0 or enemy.target == null: return
	if enemy.boss_phase_timer > 0:
		sync_visual()
		return
	var left := maxf(delta, 0)
	var spent := 0.0
	while left > 0.000001:
		var rate := minf(enemy.overtime_attack_factor(), 1.4) if state in [State.POSITION, State.RECOVERY] else 1.0
		var step := minf(left, maxf(remaining, 0) / rate)
		if state == State.STOMP:
			_fire_due_rows()
			for row in rows:
				if not row.fired and row.delay > 0.000001: step = minf(step, row.delay)
		_tick_fields(step, spent)
		volley.advance(step, spent)
		if state == State.STOMP: _tick_rows(step, spent)
		if state == State.POSITION: _move(step)
		elif state == State.FLOW: _move(step, profile.flow_movement_factor)
		remaining = maxf(remaining - step * rate, 0)
		elapsed += step
		spent += step
		left -= step
		if remaining <= 0.000001: _next(spent)
	sync_visual()
	queue_redraw()

func _next(seconds: float) -> void:
	match state:
		State.POSITION:
			if _reserved() or not _visible_bounds().has_point(enemy.global_position): remaining = 0.15
			else: begin(-1, seconds)
		State.WARN_CHANNEL, State.WARN_SHIFT:
			var duration := profile.shift_flow_seconds if attack_kind == Attack.TIDE else profile.flow_seconds
			_activate_fields(duration + profile.recall_seconds + (_stomp_duration() + profile.stomp_warning_seconds if attack_kind == Attack.TIDE and enemy.boss_phase >= 2 else 0))
			state = State.FLOW
			remaining = duration
		State.FLOW:
			if attack_kind == Attack.TIDE and shift_index < profile.shifts:
				shift_index += 1
				for field in fields: field.life = minf(field.life, profile.old_channel_fade)
				_plan_channels(true)
				state = State.WARN_SHIFT
				remaining = profile.shift_warning_seconds
				enemy.attack_performed.emit(&"boss_warning")
			elif attack_kind == Attack.TIDE and enemy.boss_phase >= 2: _warn_stomp(seconds)
			else: _recall()
		State.WARN_STOMP:
			state = State.STOMP
			remaining = _stomp_duration()
			_fire_due_rows()
		State.STOMP: _recall()
		State.RECALL:
			fields.clear()
			state = State.OPEN
			remaining = profile.open_seconds
		State.OPEN:
			state = State.RECOVERY
			remaining = profile.recovery_seconds
		State.RECOVERY:
			state = State.POSITION
			remaining = profile.approach_seconds

func _visible_bounds() -> Rect2:
	var rect := enemy.get_canvas_transform().affine_inverse() * enemy.get_viewport_rect()
	var inset := Vector2(minf(115, rect.size.x * 0.28), minf(125, rect.size.y * 0.28))
	return Rect2(rect.position + inset, rect.size - inset * 2)

func _reserved() -> bool:
	for other: AcidKingEncounter in get_tree().get_nodes_in_group("acid_king_encounters"):
		if other != self and other.enemy.target == enemy.target and other.enemy.health > 0 and (other.active or not other.fields.is_empty() or not other.volley.entries.is_empty()): return true
	return false

func _move(delta: float, speed_factor: float = 1.0) -> void:
	var target := enemy.target.global_position
	var away := target.direction_to(enemy.global_position)
	if away.is_zero_approx(): away = Vector2.LEFT
	var distance := clampf(enemy.global_position.distance_to(target), enemy.data.radius + 45, profile.preferred_distance)
	var bounds := _visible_bounds()
	var desired := (target + away.rotated(0.25 + 0.12 * profile.action_bonus) * distance).clamp(bounds.position, bounds.end)
	var margin := Vector2.ONE * (DentiArena.WALL_WIDTH + enemy.data.radius + 6)
	desired = desired.clamp(margin, enemy.target.arena.arena_size - margin)
	var next := enemy.global_position.move_toward(desired, enemy._movement_speed() * profile.move_factor * speed_factor * delta)
	var near := Geometry2D.get_closest_point_to_segment(target, enemy.global_position, next)
	var clearance := minf(enemy.global_position.distance_to(target), enemy.data.radius + HazardGeometry.PLAYER_RADIUS + 5)
	if near.distance_to(target) >= clearance - 0.01:
		movement += next.distance_to(enemy.global_position)
		enemy.global_position = next

func _plan_channels(shift: bool) -> void:
	pending.clear()
	var visible := enemy.get_canvas_transform().affine_inverse() * enemy.get_viewport_rect()
	var arena := Rect2(Vector2.ONE * DentiArena.PLAYER_MARGIN, enemy.target.arena.arena_size - Vector2.ONE * DentiArena.PLAYER_MARGIN * 2)
	var area := visible.grow(80).intersection(arena)
	if shift: anchor[axis] += profile.shift_distance * (1 if shift_index % 2 == 1 else -1)
	var coordinate: float = clampf(anchor[axis], area.position[axis] + profile.channel_half_width, area.end[axis] - profile.channel_half_width)
	var side := 1.0 if cycle % 2 == 0 else -1.0
	if coordinate + profile.channel_spacing * side < area.position[axis] or coordinate + profile.channel_spacing * side > area.end[axis]: side *= -1
	for index in profile.channel_count:
		var at := area.get_center()
		at[axis] = clampf(coordinate + index * profile.channel_spacing * side, area.position[axis] + profile.channel_half_width, area.end[axis] - profile.channel_half_width)
		var half_size := area.size * 0.5
		half_size[axis] = profile.channel_half_width
		pending.append({"at": at, "half_size": half_size})

func _activate_fields(lifetime: float) -> void:
	fields.clear()
	for planned in pending:
		# One shared budget across the coordinated double-boss encounter.
		for other: AcidKingEncounter in get_tree().get_nodes_in_group("acid_king_encounters"):
			if other != self and other.enemy.target == enemy.target: other.fields.clear()
		if fields.size() >= MAX_FIELDS: break
		fields.append({"at": planned.at, "half_size": planned.half_size, "life": lifetime, "duration": lifetime, "age": 0.0, "cooldown": 0.0})
		channels_created += 1
	pending.clear()
	enemy.attack_performed.emit(&"acid")

func _tick_fields(delta: float, first: float) -> void:
	for index in range(fields.size() - 1, -1, -1):
		var field := fields[index]
		var step := minf(delta, field.life)
		var active_after := maxf(field.cooldown, 0)
		field.cooldown = maxf(field.cooldown - delta, 0)
		field.life -= delta
		field.age += step
		var ends := AcidKingVisuals.channel_ends(field)
		if active_after <= step and HazardGeometry.swept_capsule(enemy.target, ends[0], ends[1], profile.channel_half_width, first + active_after, first + step):
			var health := enemy.target.stats.health
			enemy.target.take_hit(enemy.attack_damage * profile.field_damage_factor, enemy.inflicted_statuses)
			damage_by_source.acid += maxf(health - enemy.target.stats.health, 0)
			field.cooldown = profile.field_tick_seconds
		if field.life <= 0: fields.remove_at(index)

func _stomp_duration() -> float:
	return (profile.rows(enemy.boss_phase) - 1) * profile.stomp_row_interval + profile.stomp_active_seconds

func _warn_stomp(seconds: float) -> void:
	state = State.WARN_STOMP
	remaining = profile.stomp_warning_seconds
	var at := HazardGeometry.player_at(enemy.target, seconds) if seconds >= 0 else enemy.target.global_position
	aim = enemy.global_position.direction_to(at)
	if aim.is_zero_approx(): aim = Vector2.DOWN
	rows.clear()
	for index in profile.rows(enemy.boss_phase):
		rows.append({"at": enemy.global_position + aim * (profile.stomp_start + index * profile.stomp_spacing), "direction": aim, "delay": index * profile.stomp_row_interval, "fired": false, "hit": false})
	enemy.attack_performed.emit(&"boss_warning")

func _fire_due_rows() -> void:
	for row in rows:
		if not row.fired and row.delay <= 0.000001:
			row.fired = true
			rows_fired += 1
			volley.fire(row.at, EnemyProjectilePatterns.fan_directions(row.direction, profile.shard_count(enemy.boss_phase), deg_to_rad(18)), &"king_shard")
			enemy.attack_performed.emit(&"boss_pulse")

func _tick_rows(delta: float, first: float) -> void:
	for row in rows:
		var active_end := minf(delta, profile.stomp_active_seconds + row.delay)
		if row.fired and not row.hit and active_end >= 0:
			var tangent: Vector2 = row.direction.orthogonal() * profile.stomp_half_span
			if HazardGeometry.swept_capsule(enemy.target, row.at - tangent, row.at + tangent, profile.stomp_radius, first, first + active_end):
				var health := enemy.target.stats.health
				enemy.target.take_hit(enemy.attack_damage, enemy.inflicted_statuses)
				damage_by_source.stomp += maxf(health - enemy.target.stats.health, 0)
				row.hit = true
		row.delay -= delta

func _recall() -> void:
	state = State.RECALL
	remaining = profile.recall_seconds
	for field in fields: field.life = minf(field.life, profile.recall_seconds)
	rows.clear()

func sync_visual() -> void:
	if rig == null: return
	var kind := 1 if state in [State.WARN_STOMP, State.STOMP] else (2 if state in [State.RECALL, State.OPEN] else 0)
	var prep := 0.0
	if state == State.WARN_STOMP: prep = 1 - remaining / profile.stomp_warning_seconds
	elif state in [State.STOMP, State.FLOW, State.RECALL, State.OPEN]: prep = 1
	elif state in [State.WARN_CHANNEL, State.WARN_SHIFT]: prep = 1 - remaining / (profile.warning_seconds if state == State.WARN_CHANNEL else profile.shift_warning_seconds)
	rig.sample(elapsed, prep, clampf(1 - remaining / _stomp_duration(), 0, 1) if state == State.STOMP else 0, kind, state in [State.POSITION, State.FLOW], state == State.OPEN)
	var level := 1.0
	if state == State.FLOW: level = 0.25 + 0.75 * remaining / (profile.shift_flow_seconds if attack_kind == Attack.TIDE else profile.flow_seconds)
	elif state == State.WARN_SHIFT: level = 1 - 0.75 * remaining / profile.shift_warning_seconds
	elif state == State.RECALL: level = 1 - 0.75 * remaining / profile.recall_seconds
	rig.show_acid_level(level)

func _draw() -> void:
	if enemy.dying or enemy.health <= 0: return
	AcidKingVisuals.draw(self)

func save_data() -> Dictionary:
	return AcidKingSnapshot.capture(self)

func restore(saved: Dictionary) -> void:
	AcidKingSnapshot.restore(self, saved)
