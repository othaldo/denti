extends RefCounted
## Simple scripted observer for native studies and repeatable measurements.

static func goal(player: Player, boss: Enemy, attack: CrownCourtEncounter, melee: bool = true) -> Vector2:
	var at := player.global_position
	if attack.state in [CrownCourtEncounter.State.PORTAL_WARN, CrownCourtEncounter.State.PORTAL_FLIGHT]:
		var near := Geometry2D.get_closest_point_to_segment(at, attack.portal_a, attack.portal_b)
		var side := attack.portal_a.direction_to(attack.portal_b).orthogonal()
		var a := near + side * 90
		var b := near - side * 90
		return a if a.distance_to(at) < b.distance_to(at) else b
	if attack.state in [CrownCourtEncounter.State.NERVE_WARN, CrownCourtEncounter.State.NERVE_RELEASE]:
		var spacing := TAU / attack.profile.rays(boss.boss_phase)
		var start := attack.pulse_angle()
		var toward := (at - attack.origin).angle()
		var angle := start + (roundf((toward - start) / spacing - 0.5) + 0.5) * spacing
		var radius := maxf(175, attack.profile.rays(boss.boss_phase) * (HazardGeometry.PLAYER_RADIUS + attack.profile.shots.radius + 5) / PI) if melee else 320.0
		return attack.origin + Vector2.from_angle(angle) * radius
	if attack.state in [CrownCourtEncounter.State.EDICT_WARN, CrownCourtEncounter.State.EDICT_HIT]:
		var goal := at
		var cost := INF
		for index in 49:
			var candidate: Vector2 = at if index == 48 else attack.origin + Vector2.from_angle(index * TAU / 48) * (165 if melee else 300)
			var safe := true
			for side in [0, 1]:
				if HazardGeometry.circle_sector(candidate, attack.origin, Vector2.from_angle(attack.edict_angle + side * PI), attack.profile.court_radius, deg_to_rad(attack.profile.court_half_angle)): safe = false
			if Geometry2D.get_closest_point_to_segment(boss.global_position, at, candidate).distance_to(boss.global_position) < boss.data.radius + 22: safe = false
			var candidate_cost: float = candidate.distance_to(at) + (maxf(candidate.distance_to(boss.global_position) - 180, 0) * 2 if melee else 0)
			if safe and candidate_cost < cost:
				cost = candidate_cost
				goal = candidate
		return goal
	if melee: return boss.global_position + boss.global_position.direction_to(at) * 165
	return at
