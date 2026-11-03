class_name CaramelOverloadVisuals
extends RefCounted

static func draw(ritual: CaramelOverload) -> void:
	var base := ritual.global_transform.affine_inverse()
	ritual.draw_set_transform_matrix(base)
	var boss := ritual.encounter.enemy
	var center := boss.global_position
	var color := Color("ff7d9c")
	if ritual.blocks_damage():
		ritual.draw_circle(center, boss.data.radius + 24, Color(0.55, 0.85, 0.95, 0.12))
		CombatDrawCache.arc(ritual, center, boss.data.radius + 24, 0, TAU, 64, Color("9ce9f1"), 4, base)
	for pylon in ritual.live_pylons():
		ritual.draw_line(center, pylon.global_position, Color(color, 0.35), 3, true)
	for entry in ritual.pressure.entries:
		if not entry.warning: continue
		for ray in ritual.pressure.directions(entry.aim):
			WarningEffects.aim(ritual, entry.at + ray * 34, entry.at + ray * 260, Color("f078a3"), 1 - entry.remaining / ritual.profile.heart_warning_seconds, base)
	for burst in ritual.pressure.breaks:
		var progress: float = 1 - burst.life / 0.5
		var texture := PrinceCaramelArt.texture(7)
		var size := texture.get_size() * lerpf(0.12, 0.34, progress)
		ritual.draw_texture_rect(texture, Rect2(burst.at - size * 0.5, size), false, Color(1, 1, 1, 1 - progress))
	if ritual.state == CaramelOverload.State.ACTIVE and ritual.lane_state > 0:
		var active := ritual.lane_state == 2
		var progress := 1.0 if active else 1.0 - ritual.lane_remaining / ritual.profile.lane_warning_seconds
		var phase := WarningEffects.BATCH.Phase.ACTIVE if active else WarningEffects.BATCH.Phase.WARNING
		WarningEffects.lane(ritual, ritual.lane_start(), ritual.lane_end(), ritual.profile.lane_half_width, Color("ff8058"), progress, base, PackedFloat32Array(), phase)
	if ritual.state == CaramelOverload.State.BLAST:
		for ray in EnemyProjectilePatterns.circle_directions(4 + ritual.missed * 4, 0):
			WarningEffects.aim(ritual, ritual.anchor + ray * boss.data.radius, ritual.anchor + ray * 600, color, 1 - ritual.remaining / ritual.profile.blast_warning_seconds, base)
	if ritual.state == CaramelOverload.State.RECOVERY:
		CombatDrawCache.arc(ritual, center, boss.data.radius + 20, 0, TAU, 64, Color("ffdc79"), 5, base)
