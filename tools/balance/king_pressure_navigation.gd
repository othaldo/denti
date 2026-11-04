extends RefCounted
## Diagnostic movement only: route around fixed acid strips without dashing.

var route: Array[Vector2] = []
var last_goal := Vector2.INF
var last_stamp := -1

func next(from: Vector2, goal: Vector2, trial: KingPressureTrial) -> Vector2:
	var stamp := trial.shots * 16 + trial.encounter.acid_wake.streams.size()
	if trial.encounter.companion != null and not trial.encounter.companion.live_minions().is_empty():
		var actor := trial.encounter.companion.minion
		stamp = hash([stamp, actor.get_instance_id(), actor.acid_collector.state, actor.acid_collector.destination, actor.acid_collector.pools.size()])
	if last_goal.distance_to(goal) > 1 or last_stamp != stamp:
		route = _plan(from, goal, trial)
		last_goal = goal
		last_stamp = stamp
	while not route.is_empty() and from.distance_to(route[0]) < 7: route.pop_front()
	return route[0] if not route.is_empty() else goal

func acid_circles(trial: KingPressureTrial) -> Array[Vector3]:
	var result: Array[Vector3] = []
	var companion := trial.encounter.companion
	if companion == null or companion.live_minions().is_empty(): return result
	var collector := companion.minion.acid_collector
	var radius := collector.profile.impact_radius + HazardGeometry.PLAYER_RADIUS + 5
	for pool in collector.pools: result.append(Vector3(pool.at.x, pool.at.y, radius))
	if collector.state in [AcidCollector.State.WARNING, AcidCollector.State.FLIGHT]:
		result.append(Vector3(collector.destination.x, collector.destination.y, radius))
	return result

func safe_target(target: Vector2, along: Vector2, from: Vector2, trial: KingPressureTrial) -> Vector2:
	var circles := acid_circles(trial)
	if circles.is_empty(): return target
	var blocked := false
	for circle in circles:
		if target.distance_to(Vector2(circle.x, circle.y)) <= circle.z: blocked = true
	if not blocked: return target
	var best := target
	var cost := INF
	var arena := Rect2(Vector2.ONE * 48, trial.encounter.enemy.target.arena.arena_size - Vector2.ONE * 96)
	for offset in [-110.0, 110.0, -160.0, 160.0]:
		var candidate: Vector2 = target + along * offset
		if not arena.has_point(candidate) or candidate.distance_to(trial.anchor) <= trial.encounter.enemy.data.radius + HazardGeometry.PLAYER_RADIUS + 5: continue
		var safe := true
		for circle in circles:
			if candidate.distance_to(Vector2(circle.x, circle.y)) <= circle.z: safe = false
		if safe and candidate.distance_to(from) < cost: cost = candidate.distance_to(from); best = candidate
	return best

func _clear(a: Vector2, b: Vector2, trial: KingPressureTrial) -> bool:
	if Geometry2D.get_closest_point_to_segment(trial.anchor, a, b).distance_to(trial.anchor) <= trial.encounter.enemy.data.radius + HazardGeometry.PLAYER_RADIUS + 2: return false
	var margin := trial.profile.beam_half_width + HazardGeometry.PLAYER_RADIUS + 3
	for stream in trial.encounter.acid_wake.streams:
		var c: Vector2 = stream.from
		var d: Vector2 = stream.to
		if Geometry2D.segment_intersects_segment(a, b, c, d) != null: return false
		if minf(a.distance_to(Geometry2D.get_closest_point_to_segment(a, c, d)), b.distance_to(Geometry2D.get_closest_point_to_segment(b, c, d))) <= margin: return false
		if minf(c.distance_to(Geometry2D.get_closest_point_to_segment(c, a, b)), d.distance_to(Geometry2D.get_closest_point_to_segment(d, a, b))) <= margin: return false
	for circle in acid_circles(trial):
		var center := Vector2(circle.x, circle.y)
		# A newly warned circle may start under Denti: allow moving out of it.
		if a.distance_to(center) <= circle.z:
			if b.distance_to(center) <= a.distance_to(center): return false
		elif center.distance_to(Geometry2D.get_closest_point_to_segment(center, a, b)) <= circle.z: return false
	return true

func _plan(from: Vector2, goal: Vector2, trial: KingPressureTrial) -> Array[Vector2]:
	if _clear(from, goal, trial): return [goal]
	var points: Array[Vector2] = [from, goal]
	var radius := trial.encounter.enemy.data.radius + HazardGeometry.PLAYER_RADIUS + 24
	for index in 32: points.append(trial.anchor + Vector2.from_angle(index * TAU / 32) * radius)
	var costs: Array[float] = []
	var previous: Array[int] = []
	var used: Array[bool] = []
	costs.resize(points.size()); costs.fill(INF); costs[0] = 0
	previous.resize(points.size()); previous.fill(-1)
	used.resize(points.size()); used.fill(false)
	for iteration in points.size():
		var here := -1
		for index in points.size():
			if not used[index] and (here < 0 or costs[index] < costs[here]): here = index
		if here < 0 or is_inf(costs[here]): break
		if here == 1: break
		used[here] = true
		for index in range(1, points.size()):
			if used[index] or not _clear(points[here], points[index], trial): continue
			var distance := costs[here] + points[here].distance_to(points[index])
			if distance < costs[index]: costs[index] = distance; previous[index] = here
	var result: Array[Vector2] = []
	if previous[1] < 0: return result
	var cursor := 1
	while cursor > 0:
		result.push_front(points[cursor])
		cursor = previous[cursor]
	return result
