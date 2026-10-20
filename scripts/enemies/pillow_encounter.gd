class_name PillowEncounter
extends Node2D

const ART: Texture2D = preload("res://assets/enemies/count_pillow_atlas.png")
static var pillow_art: AtlasTexture
static var fold_art: AtlasTexture
var enemy: Enemy
var profile: PillowEncounterData
var active := false
var elapsed := 0.0
var cooldown := 1.5
var origin := Vector2.ZERO
var forward := Vector2.DOWN
var second_offset := 0.0
var count := 1
var cycle := 0
var hit_mask := 0

func _ready() -> void:
	if pillow_art == null:
		pillow_art = AtlasTexture.new()
		pillow_art.atlas = ART
		pillow_art.region = Rect2(200, 50, 850, 720)
		pillow_art.filter_clip = true
		fold_art = AtlasTexture.new()
		fold_art.atlas = ART
		fold_art.region = Rect2(30, 875, 1190, 310)
		fold_art.filter_clip = true
	add_to_group("pillow_encounters")
	z_index = -2
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR

func _process(_delta: float) -> void:
	if active: queue_redraw()

func cancel() -> void:
	active = false
	cooldown = profile.recovery_seconds
	queue_redraw()

func begin() -> void:
	active = true
	elapsed = 0
	hit_mask = 0
	# Put the boss along the attack axis, rather than in the lateral escape path.
	var to_boss := enemy.global_position - enemy.target.global_position
	forward = Vector2.RIGHT if absf(to_boss.x) > absf(to_boss.y) else Vector2.DOWN
	cycle += 1
	count = 2 if enemy.boss_phase >= 1 else 1
	var arena := enemy.target.arena.arena_size
	var margin := DentiArena.PLAYER_MARGIN + profile.lane_width * 0.5
	origin = enemy.target.global_position.clamp(Vector2.ONE * margin, arena - Vector2.ONE * margin)
	# The whole announced path fits inside the arena, including corner spawns.
	var axis := 1 if forward == Vector2.DOWN else 0
	origin[axis] = clampf(origin[axis], margin, arena[axis] - margin - profile.fold_length)
	var side := 1 - axis
	second_offset = profile.second_lane_offset if origin[side] + profile.second_lane_offset <= arena[side] - margin else -profile.second_lane_offset
	enemy.attack_performed.emit(&"boss_warning")
	queue_redraw()

func advance(delta: float) -> void:
	if enemy.dying or enemy.health <= 0 or enemy.boss_phase_timer > 0:
		return
	if not active:
		cooldown -= delta * minf(enemy.overtime_attack_factor(), 1.4)
		# A second Graf waits for the first one's safe sequence to finish.
		var reserved := false
		for other in get_tree().get_nodes_in_group("pillow_encounters"):
			if other != self and other.active and other.enemy.health > 0: reserved = true
		if cooldown <= 0 and not reserved:
			begin()
		else:
			var preferred := Vector2.RIGHT if cycle % 2 == 0 else Vector2.UP
			var margin := DentiArena.WALL_WIDTH + enemy.data.radius + 6
			var anchor := enemy.global_position
			for side in [preferred, preferred.orthogonal(), -preferred, -preferred.orthogonal()]:
				var candidate: Vector2 = (enemy.target.global_position + side * profile.anchor_distance).clamp(Vector2.ONE * margin, enemy.target.arena.arena_size - Vector2.ONE * margin)
				if candidate.distance_to(enemy.target.global_position) >= profile.anchor_distance * 0.9:
					anchor = candidate
					break
			enemy.global_position = enemy.global_position.move_toward(anchor, enemy._movement_speed() * delta)
		return
	var before := elapsed
	elapsed += maxf(delta, 0)
	for lane in count:
		var slam := profile.warning_seconds + lane * profile.second_slam_delay
		if before < slam and elapsed >= slam:
			enemy.attack_performed.emit(&"boss_pulse")
			if HazardGeometry.circle_box(HazardGeometry.player_at(enemy.target, slam - before), slam_rect(lane)):
				_hit(lane * 2, enemy.attack_damage)
		var fold_start := slam + profile.fold_delay
		var first := maxf(before, fold_start)
		var last := minf(elapsed, fold_start + profile.fold_seconds)
		if first < last:
			var from := lane_origin(lane) + forward * profile.fold_length * ((first - fold_start) / profile.fold_seconds)
			var to := lane_origin(lane) + forward * profile.fold_length * ((last - fold_start) / profile.fold_seconds)
			if HazardGeometry.moving_box(enemy.target, from, to, fold_half_size(), first - before, last - before):
				_hit(lane * 2 + 1, enemy.attack_damage * profile.fold_damage_factor)
	if elapsed >= profile.attack_seconds(count): cancel()
	queue_redraw()

func _hit(bit: int, amount: float) -> void:
	if hit_mask & (1 << bit): return
	hit_mask |= 1 << bit
	enemy.target.take_hit(amount, enemy.inflicted_statuses)

func lane_origin(lane: int) -> Vector2:
	return origin + Vector2(forward.y, forward.x) * second_offset * lane

func slam_rect(lane: int) -> Rect2:
	var size := Vector2(profile.lane_width, profile.slam_length) if forward == Vector2.DOWN else Vector2(profile.slam_length, profile.lane_width)
	return Rect2(lane_origin(lane) - size * 0.5, size)

func fold_half_size() -> Vector2:
	return (Vector2(profile.lane_width, profile.fold_thickness) if forward == Vector2.DOWN else Vector2(profile.fold_thickness, profile.lane_width)) * 0.5

func save_data() -> Dictionary:
	return {"active": active, "elapsed": elapsed, "cooldown": cooldown, "origin": SnapshotValues.vector_data(origin), "forward": SnapshotValues.vector_data(forward), "second_offset": second_offset, "count": count, "cycle": cycle, "hit_mask": hit_mask}

func restore(saved: Dictionary) -> void:
	active = bool(saved.get("active", false))
	count = clampi(int(saved.get("count", 1)), 1, 2)
	elapsed = clampf(float(saved.get("elapsed", 0)), 0, profile.attack_seconds(count))
	cooldown = clampf(float(saved.get("cooldown", profile.recovery_seconds)), 0, profile.recovery_seconds)
	origin = SnapshotValues.read_vector(saved.get("origin", [0, 0]))
	var saved_forward := SnapshotValues.read_vector(saved.get("forward", [0, 1]))
	forward = Vector2.RIGHT if saved_forward.x > 0.5 else Vector2.DOWN
	second_offset = clampf(float(saved.get("second_offset", 0)), -profile.second_lane_offset, profile.second_lane_offset)
	cycle = maxi(int(saved.get("cycle", 0)), 0)
	hit_mask = clampi(int(saved.get("hit_mask", 0)), 0, 15)
	# Old saves may contain a pending generic charge/radial. Start safely instead.
	enemy.special_phase = Enemy.SpecialPhase.COOLDOWN
	enemy.boss_radial_volleys_remaining = 0
	enemy.boss_phase_burst_fired = true
	queue_redraw()

func _draw() -> void:
	if not active or enemy.health <= 0 or enemy.dying: return
	# World-locked warnings stay where they were announced while the boss moves.
	draw_set_transform_matrix(global_transform.affine_inverse())
	for lane in count:
		_draw_lane(lane)

func _draw_lane(lane: int) -> void:
	var slam := profile.warning_seconds + lane * profile.second_slam_delay
	var fold_start := slam + profile.fold_delay
	var box := slam_rect(lane)
	var center := lane_origin(lane)
	var half := fold_half_size()
	var end := center + forward * profile.fold_length
	var corridor := Rect2(center - half, half * 2).expand(end - half).expand(end + half)
	var amber := Color(1.0, 0.62, 0.20, 0.9)
	if elapsed < slam:
		var progress := clampf(elapsed / slam, 0, 1)
		draw_rect(box, Color(0.65, 0.22, 0.10, 0.25 + progress * 0.15))
		draw_rect(box, amber, false, 3, true)
		draw_rect(corridor, Color(0.9, 0.52, 0.18, 0.08))
		draw_rect(corridor, Color(1, 0.67, 0.28, 0.55), false, 2, true)
		for step in 4:
			var at := center + forward * (45 + step * 85)
			var side := forward.orthogonal() * 9
			draw_polyline(PackedVector2Array([at + side - forward * 9, at, at - side - forward * 9]), amber, 2, true)
		_paint(pillow_art, center - Vector2(0, 55 * (1 - progress)), profile.lane_width * (0.65 + 0.35 * progress), Color(1, 1, 1, 0.3 + 0.6 * progress))
		draw_arc(center, 23, -PI * 0.5, -PI * 0.5 + TAU * progress, 32, amber, 4, true)
	elif elapsed < fold_start + profile.fold_seconds:
		var since := elapsed - slam
		if since < profile.fold_delay:
			_paint(pillow_art, center, profile.lane_width, Color.WHITE)
			draw_rect(box, Color(1, 0.32, 0.19, 0.9 * (1 - since / profile.fold_delay)), false, 4, true)
		else:
			draw_rect(corridor, Color(0.7, 0.32, 0.17, 0.08))
			draw_rect(corridor, Color(1, 0.67, 0.28, 0.5), false, 2, true)
			var at := center.lerp(end, clampf((elapsed - fold_start) / profile.fold_seconds, 0, 1))
			# Rotate the generated ridge; every source pixel keeps its aspect ratio.
			draw_set_transform_matrix(global_transform.affine_inverse() * Transform2D(forward.angle() - PI * 0.5, at))
			_paint(fold_art, Vector2.ZERO, profile.lane_width, Color.WHITE)
			draw_set_transform_matrix(global_transform.affine_inverse())

func _paint(texture: Texture2D, at: Vector2, width: float, tint: Color) -> void:
	var size := texture.get_size() * (width / texture.get_width())
	draw_texture_rect(texture, Rect2(at - size * 0.5, size), false, tint)
