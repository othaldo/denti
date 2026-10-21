class_name CaramelEncounterVisuals
extends RefCounted

static func _art(canvas: CanvasItem, index: int, at: Vector2, width: float, tint := Color.WHITE) -> void:
	var texture := PrinceCaramelArt.texture(index)
	var size := texture.get_size() * (width / texture.get_width())
	canvas.draw_texture_rect(texture, Rect2(at - size * 0.5, size), false, tint)

static func draw(encounter: CaramelEncounter) -> void:
	var profile := encounter.profile
	for pool: Dictionary in encounter.pools:
		var opacity := minf(1, pool.life / 0.75) * 0.75
		_art(encounter, 6, pool.at, profile.pool_radius * 2, Color(1, 1, 1, opacity))
	if encounter.state in [CaramelEncounter.State.WINDUP, CaramelEncounter.State.FLIGHT]:
		var total := profile.windup_seconds + profile.flight_seconds
		var progress := 1.0 - (encounter.remaining + (profile.flight_seconds if encounter.state == CaramelEncounter.State.WINDUP else 0.0)) / total
		WarningEffects.charge_impact(encounter, encounter.destination, profile.impact_radius, progress)
		if encounter.state == CaramelEncounter.State.FLIGHT:
			var flight := 1.0 - encounter.remaining / profile.flight_seconds
			var ground := encounter.origin.lerp(encounter.destination, flight)
			AttackEffects.flash(encounter, ground, 13, Color(0.35, 0.12, 0.08, 0.25))
			var airborne := ground - Vector2(0, sin(flight * PI) * profile.arc_height)
			_art(encounter, 5, airborne, 27)
	if encounter.splash_remaining > 0:
		var progress := 1.0 - encounter.splash_remaining / 0.3
		_art(encounter, 7, encounter.splash_at, lerpf(90, profile.impact_radius * 2.1, progress), Color(1, 1, 1, 1 - progress))
	var base := encounter.global_transform.affine_inverse()
	if encounter.state in [CaramelEncounter.State.HEART_WINDUP, CaramelEncounter.State.BURST_WINDUP]:
		var burst := encounter.state == CaramelEncounter.State.BURST_WINDUP
		var duration := profile.burst_warning_seconds if burst else (profile.heart_warning_seconds if encounter.salvo_index == 0 else profile.heart_followup_warning)
		var progress := 1 - encounter.remaining / duration
		var at := encounter.enemy.global_position
		for ray in encounter.rays:
			AttackEffects.aim(encounter, at + ray * (encounter.enemy.data.radius + 12), at + ray * (310 if burst else 420), Color(1, 0.29, 0.16, 0.85), progress, base)
	elif encounter.state == CaramelEncounter.State.RUSH_WINDUP:
		var progress := 1 - encounter.remaining / profile.rush_warning_seconds
		var path := encounter.rush_end - encounter.rush_origin
		var local_base := base * Transform2D(0, encounter.rush_origin)
		WarningEffects.charge(encounter, Vector2.ZERO, path, encounter.enemy.data.radius, path.length(), Color(1, 0.29, 0.16, 0.95), progress, local_base)
	elif encounter.state == CaramelEncounter.State.RUSH_ACTIVE:
		AttackEffects.strip(encounter, AttackEffects.Shape.TRAIL, encounter.rush_origin, encounter.enemy.global_position, 34, Color(1, 0.71, 0.3, 0.65), encounter.elapsed, base)
