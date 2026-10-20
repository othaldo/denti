class_name BossAttackController
extends RefCounted


static func start_overtime(enemy: Enemy) -> void:
	if not enemy.data.is_boss or enemy.overtime_active or enemy.dying or enemy.health <= 0.0:
		return
	enemy.overtime_active = true
	enemy.is_enraged = true
	enemy.sync_inflammation_aura()
	enemy.enraged.emit(enemy.global_position)
	enemy.queue_redraw()


static func tick_overtime(enemy: Enemy, delta: float) -> void:
	if not enemy.overtime_active or enemy.dying or enemy.health <= 0.0 or enemy.target == null or enemy.target.stats.health <= 0.0:
		return
	enemy.overtime_tick += maxf(delta, 0.0)
	var ticks := floori(enemy.overtime_tick + 0.000001)
	if ticks > 0:
		enemy.overtime_tick = maxf(enemy.overtime_tick - ticks, 0.0)
		enemy.advance_overtime(ticks)


static func advance_overtime(enemy: Enemy, seconds: int) -> void:
	if not enemy.data.is_boss or seconds <= 0:
		return
	var next := enemy.overtime_seconds + seconds
	var damage_factor := (1.0 + enemy.data.overtime_damage_per_second * next) / (1.0 + enemy.data.overtime_damage_per_second * enemy.overtime_seconds)
	var health_factor := (1.0 + enemy.data.overtime_health_per_second * next) / (1.0 + enemy.data.overtime_health_per_second * enemy.overtime_seconds)
	enemy.contact_damage *= damage_factor
	enemy.attack_damage *= damage_factor
	enemy.max_health *= health_factor
	enemy.health *= health_factor
	enemy.boss_damage_budget *= health_factor
	enemy.overtime_seconds = next
	enemy.sync_inflammation_aura()
	enemy.queue_redraw()


static func boss_dash_target(enemy: Enemy, direction: Vector2) -> Vector2:
	var margin := DentiArena.WALL_WIDTH + enemy.data.radius + 6.0
	return (enemy.global_position + direction * enemy.data.attack_speed * enemy.data.attack_duration).clamp(Vector2.ONE * margin, enemy.target.arena.arena_size - Vector2.ONE * margin)


static func fire_phase_burst(enemy: Enemy) -> void:
	enemy.boss_radial_volleys_remaining = maxi(enemy.data.boss_radial_volley_count + enemy.difficulty.boss_volley_bonus, 1)
	enemy.boss_radial_volley_timer = 0.0
	enemy.boss_radial_volley_index = 0
	enemy._fire_next_boss_radial_volley()


static func fire_next_boss_radial_volley(enemy: Enemy) -> void:
	var root := enemy._projectile_root()
	var volley_angle := enemy.boss_phase_gap_angle + deg_to_rad(enemy.data.boss_radial_angle_step_degrees * float(enemy.boss_radial_volley_index))
	if root != null:
		EnemyProjectilePatterns.fire_radial(root, enemy.global_position, enemy.data.boss_radial_count + enemy.boss_phase * 2, volley_angle, enemy.data.boss_projectile_speed * enemy.overtime_speed_factor(), enemy.attack_damage * 0.55, enemy.target, EnemyProjectilePatterns.BOSS_COLOR, enemy.inflicted_statuses)
	enemy.boss_radial_volley_index += 1
	enemy.boss_radial_volleys_remaining -= 1
	if enemy.boss_radial_volleys_remaining > 0:
		enemy.boss_radial_volley_timer += enemy.data.boss_radial_volley_interval
	elif enemy.boss_phase >= 2:
		enemy._fire_boss_signature(Vector2.RIGHT.rotated(enemy.boss_phase_gap_angle))


static func fire_boss_fan(enemy: Enemy) -> void:
	enemy._fire_boss_signature(enemy.special_direction)


static func fire_boss_signature(enemy: Enemy, charge_direction: Vector2) -> void:
	var root := enemy._projectile_root()
	if root == null:
		return
	match enemy.data.boss_signature:
		EnemyData.BossSignature.AIMED_FAN:
			EnemyProjectilePatterns.fire_aimed_fan(root, enemy.global_position, enemy.target.global_position - enemy.global_position, maxi(enemy.data.boss_fan_count + enemy.difficulty.boss_volley_bonus * 2, 1), enemy.data.boss_projectile_speed * enemy.overtime_speed_factor(), enemy.attack_damage * 0.45, enemy.target, EnemyProjectilePatterns.BOSS_COLOR, 3.0, enemy.inflicted_statuses)
		EnemyData.BossSignature.TRAIL_FAN:
			EnemyProjectilePatterns.fire_aimed_fan(root, enemy.global_position, -charge_direction, maxi(enemy.data.boss_fan_count + enemy.difficulty.boss_volley_bonus * 2, 1), enemy.data.boss_projectile_speed * enemy.overtime_speed_factor(), enemy.attack_damage * 0.45, enemy.target, EnemyProjectilePatterns.BOSS_COLOR, 3.0, enemy.inflicted_statuses)
		EnemyData.BossSignature.LANE:
			EnemyProjectilePatterns.fire_lane(root, enemy.global_position, charge_direction, maxi(enemy.data.boss_signature_projectile_count + enemy.difficulty.boss_volley_bonus, 1), enemy.data.boss_signature_projectile_spacing, enemy.data.boss_projectile_speed * enemy.overtime_speed_factor(), enemy.attack_damage * 0.45, enemy.target, EnemyProjectilePatterns.BOSS_COLOR, enemy.inflicted_statuses)
		EnemyData.BossSignature.SPACE_ORB:
			EnemyProjectilePatterns.fire_space_orb(root, enemy.global_position, charge_direction, enemy.data.boss_projectile_speed * enemy.overtime_speed_factor(), enemy.attack_damage * 0.5, enemy.data.boss_signature_orb_radius, enemy.target, enemy.inflicted_statuses)


static func boss_phase_floor(enemy: Enemy) -> float:
	return enemy.max_health * (2.0 - float(enemy.boss_phase)) / 3.0


static func start_boss_phase(enemy: Enemy) -> void:
	enemy.boss_phase += 1
	enemy.boss_phase_timer = enemy.data.boss_phase_duration
	enemy.boss_phase_burst_fired = false
	enemy.boss_radial_volleys_remaining = 0
	enemy.boss_radial_volley_timer = 0.0
	enemy.boss_radial_volley_index = 0
	enemy.boss_phase_gap_angle = enemy.global_position.angle_to_point(enemy.target.global_position)
	enemy.special_direction = Vector2.RIGHT.rotated(enemy.boss_phase_gap_angle)
	enemy.special_phase = Enemy.SpecialPhase.COOLDOWN
	enemy.special_timer = enemy.data.special_interval * (0.72 if enemy.is_enraged else 1.0)
	if enemy.pillow_encounter != null:
		enemy.pillow_encounter.cancel()
		enemy.boss_phase_burst_fired = true
	if enemy.cloak_encounter != null:
		enemy.cloak_encounter.cancel()
		enemy.boss_phase_burst_fired = true
	enemy.boss_phase_started.emit(enemy.global_position, enemy.boss_phase)
	enemy.reinforcements_requested.emit(enemy.data.boss_phase_adds)
	enemy.queue_redraw()


static func guard_boss_hit(enemy: Enemy) -> void:
	if enemy.boss_guard_feedback_time <= 0.0:
		enemy.boss_guarded.emit(enemy.global_position)
		enemy.boss_guard_feedback_time = 0.8
	enemy.queue_redraw()
