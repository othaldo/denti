class_name EnemyVisuals
extends RefCounted


static func draw(enemy: Enemy) -> void:
	if enemy.data != null and enemy.health > 0.0:
		for index in enemy.inflicted_statuses.size():
			var kind := int(enemy.inflicted_statuses[index]["kind"])
			var at := Vector2((index - (enemy.inflicted_statuses.size() - 1) * 0.5) * 15.0, -enemy.data.radius - 7.0)
			enemy.draw_circle(at, 5.0, DentiStatus.COLORS[kind])
			if kind == DentiStatus.Type.BLEED:
				enemy.draw_line(at + Vector2(-2, 2), at + Vector2(2, -2), Color.WHITE, 2.0)
			else:
				enemy.draw_circle(at, 2.0, Color(0.13, 0.35, 0.13))
	if enemy.data == null:
		return
	if enemy.treasure_carrier and enemy.health > 0.0:
		enemy.draw_arc(Vector2.ZERO, enemy.data.radius + 6.0, 0, TAU, 24, Color(1, 0.8, 0.25, 0.75), 2.0)
		for index in 4:
			var point := Vector2.RIGHT.rotated(enemy.animation_time * 0.4 + index * TAU / 4.0) * (enemy.data.radius + 11.0)
			var shine := 3.0 + sin(enemy.animation_time + index) * 1.5
			enemy.draw_line(point - Vector2(shine, 0), point + Vector2(shine, 0), Color(1, 0.95, 0.6), 2.0)
			enemy.draw_line(point - Vector2(0, shine), point + Vector2(0, shine), Color(1, 0.95, 0.6), 2.0)
	if enemy.dying:
		var progress := clampf(enemy.death_elapsed / Enemy.BOSS_DEATH_DURATION, 0.0, 1.0)
		var fade := 1.0 - progress
		enemy.draw_circle(Vector2.ZERO, enemy.data.radius * (1.0 + progress * 3.0), Color(0.56, 0.15, 0.42, 0.18 * fade))
		CombatDrawCache.arc(enemy, Vector2.ZERO, enemy.data.radius * (0.8 + progress * 3.4), 0.0, TAU, 48, Color(1.0, 0.78, 0.38, 0.95 * fade), 11.0 * fade + 2.0)
		for index in 12:
			var ray := Vector2.RIGHT.rotated(TAU * float(index) / 12.0 + 0.2)
			var shard_at := ray * (enemy.data.radius * 0.7 + progress * 180.0)
			enemy.draw_line(shard_at, shard_at + ray * (16.0 + 26.0 * fade), Color(1.0, 0.76, 0.35, fade), 6.0 * fade + 1.0)
		return
	if enemy.data.is_boss and enemy.data.boss_guard_recharge_seconds > 0.0:
		if enemy.boss_phase_timer > 0.0 or enemy.boss_radial_volleys_remaining > 0:
			CombatDrawCache.arc(enemy, Vector2.ZERO, enemy.data.radius + 19.0, 0.0, TAU, 48, Color(0.95, 0.32, 0.63, 0.9), 7.0)
			if not enemy.boss_phase_burst_fired or enemy.boss_radial_volleys_remaining > 0:
				var first_preview_index := enemy.boss_radial_volley_index if enemy.boss_phase_burst_fired else 0
				var preview_count := enemy.boss_radial_volleys_remaining if enemy.boss_phase_burst_fired else enemy.data.boss_radial_volley_count
				var current_gap_angle := enemy.boss_phase_gap_angle + deg_to_rad(enemy.data.boss_radial_angle_step_degrees * float(first_preview_index))
				for ray in EnemyProjectilePatterns.radial_directions(enemy.data.boss_radial_count + enemy.boss_phase * 2, current_gap_angle):
					AttackEffects.aim(enemy, ray * enemy.data.radius, ray * 290.0, Color(0.95, 0.25, 0.42, 0.6), 0.5)
				for volley_offset in preview_count:
					var preview_angle := enemy.boss_phase_gap_angle + deg_to_rad(enemy.data.boss_radial_angle_step_degrees * float(first_preview_index + volley_offset))
					var gap_marker := Vector2.RIGHT.rotated(preview_angle) * 290.0
					CombatDrawCache.arc(enemy, gap_marker, 10.0, 0.0, TAU, 20, Color(1.0, 0.78, 0.3, 0.88), 3.0)
				if enemy.boss_phase >= 2:
					var phase_aim := Vector2.RIGHT.rotated(enemy.boss_phase_gap_angle)
					match enemy.data.boss_signature:
						EnemyData.BossSignature.AIMED_FAN:
							for ray in EnemyProjectilePatterns.fan_directions(phase_aim, enemy.data.boss_fan_count):
								AttackEffects.aim(enemy, ray * enemy.data.radius, ray * 320.0, Color(1.0, 0.65, 0.3, 0.7), 0.5)
						EnemyData.BossSignature.TRAIL_FAN:
							for ray in EnemyProjectilePatterns.fan_directions(-phase_aim, enemy.data.boss_fan_count):
								AttackEffects.aim(enemy, ray * enemy.data.radius, ray * 320.0, Color(1.0, 0.65, 0.3, 0.7), 0.5)
						EnemyData.BossSignature.LANE:
							var lane_half_width := enemy.data.boss_signature_projectile_spacing * float(enemy.data.boss_signature_projectile_count - 1) * 0.5 + 21.0
							var lane_end := phase_aim * 520.0
							AttackEffects.lane(enemy, Vector2.ZERO, lane_end, lane_half_width, Color(1.0, 0.35, 0.48, 0.8), 0.5)
						EnemyData.BossSignature.SPACE_ORB:
							var orb_end := phase_aim * 520.0
							AttackEffects.lane(enemy, Vector2.ZERO, orb_end, enemy.data.boss_signature_orb_radius * 0.7, Color(1.0, 0.43, 0.25, 0.65), 0.5)
							GroundEffects.draw(enemy, GroundEffects.Shape.DANGER, orb_end, enemy.data.boss_signature_orb_radius, Color(1.0, 0.48, 0.3, 0.85))
		elif enemy.boss_damage_budget <= enemy.max_health * 0.01:
			CombatDrawCache.arc(enemy, Vector2.ZERO, enemy.data.radius + 19.0, 0.0, TAU, 48, Color(0.43, 0.84, 0.94, 0.8), 5.0)
	if enemy.data.is_elite and enemy.data.elite_guard_fraction > 0.0:
		var guard_ratio := clampf(enemy.elite_damage_budget / (enemy.max_health * enemy.data.elite_guard_fraction), 0.0, 1.0)
		CombatDrawCache.arc(enemy, Vector2.ZERO, enemy.data.radius + 18.0, 0.0, TAU, 40, Color(0.43, 0.84, 0.94, 0.22), 4.0)
		if guard_ratio > 0.0:
			CombatDrawCache.arc(enemy, Vector2.ZERO, enemy.data.radius + 18.0, -PI / 2.0, -PI / 2.0 + TAU * guard_ratio, 40, Color(0.43, 0.84, 0.94, 0.85), 4.0)
	if enemy.spatial_index == null:
		enemy.draw_attack_visuals(enemy)
	if enemy.pulse_flash_time > 0.0:
		var flash_radius := enemy.data.dash_impact_radius if enemy.active_special_attack == EnemyData.SpecialAttack.DASH and enemy.data.dash_impact_radius > 0.0 else enemy.data.attack_radius
		if enemy.active_special_attack == EnemyData.SpecialAttack.DASH and enemy.data.dash_impact_radius > 0.0:
			WarningEffects.charge_impact(enemy, Vector2.ZERO, flash_radius, 1, Color(1, 1, 1, enemy.pulse_flash_time / Enemy.PULSE_FLASH_DURATION))
		else:
			CombatDrawCache.arc(enemy, Vector2.ZERO, flash_radius, 0.0, TAU, 64, Color(1.0, 0.72, 0.27, enemy.pulse_flash_time / Enemy.PULSE_FLASH_DURATION), 8.0)
	enemy.affix_effects.draw_markers(enemy)
	if enemy.bleed_stacks > 0:
		CombatDrawCache.arc(enemy, Vector2.ZERO, enemy.data.radius + 4.0, 0.0, TAU, 24, Color(0.78, 0.25, 0.48, 0.85), 2.5 + enemy.bleed_stacks)
	if enemy.wet_time > 0.0:
		CombatDrawCache.arc(enemy, Vector2.ZERO, enemy.data.radius + 8.0, 0.0, TAU, 24, Color(0.36, 0.86, 1.0, 0.88), 3.0)
	if enemy.exposure_time > 0.0:
		CombatDrawCache.arc(enemy, Vector2.ZERO, enemy.data.radius + 6.0, 0.0, TAU, 24, Color(0.65, 1.0, 0.70, 0.8), 2.0)
	if enemy.haste_time > 0.0:
		CombatDrawCache.arc(enemy, Vector2.ZERO, enemy.data.radius + 8.0, 0.0, TAU, 24, Color(1.0, 0.46, 0.73, 0.9), 3.0)
	if enemy.data.is_elite:
		CombatDrawCache.arc(enemy, Vector2.ZERO, enemy.data.radius + 12.0, 0.0, TAU, 40, Color(1.0, 0.73, 0.24, 0.95), 4.0)
	if enemy.data.aura_radius > 0.0:
		CombatDrawCache.arc(enemy, Vector2.ZERO, enemy.data.aura_radius, 0.0, TAU, 48, Color(1.0, 0.46, 0.73, 0.45), 2.0)
	if enemy.is_enraged and not enemy.overtime_active:
		CombatDrawCache.arc(enemy, Vector2.ZERO, enemy.data.radius + 12.0, 0.0, TAU, 40, Color(1.0, 0.26, 0.23, 0.85), 4.0)
	if enemy.spatial_index == null:
		enemy.draw_circle(Vector2(0.0, enemy.data.radius * 0.7), enemy.data.radius * 0.7, Color(0.17, 0.13, 0.17, 0.17))
	if enemy.data.is_boss:
		enemy.draw_rect(Rect2(Vector2(-enemy.data.radius, enemy.data.radius + 11.0), Vector2(enemy.data.radius * 2.0, 8.0)), Color(0.18, 0.13, 0.2))
		enemy.draw_rect(Rect2(Vector2(-enemy.data.radius + 1.0, enemy.data.radius + 12.0), Vector2((enemy.data.radius * 2.0 - 2.0) * enemy.health / enemy.max_health, 6.0)), Color(0.92, 0.49, 0.25))


static func warning_rays(enemy: Enemy, mode: int, count: int) -> Array[Vector2]:
	if mode != enemy.warning_ray_mode or count != enemy.warning_ray_count or enemy.special_direction != enemy.warning_ray_direction:
		enemy.warning_rays = EnemyProjectilePatterns.fan_directions(enemy.special_direction, count) if mode == EnemyData.SpecialAttack.SHOOT else EnemyProjectilePatterns.radial_directions(count, enemy.special_direction.angle() + PI)
		enemy.warning_ray_mode = mode
		enemy.warning_ray_count = count
		enemy.warning_ray_direction = enemy.special_direction
	return enemy.warning_rays


static func warning_lane_start(enemy: Enemy) -> Vector2:
	return enemy.special_direction * enemy.data.radius * 0.5 if enemy.active_special_attack == EnemyData.SpecialAttack.BOSS and enemy.boss_move == Enemy.BossMove.CHARGE else Vector2.ZERO


static func warning_lane_end(enemy: Enemy) -> Vector2:
	match enemy.active_special_attack:
		EnemyData.SpecialAttack.DASH:
			if enemy.target == null:
				return Vector2.ZERO
			var margin := DentiArena.WALL_WIDTH + enemy.data.radius + 6.0
			return (enemy.global_position + enemy.special_direction * enemy.data.attack_speed * enemy.overtime_speed_factor() * enemy.data.attack_duration).clamp(Vector2.ONE * margin, enemy.target.arena.arena_size - Vector2.ONE * margin) - enemy.global_position
		EnemyData.SpecialAttack.BOSS:
			return enemy.boss_dash_end - enemy.global_position
		EnemyData.SpecialAttack.LANE, EnemyData.SpecialAttack.SPACE_ORB:
			return enemy.special_direction.normalized() * 550.0
	return Vector2.ZERO


static func warning_lane_half_width(enemy: Enemy) -> float:
	match enemy.active_special_attack:
		EnemyData.SpecialAttack.DASH:
			return enemy.data.radius
		EnemyData.SpecialAttack.BOSS:
			return enemy.data.radius + 19.0 if enemy.boss_move == Enemy.BossMove.CHARGE else 0.0
		EnemyData.SpecialAttack.LANE:
			return enemy.data.lane_projectile_spacing * float(enemy.data.lane_projectile_count - 1) * 0.5 + 21.0
		EnemyData.SpecialAttack.SPACE_ORB:
			return enemy.data.space_orb_radius * 0.7
	return 0.0


static func draw_warning_fill(enemy: Enemy, canvas: CanvasItem, base: Transform2D = Transform2D.IDENTITY, fill_scales: PackedFloat32Array = PackedFloat32Array()) -> void:
	if enemy.special_phase != Enemy.SpecialPhase.WARNING or enemy.warning_lane_half_width() <= 0.0:
		return
	var tint := Color(1.0, 0.28, 0.18, 0.95)
	match enemy.active_special_attack:
		EnemyData.SpecialAttack.BOSS:
			tint = Color(1.0, 0.3, 0.32, 0.95)
		EnemyData.SpecialAttack.LANE:
			tint = Color(0.50, 0.88, 0.14, 0.9)
		EnemyData.SpecialAttack.SPACE_ORB:
			tint = Color(1.0, 0.43, 0.25, 0.65)
	if canvas != enemy:
		tint *= enemy.modulate * enemy.self_modulate
	var progress := 1.0 - clampf(enemy.special_timer / maxf(enemy.data.warning_time, 0.01), 0.0, 1.0)
	if enemy.active_special_attack == EnemyData.SpecialAttack.DASH or enemy.active_special_attack == EnemyData.SpecialAttack.BOSS and enemy.boss_move == Enemy.BossMove.CHARGE:
		WarningEffects.charge(canvas, enemy.warning_lane_start(), enemy.warning_lane_end(), enemy.warning_lane_half_width(), enemy.charge_aim_distance, tint, progress, base, fill_scales)
	else:
		AttackEffects.lane(canvas, enemy.warning_lane_start(), enemy.warning_lane_end(), enemy.warning_lane_half_width(), tint, progress, base, fill_scales)


static func draw_attack_visuals(enemy: Enemy, canvas: CanvasItem, base: Transform2D = Transform2D.IDENTITY, fill_scales: PackedFloat32Array = PackedFloat32Array(), draw_fill: bool = true) -> void:
	var visual_tint := enemy.modulate * enemy.self_modulate if canvas != enemy else Color.WHITE
	if draw_fill:
		enemy.draw_warning_fill(canvas, base, fill_scales)
	if enemy.special_phase == Enemy.SpecialPhase.WARNING:
		var warning_color := Color(0.73, 0.20, 0.19, 0.85)
		var warning_progress := 1.0 - clampf(enemy.special_timer / maxf(enemy.data.warning_time, 0.01), 0.0, 1.0)
		if enemy.active_special_attack == EnemyData.SpecialAttack.DASH or enemy.active_special_attack == EnemyData.SpecialAttack.BOSS and enemy.boss_move == Enemy.BossMove.CHARGE:
			var dash_path := enemy.warning_lane_end()
			if enemy.active_special_attack == EnemyData.SpecialAttack.DASH and enemy.data.dash_impact_radius > 0.0:
				WarningEffects.charge_impact(canvas, dash_path, enemy.data.dash_impact_radius, warning_progress, visual_tint)
			else:
				AttackEffects.flash(canvas, dash_path, enemy.data.radius * 0.55 if enemy.data.is_boss else 9.0, Color(1.0, 0.4, 0.32, 0.3) * visual_tint)
		elif enemy.active_special_attack == EnemyData.SpecialAttack.SHOOT:
			var shot_color := Color(DentiStatus.COLORS[int(enemy.inflicted_statuses[0]["kind"])], 0.9) if not enemy.inflicted_statuses.is_empty() else Color(enemy.data.projectile_color, 0.9)
			for ray in enemy._warning_rays(EnemyData.SpecialAttack.SHOOT, enemy._aimed_projectile_count()):
				AttackEffects.aim(canvas, ray * enemy.data.radius, ray * 150.0, shot_color * visual_tint, warning_progress, base)
			AttackEffects.warning_ring(canvas, Vector2.ZERO, enemy.data.radius + 8.0, warning_progress, shot_color * visual_tint)
		elif enemy.active_special_attack == EnemyData.SpecialAttack.RADIAL:
			var shot_color := Color(1.0, 0.48, 0.19, 0.9)
			for ray in enemy._warning_rays(EnemyData.SpecialAttack.RADIAL, enemy.data.radial_count):
				AttackEffects.aim(canvas, ray * enemy.data.radius, ray * 235.0, Color(shot_color, 0.3 + warning_progress * 0.35) * visual_tint, warning_progress, base)
			AttackEffects.warning_ring(canvas, Vector2.ZERO, enemy.data.radius + 9.0, warning_progress, shot_color * visual_tint)
		elif enemy.active_special_attack == EnemyData.SpecialAttack.LANE:
			var lane_color := Color(0.50, 0.88, 0.14, 0.9)
			AttackEffects.warning_ring(canvas, Vector2.ZERO, enemy.data.radius + 8.0, warning_progress, lane_color * visual_tint)
		elif enemy.active_special_attack == EnemyData.SpecialAttack.SPACE_ORB:
			var orb_color := Color(1.0, 0.43, 0.25, 0.88)
			var orb_end := enemy.warning_lane_end()
			AttackEffects.danger(canvas, orb_end, enemy.data.space_orb_radius, orb_color * visual_tint)
			AttackEffects.warning_ring(canvas, Vector2.ZERO, enemy.data.radius + 8.0, warning_progress, orb_color * visual_tint)
		else:
			AttackEffects.danger(canvas, Vector2.ZERO, enemy.data.attack_radius, Color(1.0, 0.34, 0.29, 0.8 + warning_progress * 0.2) * visual_tint)
			AttackEffects.warning_ring(canvas, Vector2.ZERO, enemy.data.attack_radius - 8.0, warning_progress, Color(1.0, 0.72, 0.27) * visual_tint)
	elif enemy.special_phase == Enemy.SpecialPhase.ACTIVE and (enemy.active_special_attack == EnemyData.SpecialAttack.DASH or enemy.active_special_attack == EnemyData.SpecialAttack.BOSS and enemy.boss_move == Enemy.BossMove.CHARGE):
		AttackEffects.strip(canvas, AttackEffects.Shape.TRAIL, enemy.boss_dash_origin - enemy.global_position if enemy.data.is_boss else -enemy.special_direction * enemy.data.radius, Vector2.ZERO, 32.0 if enemy.data.is_boss else 16.0, Color(1.0, 0.72, 0.27, 0.7) * visual_tint, enemy.animation_time, base)
