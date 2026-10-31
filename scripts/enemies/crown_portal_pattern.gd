class_name CrownPortalPattern
extends RefCounted
## A new portal intercepts movement; an already announced portal never changes.

static func plan(encounter: CrownCourtEncounter, seconds: float) -> void:
	var enemy := encounter.enemy
	var profile := encounter.profile
	var at := HazardGeometry.player_at(enemy.target, seconds) if seconds >= 0 else enemy.target.global_position
	var direction := enemy.global_position.direction_to(at)
	if not encounter.legacy_sequence and not enemy.target.velocity.is_zero_approx():
		direction = enemy.target.velocity.normalized()
		var intercept_seconds := profile.portal_warning_seconds + profile.portal_half_length / profile.lance.speed
		at += (enemy.target.velocity * intercept_seconds).limit_length(profile.portal_lead_distance)
	var along := direction.rotated(PI * 0.5 + (encounter.step_index % 2) * profile.portal_angle_step_radians)
	if along.is_zero_approx(): along = Vector2.RIGHT
	var margin := Vector2.ONE * DentiArena.PLAYER_MARGIN
	var visible := enemy.get_canvas_transform().affine_inverse() * enemy.get_viewport_rect()
	var inset := Vector2(minf(50, visible.size.x * 0.16), minf(100, visible.size.y * 0.20))
	var bounds := Rect2(visible.position + inset, visible.size - inset * 2).intersection(Rect2(margin, enemy.target.arena.arena_size - margin * 2))
	encounter.portal_a = (at - along * profile.portal_half_length).clamp(bounds.position, bounds.end)
	encounter.portal_b = (at + along * profile.portal_half_length).clamp(bounds.position, bounds.end)
