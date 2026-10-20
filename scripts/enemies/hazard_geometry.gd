class_name HazardGeometry
extends RefCounted

const PLAYER_RADIUS := 20.0

static func circle_sector(point: Vector2, center: Vector2, direction: Vector2, radius: float, half_angle: float) -> bool:
	var relative := point - center
	if relative.length() <= PLAYER_RADIUS:
		return true
	if absf(direction.angle_to(relative)) <= half_angle and relative.length() <= radius + PLAYER_RADIUS:
		return true
	for sign_side in [-1, 1]:
		var end := center + direction.rotated(half_angle * sign_side) * radius
		if point.distance_to(Geometry2D.get_closest_point_to_segment(point, center, end)) <= PLAYER_RADIUS:
			return true
	return false

static func swept_sector(player: Player, center: Vector2, direction: Vector2, radius: float, half_angle: float, first: float, last: float) -> bool:
	var start := player_at(player, first)
	var end := player_at(player, last)
	if circle_sector(start, center, direction, radius, half_angle) or circle_sector(end, center, direction, radius, half_angle):
		return true
	# A moving player circle intersects either a radial edge capsule or the outer arc.
	for sign_side in [-1, 1]:
		var ray_end := center + direction.rotated(half_angle * sign_side) * radius
		if Geometry2D.segment_intersects_segment(start, end, center, ray_end) != null:
			return true
		for point in [start, end]:
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point, center, ray_end)) <= PLAYER_RADIUS:
				return true
		for point in [center, ray_end]:
			if point.distance_to(Geometry2D.get_closest_point_to_segment(point, start, end)) <= PLAYER_RADIUS:
				return true
	var entry := DashCollision.circle_fraction(start, end - start, center, radius + PLAYER_RADIUS)
	return entry != INF and absf(direction.angle_to(start.lerp(end, entry) - center)) <= half_angle

static func circle_ring(point: Vector2, center: Vector2, inner: float, outer: float) -> bool:
	var distance := point.distance_to(center)
	return distance >= maxf(inner - PLAYER_RADIUS, 0) and distance <= outer + PLAYER_RADIUS

static func swept_ring(player: Player, center: Vector2, inner: float, outer: float, first: float, last: float) -> bool:
	var start := player_at(player, first)
	var end := player_at(player, last)
	# Distance along a segment is continuous: it crosses the annulus iff its
	# minimum is within the outer circle and its maximum reaches the inner rim.
	var nearest := Geometry2D.get_closest_point_to_segment(center, start, end).distance_to(center)
	var farthest := maxf(start.distance_to(center), end.distance_to(center))
	return nearest <= outer + PLAYER_RADIUS and farthest >= maxf(inner - PLAYER_RADIUS, 0)

static func player_at(player: Player, seconds: float) -> Vector2:
	if player.swept_dash_this_frame():
		return player.motion_start.lerp(player.motion_end, clampf(seconds / maxf(player.dash_motion_seconds, 0.000001), 0, 1))
	return player.global_position

static func circle_box(point: Vector2, box: Rect2) -> bool:
	return point.distance_squared_to(point.clamp(box.position, box.end)) <= PLAYER_RADIUS * PLAYER_RADIUS

static func _segment_box(start: Vector2, end: Vector2, box: Rect2) -> bool:
	var travel := end - start
	var enter := 0.0
	var leave := 1.0
	for axis in 2:
		if absf(travel[axis]) < 0.000001:
			if start[axis] < box.position[axis] or start[axis] > box.end[axis]: return false
		else:
			var a: float = (box.position[axis] - start[axis]) / travel[axis]
			var b: float = (box.end[axis] - start[axis]) / travel[axis]
			enter = maxf(enter, minf(a, b))
			leave = minf(leave, maxf(a, b))
	return enter <= leave

static func moving_box(player: Player, from: Vector2, to: Vector2, half_size: Vector2, first: float, last: float) -> bool:
	# Relative sweep against the rounded rectangle (faces plus four corners).
	# Split at dash end so a long frame cannot hide an impact after movement stops.
	var times: Array[float] = [first, last]
	if player.swept_dash_this_frame() and player.dash_motion_seconds > first and player.dash_motion_seconds < last:
		times.insert(1, player.dash_motion_seconds)
	for index in times.size() - 1:
		var a := times[index]
		var b := times[index + 1]
		var fraction_a := (a - first) / maxf(last - first, 0.000001)
		var fraction_b := (b - first) / maxf(last - first, 0.000001)
		var start := player_at(player, a) - from.lerp(to, fraction_a)
		var end := player_at(player, b) - from.lerp(to, fraction_b)
		if _segment_box(start, end, Rect2(-half_size - Vector2(PLAYER_RADIUS, 0), half_size * 2 + Vector2(PLAYER_RADIUS * 2, 0))): return true
		if _segment_box(start, end, Rect2(-half_size - Vector2(0, PLAYER_RADIUS), half_size * 2 + Vector2(0, PLAYER_RADIUS * 2))): return true
		for x in [-1, 1]:
			for y in [-1, 1]:
				if DashCollision.circle_fraction(start, end - start, half_size * Vector2(x, y), PLAYER_RADIUS) != INF: return true
	return false
