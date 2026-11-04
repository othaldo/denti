class_name CaramelEscapePilot
extends RefCounted
## Diagnostic pilot: observes locked bomb, fist and projectile warnings.

static func goal(boss: Enemy, minion: Enemy, variant: int = 0) -> Vector2:
	var court := boss.caramel_encounter
	var player := boss.target
	var speed := PlayerStats.BASE_MOVE_SPEED * court.profile.movement_factor
	var hazards: Array[Vector4] = []
	if court.state == CaramelEncounter.State.BOMB_SEQUENCE:
		for bomb in court.bombs.entries: hazards.append(Vector4(bomb.at.x, bomb.at.y, court.profile.windup_seconds + court.profile.flight_seconds - bomb.age, court.profile.impact_radius))
	elif court.state in [CaramelEncounter.State.WINDUP, CaramelEncounter.State.FLIGHT]:
		hazards.append(Vector4(court.destination.x, court.destination.y, court.remaining + (court.profile.flight_seconds if court.state == CaramelEncounter.State.WINDUP else 0), court.profile.impact_radius))
	var ai := minion.caramel_enforcer
	if ai.state in [CaramelEnforcer.State.PUNCH_WARN, CaramelEnforcer.State.PUNCH]:
		hazards.append(Vector4(ai.destination.x, ai.destination.y, ai.remaining if ai.state == CaramelEnforcer.State.PUNCH_WARN else 0.01, ai.profile.punch_radius))
	var at := player.global_position
	var best := at
	var cost := INF
	for index in 32:
		var direction := Vector2.from_angle((index + variant) * TAU / 32)
		var candidate := (at + direction * speed * 1.15).clamp(Vector2.ONE * 48, player.arena.arena_size - Vector2.ONE * 48)
		var next := at.move_toward(candidate, speed * 0.12)
		if Geometry2D.get_closest_point_to_segment(boss.global_position, at, next).distance_to(boss.global_position) <= boss.data.radius + 21: continue
		var score := 0.0
		for hazard in hazards:
			var predicted := at.move_toward(candidate, speed * maxf(hazard.z, 0))
			var shortfall := maxf(hazard.w + HazardGeometry.PLAYER_RADIUS + 6 - predicted.distance_to(Vector2(hazard.x, hazard.y)), 0)
			score += shortfall * shortfall / maxf(hazard.z, 0.05)
		if ai.state in [CaramelEnforcer.State.CHARGE_WARN, CaramelEnforcer.State.CHARGE]:
			var time := ai.remaining if ai.state == CaramelEnforcer.State.CHARGE_WARN else 0.01
			var predicted := at.move_toward(candidate, speed * time)
			var distance := Geometry2D.get_closest_point_to_segment(predicted, ai.origin, ai.destination).distance_to(predicted)
			score += pow(maxf(ai.profile.charge_radius + HazardGeometry.PLAYER_RADIUS + 6 - distance, 0), 2) / maxf(time, 0.05)
		for heart in court.hearts.entries:
			for time in [0.12, 0.3, 0.6, 1.0]:
				if time > heart.life: continue
				var future: Vector2 = heart.at + heart.velocity * time
				var distance := at.move_toward(candidate, speed * time).distance_to(future)
				score += pow(maxf(court.profile.heart_radius + HazardGeometry.PLAYER_RADIUS + 6 - distance, 0), 2) / time
		if not player.velocity.is_zero_approx(): score += pow(direction.angle_to(player.velocity), 2) * 0.05
		if score < cost: cost = score; best = candidate
	return best
