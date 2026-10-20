class_name CloakStrikeArea
extends RefCounted
## Rendering consumes the locked attack geometry; damage remains independent.

static func paint(attack: CloakEncounter) -> void:
	var warning := attack.state == CloakEncounter.State.WARNING
	var duration := attack.profile.warning(attack.strike_index) if warning else attack.profile.strike_seconds
	var progress := 1.0 - attack.remaining / duration
	var age := attack._stage_elapsed()
	var striking := not warning and age >= attack.profile.hit_start and age <= attack.profile.hit_end
	if striking:
		progress = clampf((age - attack.profile.hit_start) / (attack.profile.hit_end - attack.profile.hit_start), 0, 1)
	var shape := attack.profile.strike(attack.variant)
	if attack.variant == CloakStrikeData.Kind.RING:
		WarningEffects.ring(attack, attack.origin, shape.inner_radius, shape.reach, progress, not warning, striking)
	else:
		WarningEffects.sector(attack, attack.origin, attack.direction, shape.reach, attack.half_angle, progress, not warning, striking, attack.global_transform.affine_inverse())
