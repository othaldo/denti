class_name KingPressureShield
extends RefCounted
## A glass shell with one powered segment per intact valve.

static func draw(trial: KingPressureTrial, base: Transform2D) -> void:
	var at := trial.encounter.enemy.global_position
	var shatter := 1 - trial.remaining / trial.profile.shatter_seconds if trial.state == KingPressureTrial.State.SHATTER else 0.0
	var radius := (trial.encounter.enemy.data.radius + 42) * (1 + sin(trial.elapsed * 3.0) * 0.015) + shatter * 70
	var opacity := 1 - shatter
	trial.draw_set_transform_matrix(base)
	trial.draw_circle(at, radius, Color(0.30, 0.96, 0.82, 0.16 * opacity))
	for ring in 5:
		CombatDrawCache.arc(trial, at, radius - ring * 2, 0, TAU, 80, Color(0.40, 1, 0.85, (0.26 - ring * 0.04) * opacity), 3, base)
	var count := maxi(trial.valves.size(), 1)
	for index in count:
		var angle := TAU * index / count - PI * 0.5
		var live: bool = index < trial.valves.size() and not trial.valves[index].broken
		CombatDrawCache.arc(trial, at, radius + 5, angle + 0.06, angle + TAU / count - 0.06, 28, Color(0.72, 1, 0.86, (0.95 if live else 0.12) * opacity), 4, base)
		if not live:
			var normal := Vector2.from_angle(angle + PI / count)
			var tangent := normal.orthogonal()
			var crack := PackedVector2Array([at + normal * radius, at + normal * radius * 0.73 + tangent * 9, at + normal * radius * 0.59 - tangent * 6, at + normal * radius * 0.35])
			trial.draw_polyline(crack, Color(0.8, 1, 0.95, 0.65 * opacity), 2, true)
	CombatDrawCache.arc(trial, at, radius - 11, -2.9, -1.9, 24, Color(0.95, 1, 1, 0.85 * opacity), 5, base)
	CombatDrawCache.arc(trial, at, radius - 18, 0.25, 0.85, 18, Color(0.80, 1, 0.95, 0.48 * opacity), 3, base)
