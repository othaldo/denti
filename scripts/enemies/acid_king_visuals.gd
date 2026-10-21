class_name AcidKingVisuals
extends RefCounted

const STREAM_CONTENT := Rect2(0, 135, 2172, 459)
static var contours: Dictionary[Vector2, PackedVector2Array] = {}

static func channel_ends(field: Dictionary) -> Array[Vector2]:
	var along := Vector2(0, field.half_size.y) if field.half_size.x < field.half_size.y else Vector2(field.half_size.x, 0)
	return [field.at - along, field.at + along]

static func _contour(length: float, radius: float) -> PackedVector2Array:
	var key := Vector2(length, radius)
	if not contours.has(key):
		if contours.size() > 256: contours.clear()
		var points := PackedVector2Array()
		for index in 13: points.append(Vector2(length, 0) + Vector2.from_angle(-PI * 0.5 + PI * index / 12) * radius)
		for index in 13: points.append(Vector2.from_angle(PI * 0.5 + PI * index / 12) * radius)
		contours[key] = points
	return contours[key]

static func _art(canvas: CanvasItem, index: int, at: Vector2, extent: float, tint: Color, base: Transform2D, rotation: float = 0.0) -> void:
	var texture := KingAcidArt.texture(index)
	var size := texture.get_size() * extent / maxf(texture.get_width(), texture.get_height())
	canvas.draw_set_transform_matrix(base * Transform2D(rotation, at))
	canvas.draw_texture_rect(texture, Rect2(-size * 0.5, size), false, tint)

static func draw(encounter: AcidKingEncounter) -> void:
	var base := encounter.global_transform.affine_inverse()
	var profile := encounter.profile
	for field: Dictionary in encounter.fields:
		var ends := channel_ends(field)
		var width: float = minf(field.half_size.x, field.half_size.y) * 2
		var alpha := clampf(field.life / profile.old_channel_fade, 0.45, 1)
		AttackEffects.strip(encounter, AttackEffects.Shape.TRAIL, ends[0], ends[1], width, Color(0.72, 0.92, 0.12, 0.6 * alpha), encounter.elapsed, base)
		var length := ends[0].distance_to(ends[1])
		var direction := ends[0].direction_to(ends[1])
		var tile_length := width * STREAM_CONTENT.size.x / STREAM_CONTENT.size.y
		var travel := encounter.elapsed * 45 / tile_length * (-1 if encounter.state == AcidKingEncounter.State.RECALL else 1)
		var points := _contour(length, width * 0.5)
		var uvs := PackedVector2Array()
		for point in points:
			uvs.append(Vector2(point.x / tile_length + travel, (STREAM_CONTENT.position.y + (point.y / width + 0.5) * STREAM_CONTENT.size.y) / KingAcidArt.STREAM.get_height()))
		encounter.draw_set_transform_matrix(base * Transform2D(direction.angle(), ends[0]))
		encounter.draw_polygon(points, PackedColorArray([Color(1, 1, 1, 0.9 * alpha)]), uvs, KingAcidArt.STREAM)
	if encounter.state in [AcidKingEncounter.State.WARN_CHANNEL, AcidKingEncounter.State.WARN_SHIFT]:
		var duration := profile.warning_seconds if encounter.state == AcidKingEncounter.State.WARN_CHANNEL else profile.shift_warning_seconds
		var progress := 1 - encounter.remaining / duration
		for field in encounter.pending:
			var ends := channel_ends(field)
			WarningEffects.charge(encounter, Vector2.ZERO, ends[1] - ends[0], profile.channel_half_width, ends[0].distance_to(ends[1]), Color(1, 0.32, 0.18, 0.8), progress, base * Transform2D(0, ends[0]))
			encounter.draw_set_transform_matrix(base)
			for end in ends: AttackEffects.flash(encounter, end, profile.channel_half_width, Color(1, 0.32, 0.18, 0.35), progress)
	for row: Dictionary in encounter.rows:
		var tangent: Vector2 = row.direction.orthogonal() * profile.stomp_half_span
		if encounter.state == AcidKingEncounter.State.WARN_STOMP or not row.fired:
			var progress := 1 - encounter.remaining / profile.stomp_warning_seconds if encounter.state == AcidKingEncounter.State.WARN_STOMP else 1.0
			WarningEffects.charge(encounter, Vector2.ZERO, tangent * 2, profile.stomp_radius, tangent.length() * 2, Color(1, 0.44, 0.25, 0.75), progress, base * Transform2D(0, row.at - tangent))
		elif row.delay >= -profile.stomp_active_seconds - 0.22:
			var alpha := clampf(1 + row.delay / (profile.stomp_active_seconds + 0.22), 0, 1)
			for index in 7:
				_art(encounter, 7, row.at + tangent * (float(index) / 3 - 1), 48, Color(1, 1, 1, alpha), base)
	encounter.draw_set_transform_matrix(Transform2D.IDENTITY)
