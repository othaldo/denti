class_name HazardGeometry
extends RefCounted

const PLAYER_RADIUS := 20.0

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
