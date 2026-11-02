extends RefCounted
## Adapters for geometry already painted by the three later bosses. No next
## attack selection, hidden aim or unreleased follow-up is exposed.

static func capture(enemy: Enemy, area: Rect2, hazards: Array[Dictionary], projectiles: Array[Dictionary]) -> void:
	var shapes: Array[Dictionary] = []
	var shots: Array[Dictionary] = []
	if enemy.caramel_encounter != null: _prince(enemy.caramel_encounter, shapes, shots)
	if enemy.acid_king_encounter != null: _king(enemy.acid_king_encounter, shapes, shots)
	if enemy.crown_court_encounter != null: _emperor(enemy.crown_court_encounter, shapes, shots)
	for shape in shapes:
		var at: Vector2 = shape.position
		var bounds := Rect2(at, Vector2.ZERO).expand(shape.get("end", at)).grow(float(shape.radius))
		if area.intersects(bounds): hazards.append(shape)
	for shot in shots:
		# Pending shots are visible only along an explicitly drawn warning ray.
		var bounds := Rect2(shot.position, Vector2.ZERO)
		if float(shot.get("delay", 0)) > 0: bounds = bounds.expand(shot.position + shot.velocity * float(shot.life))
		if area.intersects(bounds.grow(float(shot.radius))): projectiles.append(shot)

static func _batch(batch: BossPaintedVolley, shots: Array[Dictionary]) -> void:
	if batch == null: return
	_entries(batch.entries, batch.profile.radius, shots)

static func _entries(entries: Array[Dictionary], radius: float, shots: Array[Dictionary]) -> void:
	for entry in entries:
		if entry.life > 0: shots.append({"position": entry.at, "velocity": entry.velocity, "radius": radius + HazardGeometry.PLAYER_RADIUS, "life": entry.life})

static func _rays(at: Vector2, rays: Array[Vector2], speed: float, radius: float, life: float, delay: float, shots: Array[Dictionary], offset: float = 0) -> void:
	for ray in rays: shots.append({"position": at + ray * offset, "velocity": ray * speed, "radius": radius + HazardGeometry.PLAYER_RADIUS, "life": life, "delay": delay})

static func _capsule(a: Vector2, b: Vector2, radius: float, time: float, duration: float) -> Dictionary:
	return {"shape": "capsule", "position": a, "end": b, "radius": radius, "time": time, "duration": duration}

static func _prince(c: CaramelEncounter, shapes: Array[Dictionary], shots: Array[Dictionary]) -> void:
	var p := c.profile
	_entries(c.hearts.entries, p.heart_radius, shots)
	if c.state in [CaramelEncounter.State.WINDUP, CaramelEncounter.State.FLIGHT]:
		shapes.append({"shape": "circle", "position": c.destination, "radius": p.impact_radius,
			"time": c.remaining + (p.flight_seconds if c.state == CaramelEncounter.State.WINDUP else 0), "duration": 0.02})
	if c.state == CaramelEncounter.State.BOMB_SEQUENCE:
		for entry in c.bombs.entries:
			shapes.append({"shape": "circle", "position": entry.at, "radius": p.impact_radius,
				"time": maxf(p.windup_seconds + p.flight_seconds - float(entry.age), 0), "duration": 0.02})
	if c.state == CaramelEncounter.State.RUSH_WINDUP:
		shapes.append(_capsule(c.rush_origin, c.rush_end, c.enemy.data.radius, c.remaining, p.rush_seconds))
	if c.state in [CaramelEncounter.State.HEART_WINDUP, CaramelEncounter.State.BURST_WINDUP]:
		_rays(c.enemy.global_position, c.rays, p.heart_speed, p.heart_radius, p.heart_lifetime, c.remaining, shots, c.enemy.data.radius + 12)

static func _king(c: AcidKingEncounter, shapes: Array[Dictionary], shots: Array[Dictionary]) -> void:
	var p := c.profile
	_batch(c.volley, shots)
	_batch(c.spit, shots)
	for field in c.fields:
		var ends := AcidKingVisuals.channel_ends(field)
		shapes.append(_capsule(ends[0], ends[1], p.channel_half_width, 0, field.life))
	if c.state in [AcidKingEncounter.State.WARN_CHANNEL, AcidKingEncounter.State.WARN_SHIFT]:
		for field in c.pending:
			var ends := AcidKingVisuals.channel_ends(field)
			shapes.append(_capsule(ends[0], ends[1], p.channel_half_width, c.remaining, 0.5))
	for row in c.rows:
		var time: float = float(row.delay) + (c.remaining if c.state == AcidKingEncounter.State.WARN_STOMP else 0.0)
		if time + p.stomp_active_seconds <= 0 or row.hit: continue
		var tangent: Vector2 = row.direction.orthogonal() * p.stomp_half_span
		shapes.append(_capsule(row.at - tangent, row.at + tangent, p.stomp_radius, time, p.stomp_active_seconds))
	if c.state == AcidKingEncounter.State.WARN_SPIT:
		_rays(c.spit_origin, c.spit_rays, p.spit.speed, p.spit.radius, p.spit.lifetime, c.remaining, shots)

static func _emperor(c: CrownCourtEncounter, shapes: Array[Dictionary], shots: Array[Dictionary]) -> void:
	var p := c.profile
	for batch in [c.shots, c.lances, c.needles]: _batch(batch, shots)
	if c.state in [CrownCourtEncounter.State.EDICT_WARN, CrownCourtEncounter.State.EDICT_HIT] or c.combo:
		var active := c.state in [CrownCourtEncounter.State.EDICT_HIT, CrownCourtEncounter.State.NERVE_RELEASE]
		for side in [0, 1]:
			var direction := Vector2.from_angle(c.edict_angle + side * PI)
			if not c.verdict_hit:
				shapes.append({"shape": "sector", "position": c.origin, "direction": direction, "radius": p.court_radius,
					"inner": 0.0, "angle": deg_to_rad(p.court_half_angle), "time": 0.0 if active else c.remaining,
					"duration": c.remaining if active else p.impact_seconds})
			if c.state == CrownCourtEncounter.State.EDICT_WARN and not c.legacy_sequence:
				var spacing := deg_to_rad(p.court_half_angle * 2 / maxi(p.fan_count() - 1, 1))
				_rays(c.origin, EnemyProjectilePatterns.fan_directions(direction, p.fan_count(), spacing), p.needles.speed, p.needles.radius, p.needles.lifetime, c.remaining, shots)
	if c.state == CrownCourtEncounter.State.PORTAL_WARN or c.state == CrownCourtEncounter.State.EDICT_WARN and c.portal_combo:
		_rays(c.portal_a, [c.portal_a.direction_to(c.portal_b)], p.lance.speed, p.lance.radius,
			minf(c.portal_a.distance_to(c.portal_b) / p.lance.speed, p.lance.lifetime), c.remaining, shots)
	if c.state == CrownCourtEncounter.State.NERVE_WARN:
		_rays(c.origin, EnemyProjectilePatterns.circle_directions(p.rays(c.enemy.boss_phase), c.pulse_angle()), p.shots.speed, p.shots.radius, p.shots.lifetime, c.remaining, shots)
		_rays(c.origin, c.needle_rays, p.needles.speed, p.needles.radius, p.needles.lifetime, c.remaining, shots)
