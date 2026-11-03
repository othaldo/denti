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
	if encounter.state == AcidKingEncounter.State.WARN_SPIT:
		var progress := 1 - encounter.remaining / profile.spit_warning_seconds
		var tint := Color(0.65, 0.95, 0.20, 0.9)
		for ray in encounter.spit_rays:
			WarningEffects.aim(encounter, encounter.spit_origin, encounter.spit_origin + ray * profile.spit.speed * profile.spit.lifetime, tint, progress, base)
		WarningEffects.timer(encounter, encounter.spit_origin, encounter.enemy.data.radius + 12, progress, tint, base)
	for field: Dictionary in encounter.fields:
		var ends := channel_ends(field)
		var width: float = minf(field.half_size.x, field.half_size.y) * 2
		var alpha := clampf(field.life / profile.old_channel_fade, 0.45, 1)
		WarningEffects.capsule(encounter, ends[0], ends[1], width * 0.5, Color(0.65, 0.92, 0.14, 0.65 * alpha), fposmod(encounter.elapsed * 0.5, 1), base, WarningEffects.BATCH.Phase.ACTIVE)
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
			WarningEffects.capsule(encounter, ends[0], ends[1], profile.channel_half_width, Color(0.65, 0.92, 0.14, 0.85), progress, base)
	for row: Dictionary in encounter.rows:
		var circle: float = row.get("circle_radius", 0)
		var tangent: Vector2 = row.direction.orthogonal() * encounter.row_half_span(row)
		if encounter.state == AcidKingEncounter.State.WARN_STOMP or not row.fired:
			var progress := 1 - encounter.remaining / encounter.stomp_warning_duration() if encounter.state == AcidKingEncounter.State.WARN_STOMP else 1.0
			if circle > 0: WarningEffects.circle(encounter, row.at, circle, progress, Color(1, 0.44, 0.25, 0.85), base)
			else: WarningEffects.capsule(encounter, row.at - tangent, row.at + tangent, profile.stomp_radius, Color(1, 0.44, 0.25, 0.85), progress, base)
		elif row.delay >= -profile.stomp_active_seconds - 0.22:
			var alpha := clampf(1 + row.delay / (profile.stomp_active_seconds + 0.22), 0, 1)
			if circle > 0: WarningEffects.circle(encounter, row.at, circle, 1, Color(1, 0.55, 0.25, alpha), base, WarningEffects.BATCH.Phase.ACTIVE)
			for index in 7:
				var at: Vector2 = row.at + (Vector2.from_angle(index * TAU / 7) * circle * 0.8 if circle > 0 else tangent * (float(index) / 3 - 1))
				_art(encounter, 7, at, 48, Color(1, 1, 1, alpha), base)
	encounter.draw_set_transform_matrix(Transform2D.IDENTITY)
