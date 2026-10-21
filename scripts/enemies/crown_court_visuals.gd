class_name CrownCourtVisuals
extends RefCounted

static var sector_uvs: Dictionary[float, PackedVector2Array] = {}

static func prepare(degrees: float) -> void:
	if sector_uvs.has(degrees): return
	var uvs := PackedVector2Array()
	var lateral := sin(deg_to_rad(degrees * 0.5))
	for point in AttackEffects.cone_points(degrees):
		uvs.append((WarningEffects.CHARGE_BODY.position + Vector2(point.x * 63 + 0.5, (point.y / lateral * 0.5 + 0.5) * 63 + 0.5)) / WarningEffects.ATLAS.get_size())
	sector_uvs[degrees] = uvs

static func _sector(canvas: CanvasItem, at: Vector2, direction: Vector2, radius: float, degrees: float, tint: Color, base: Transform2D) -> void:
	prepare(degrees)
	canvas.draw_set_transform_matrix(base * Transform2D(direction.angle(), Vector2.ONE * radius, 0, at))
	canvas.draw_polygon(AttackEffects.cone_points(degrees), PackedColorArray([tint]), sector_uvs[degrees], WarningEffects.ATLAS)
	canvas.draw_set_transform_matrix(base)

static func _piece(canvas: CanvasItem, index: int, at: Vector2, extent: float, base: Transform2D, angle: float = 0, alpha: float = 1) -> void:
	var texture := EmperorCourtArt.texture(index)
	var size := texture.get_size() * extent / maxf(texture.get_width(), texture.get_height())
	canvas.draw_set_transform_matrix(base * Transform2D(angle, at))
	canvas.draw_texture_rect(texture, Rect2(-size * 0.5, size), false, Color(1, 1, 1, alpha))

static func draw(encounter: CrownCourtEncounter) -> void:
	var base := encounter.global_transform.affine_inverse()
	var data := encounter.profile
	var state := encounter.state
	if state in [CrownCourtEncounter.State.EDICT_WARN, CrownCourtEncounter.State.EDICT_HIT] or encounter.combo:
		var active := state in [CrownCourtEncounter.State.EDICT_HIT, CrownCourtEncounter.State.NERVE_RELEASE]
		var duration := data.nerve_warning_seconds if encounter.combo else data.warning_seconds
		var progress := 1.0 if active else 1 - encounter.remaining / duration
		for side in [0, 1]:
			var direction := Vector2.from_angle(encounter.edict_angle + side * PI)
			var tint := Color(1, 0.36, 0.27, 0.65 if not active else 0.95)
			_sector(encounter, encounter.origin, direction, data.court_radius, data.court_half_angle * 2, Color(tint, 0.3), base)
			_sector(encounter, encounter.origin, direction, data.court_radius * lerpf(0.25, 1, progress), data.court_half_angle * 2, tint, base)
			_piece(encounter, 8, encounter.origin + direction * data.court_radius * 0.65, 50, base, 0, 0.5 + progress * 0.5)
	if state in [CrownCourtEncounter.State.PORTAL_WARN, CrownCourtEncounter.State.PORTAL_FLIGHT]:
		var progress := 1 - encounter.remaining / data.portal_warning_seconds if state == CrownCourtEncounter.State.PORTAL_WARN else 1.0
		for at in [encounter.portal_a, encounter.portal_b]:
			_piece(encounter, 6, at, lerpf(62, 90, smoothstep(0, 1, progress)), base, sin(encounter.elapsed * 2) * 0.08)
		if state == CrownCourtEncounter.State.PORTAL_WARN:
			WarningEffects.charge(encounter, Vector2.ZERO, encounter.portal_b - encounter.portal_a, data.lance.radius, encounter.portal_a.distance_to(encounter.portal_b), Color(1, 0.4, 0.6, 0.85), progress, base * Transform2D(0, encounter.portal_a))
	if state == CrownCourtEncounter.State.NERVE_WARN:
		var progress := 1 - encounter.remaining / data.nerve_warning_seconds
		for ray in EnemyProjectilePatterns.circle_directions(data.rays(encounter.enemy.boss_phase), encounter.pulse_angle()):
			encounter.draw_set_transform_matrix(base)
			AttackEffects.aim(encounter, encounter.origin + ray * 115, encounter.origin + ray * 285, Color(1, 0.42, 0.62, 0.45 + 0.4 * progress), progress, base)
	if state == CrownCourtEncounter.State.TURN:
		var progress := 1 - encounter.remaining / data.turn_seconds
		var end := encounter.enemy.global_position + Vector2.from_angle(encounter.turn_to) * 155
		_piece(encounter, 4, end, 38, base, encounter.turn_to - PI * 0.5, 0.35 + progress * 0.4)
	encounter.draw_set_transform_matrix(Transform2D.IDENTITY)
