class_name ImperialRetinueVisuals
extends RefCounted

static func draw(retinue: ImperialRetinue) -> void:
	var base := retinue.global_transform.affine_inverse()
	var enemy := retinue.encounter.enemy
	retinue.draw_set_transform_matrix(base)
	if retinue.blocks_damage():
		retinue.draw_circle(enemy.global_position, enemy.data.radius + 24, Color(0.60, 0.24, 0.87, 0.13))
		CombatDrawCache.arc(retinue, enemy.global_position, enemy.data.radius + 24, 0, TAU, 64, Color("c88bff"), 4, base)
	for minion in retinue.live_minions():
		retinue.draw_set_transform_matrix(base)
		var keeper := minion.imperial_vassal.profile.role == ImperialVassalData.Role.KEEPER
		var color := Color("8ee8cb") if keeper and retinue.regeneration_left > 0 and retinue.state == ImperialRetinue.State.CHANNEL else Color("bd82e0")
		retinue.draw_line(minion.global_position, enemy.global_position, Color(color, 0.5), 3, true)
		if keeper and retinue.regeneration_left > 0 and retinue.state == ImperialRetinue.State.CHANNEL:
			for index in 3:
				var progress := fposmod(retinue.elapsed * 0.7 + float(index) / 3, 1)
				retinue.draw_circle(minion.global_position.lerp(enemy.global_position, progress), 5, color)
	if retinue.state == ImperialRetinue.State.CHANNEL:
		var progress := 1 - retinue.remaining / retinue.profile.channel_seconds
		WarningEffects.timer(retinue, enemy.global_position, enemy.data.radius + 32, progress, Color("e4a8ff"), base)
		if retinue.pulse_warned:
			for ray in EnemyProjectilePatterns.fan_directions(retinue.pulse_aim, 5, 0.22): WarningEffects.aim(retinue, retinue.anchor, retinue.anchor + ray * 650, Color("cc8eff"), 1 - retinue.pulse_remaining / retinue.profile.pulse_warning, base)
	elif retinue.state == ImperialRetinue.State.FAILURE:
		for ray in EnemyProjectilePatterns.circle_directions(8 + retinue.live_minions().size() * 4, 0): WarningEffects.aim(retinue, retinue.anchor, retinue.anchor + ray * 650, Color("d9a1ff"), 1 - retinue.remaining / retinue.profile.failure_warning, base)
	elif retinue.state == ImperialRetinue.State.OPEN:
		CombatDrawCache.arc(retinue, enemy.global_position, enemy.data.radius + 25, 0, TAU, 64, Color("ffe19b"), 5, base)
