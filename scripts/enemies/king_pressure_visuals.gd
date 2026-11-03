class_name KingPressureVisuals
extends RefCounted

static func _art(trial: KingPressureTrial, index: int, at: Vector2, extent: float, tint: Color = Color.WHITE) -> void:
	var texture := KingAcidArt.texture(index)
	var size := texture.get_size() * extent / maxf(texture.get_width(), texture.get_height())
	trial.draw_set_transform_matrix(trial.global_transform.affine_inverse())
	trial.draw_texture_rect(texture, Rect2(at - size * 0.5, size), false, tint)

static func draw(trial: KingPressureTrial) -> void:
	var base := trial.global_transform.affine_inverse()
	var enemy := trial.encounter.enemy
	var tint := Color("b7ed38")
	var aligned := trial.aligned_valve(trial.aim, trial.origin) if trial.state == KingPressureTrial.State.TRACKING else trial.hit_valve
	trial.draw_set_transform_matrix(base)
	if trial.blocks_damage():
		KingPressureShield.draw(trial, base)
	for index in trial.valves.size():
		var valve := trial.valves[index]
		var at: Vector2 = valve.at
		trial.draw_set_transform_matrix(base)
		trial.draw_circle(at + Vector2(0, 18), trial.profile.valve_radius + 9, Color(0.1, 0.12, 0.09, 0.50))
		if valve.broken:
			_art(trial, 7, at, 75, Color(0.65, 0.75, 0.65, 0.7))
			continue
		trial.draw_line(enemy.global_position, at, Color(0.63, 0.88, 0.2, 0.30), 3, true)
		_art(trial, 5, at, trial.profile.valve_radius * 2.6)
		var color := Color("ffdf6b") if aligned == index else Color("89bec0")
		CombatDrawCache.arc(trial, at, trial.profile.valve_radius + 10, 0, TAU, 48, color, 3, base)
		# These floor circles mark a firing line, not an interact/key prompt.
		var spot := trial.stance(index)
		CombatDrawCache.arc(trial, spot, 22, 0, TAU, 40, Color(color, 0.80), 2, base)
		trial.draw_line(spot - Vector2(7, 0), spot + Vector2(7, 0), color, 2)
		trial.draw_line(spot - Vector2(0, 7), spot + Vector2(0, 7), color, 2)
	var start := trial.origin + trial.aim * 30
	if trial.state == KingPressureTrial.State.TRACKING:
		WarningEffects.aim(trial, start, trial.destination, Color(0.7, 0.96, 0.24, 0.65), 1 - trial.remaining / trial.profile.tracking_seconds, base)
	elif trial.state == KingPressureTrial.State.LOCKED:
		WarningEffects.capsule(trial, start, trial.destination, trial.profile.beam_half_width, Color("ffa350"), 1 - trial.remaining / trial.profile.lock_seconds, base)
	elif trial.state == KingPressureTrial.State.FIRING:
		WarningEffects.capsule(trial, start, trial.destination, trial.profile.beam_half_width, tint, 1, base, WarningEffects.BATCH.Phase.ACTIVE)
		var length := start.distance_to(trial.destination)
		trial.draw_set_transform_matrix(base * Transform2D(trial.aim.angle(), start))
		trial.draw_texture_rect_region(KingAcidArt.STREAM, Rect2(0, -trial.profile.beam_half_width, length, trial.profile.beam_half_width * 2), AcidKingVisuals.STREAM_CONTENT)
	elif trial.state == KingPressureTrial.State.BLAST_WARNING:
		for ray in EnemyProjectilePatterns.circle_directions(8 + trial.remaining_valves() * 4, 0):
			WarningEffects.aim(trial, trial.anchor + ray * enemy.data.radius, trial.anchor + ray * 600, Color("b7ed38"), 1 - trial.remaining / trial.profile.blast_warning_seconds, base)
	if trial.flash_remaining > 0:
		var progress := 1 - trial.flash_remaining / 0.7
		_art(trial, 7, trial.flash_at, lerpf(60, 145, progress), Color(1, 1, 1, 1 - progress))
		CombatDrawCache.arc(trial, trial.flash_at, lerpf(36, 115, progress), 0, TAU, 48, Color(0.9, 1, 0.55, 1 - progress), 4, base)
	if trial.state == KingPressureTrial.State.SHATTER:
		var progress := 1 - trial.remaining / trial.profile.shatter_seconds
		CombatDrawCache.arc(trial, trial.anchor, lerpf(90, 240, progress), 0, TAU, 64, Color(0.95, 1, 0.6, 1 - progress), 8, base)
	elif trial.state == KingPressureTrial.State.EXPOSED:
		CombatDrawCache.arc(trial, enemy.global_position, enemy.data.radius + 18, 0, TAU, 64, Color("ffdc79"), 4, base)
