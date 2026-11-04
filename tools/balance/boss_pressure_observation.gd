extends "res://tools/balance/bots/pilot_observation.gd"
## Additional currently painted threats omitted by the older whole-run bot sensor.

func capture(game, frame: int) -> Dictionary:
	var world := super.capture(game, frame)
	var area := Rect2(Vector2(world.position) - VIEW_HALF, VIEW_HALF * 2)
	var hazards: Array[Dictionary] = []
	var shots: Array[Dictionary] = []
	var contact_positions: Dictionary = {}
	for enemy: Enemy in game.get_node("Enemies").get_children():
		if enemy.health <= 0 or enemy.is_queued_for_deletion(): continue
		if enemy.contact_damage > 0: contact_positions[enemy.global_position] = true
		if enemy.caramel_enforcer != null:
			var a := enemy.caramel_enforcer
			if a.state == CaramelEnforcer.State.CHARGE_WARN:
				hazards.append(BOSS_OBSERVATION._capsule(a.origin, a.destination, a.profile.charge_radius, a.remaining, a.profile.charge_seconds))
			if a.state in [CaramelEnforcer.State.PUNCH_WARN, CaramelEnforcer.State.PUNCH]:
				hazards.append(_circle(a.destination, a.profile.punch_radius, a.remaining if a.state == CaramelEnforcer.State.PUNCH_WARN else 0.0, a.profile.punch_seconds))
		if enemy.acid_collector != null:
			var a := enemy.acid_collector
			for pool in a.pools: hazards.append(_circle(pool.at, a.profile.impact_radius, 0, pool.life))
			if a.state in [AcidCollector.State.WARNING, AcidCollector.State.FLIGHT]:
				hazards.append(_circle(a.destination, a.profile.impact_radius, a.remaining + (a.profile.flight_seconds if a.state == AcidCollector.State.WARNING else 0.0), a.profile.pool_seconds))
		if enemy.imperial_vassal != null:
			var a := enemy.imperial_vassal
			BOSS_OBSERVATION._batch(a.shots, shots)
			if a.state in [ImperialVassal.State.WARNING, ImperialVassal.State.ACTIVE]:
				var delay := a.remaining if a.state == ImperialVassal.State.WARNING else 0.0
				if a.profile.role == ImperialVassalData.Role.LANCER:
					hazards.append(BOSS_OBSERVATION._capsule(a.origin, a.destination, a.profile.lane_radius, delay, a.profile.active_seconds))
				elif a.profile.role == ImperialVassalData.Role.JUSTICIAR:
					var impact := delay + a.profile.active_seconds * 0.85 if a.state == ImperialVassal.State.WARNING else maxf(a.remaining - a.profile.active_seconds * 0.15, 0)
					hazards.append(_circle(a.destination, a.profile.slam_radius, impact, a.profile.active_seconds * 0.15))
				elif a.state == ImperialVassal.State.WARNING:
					var p := a.profile.projectile_profile
					BOSS_OBSERVATION._rays(a.origin, EnemyProjectilePatterns.fan_directions(a.aim, 3 + maxi(enemy.difficulty.boss_volley_bonus, 0), 0.2), p.speed, p.radius, p.lifetime, delay, shots)
		if enemy.acid_king_encounter != null:
			var c := enemy.acid_king_encounter
			var trial := c.pressure
			if trial.state in [KingPressureTrial.State.LOCKED, KingPressureTrial.State.FIRING]:
				hazards.append(BOSS_OBSERVATION._capsule(trial.origin + trial.aim * 30, trial.destination, trial.profile.beam_half_width, trial.remaining if trial.state == KingPressureTrial.State.LOCKED else 0.0, trial.profile.firing_seconds))
			if trial.state == KingPressureTrial.State.BLAST_WARNING:
				BOSS_OBSERVATION._rays(trial.anchor, EnemyProjectilePatterns.circle_directions(8 + trial.remaining_valves() * 4, 0), c.profile.spit.speed, c.profile.spit.radius, c.profile.spit.lifetime, trial.remaining, shots, enemy.data.radius)
			for stream in c.acid_wake.streams:
				hazards.append(BOSS_OBSERVATION._capsule(stream.from, stream.to, c.pressure.profile.beam_half_width, maxf(c.pressure.profile.acid_arm_seconds - stream.age, 0), stream.life))
		if enemy.caramel_encounter != null:
			var c := enemy.caramel_encounter
			var ritual := c.overload
			if ritual.state == CaramelOverload.State.ACTIVE and ritual.lane_state > 0:
				hazards.append(BOSS_OBSERVATION._capsule(ritual.lane_start(), ritual.lane_end(), ritual.profile.lane_half_width, ritual.lane_remaining if ritual.lane_state == 1 else 0.0, ritual.profile.lane_active_seconds))
			if ritual.state == CaramelOverload.State.BLAST:
				BOSS_OBSERVATION._rays(ritual.anchor, EnemyProjectilePatterns.circle_directions(4 + ritual.missed * 4, 0), c.profile.heart_speed, c.profile.heart_radius, c.profile.heart_lifetime, ritual.remaining, shots, enemy.data.radius)
			for entry in c.overload.pressure.entries:
				if entry.warning:
					BOSS_OBSERVATION._rays(entry.at, c.overload.pressure.directions(entry.aim), c.profile.heart_speed, c.profile.heart_radius, c.profile.heart_lifetime, entry.remaining, shots, 28)
		if enemy.crown_court_encounter != null:
			var r := enemy.crown_court_encounter.retinue
			BOSS_OBSERVATION._batch(r.shots, shots)
			if r.pulse_warned:
				var p := r.encounter.profile.shots
				BOSS_OBSERVATION._rays(r.anchor, EnemyProjectilePatterns.fan_directions(r.pulse_aim, 5, 0.22), p.speed, p.radius, p.lifetime, r.pulse_remaining, shots)
			if r.state == ImperialRetinue.State.FAILURE:
				var p := r.encounter.profile.shots
				BOSS_OBSERVATION._rays(r.anchor, EnemyProjectilePatterns.circle_directions(8 + r.live_minions().size() * 4, 0), p.speed, p.radius, p.lifetime, r.remaining, shots, enemy.data.radius)
	# Brösel, Schlacko and objectives have no contact damage. Their actual attacks
	# are captured above; a fictitious body threat would inflate the pressure score.
	world.enemies = world.enemies.filter(func(entry: Dictionary) -> bool: return contact_positions.has(entry.position))
	for hazard in hazards:
		var bounds := Rect2(Vector2(hazard.position), Vector2.ZERO).expand(hazard.get("end", hazard.position)).grow(float(hazard.radius))
		if area.intersects(bounds): world.hazards.append(hazard)
	for shot in shots:
		var bounds := Rect2(Vector2(shot.position), Vector2.ZERO)
		if float(shot.get("delay", 0)) > 0: bounds = bounds.expand(shot.position + shot.velocity * float(shot.life))
		bounds = bounds.grow(float(shot.radius))
		if area.intersects(bounds): world.projectiles.append(shot)
	return world

static func _circle(at: Vector2, radius: float, time: float, duration: float) -> Dictionary:
	return {"shape": "circle", "position": at, "radius": radius, "time": time, "duration": duration}
