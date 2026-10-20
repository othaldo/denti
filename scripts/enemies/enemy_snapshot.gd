class_name EnemySnapshot
extends RefCounted


static func capture(enemy: Enemy) -> Dictionary:
	return {
		"type": enemy.data.resource_path, "treasure_carrier": enemy.treasure_carrier, "chill_time": enemy.chill_time, "position": SnapshotValues.vector_data(enemy.position),
		"sprite_flip_h": enemy.sprite.flip_h,
		"inflicted_statuses": enemy.inflicted_statuses.duplicate(true),
		"health": enemy.health, "phase": enemy.special_phase,
		"timer": enemy.special_timer, "direction": SnapshotValues.vector_data(enemy.special_direction),
		"charge_aim_distance": enemy.charge_aim_distance,
		"boss_move": enemy.boss_move, "boss_charge_next": enemy.boss_charge_next,
		"boss_dash_end": SnapshotValues.vector_data(enemy.boss_dash_end), "boss_dash_origin": SnapshotValues.vector_data(enemy.boss_dash_origin),
		"dying": enemy.dying, "death_elapsed": enemy.death_elapsed, "enraged": enemy.is_enraged,
		"overtime_active": enemy.overtime_active, "overtime_seconds": enemy.overtime_seconds, "overtime_tick": enemy.overtime_tick,
		"affix_effects": enemy.affix_effects.save_data(), "bleed_stacks": enemy.bleed_stacks, "bleed_dps": enemy.bleed_dps,
		"bleed_time": enemy.bleed_time, "bleed_tick": enemy.bleed_tick,
		"wet_time": enemy.wet_time,
		"exposure_time": enemy.exposure_time, "enamel_exposure": enemy.enamel_exposure,
		"haste_time": enemy.haste_time, "haste_bonus": enemy.haste_bonus,
		"aura_timer": enemy.aura_timer,
		"boss_damage_budget": enemy.boss_damage_budget, "boss_phase": enemy.boss_phase,
		"elite_damage_budget": enemy.elite_damage_budget,
		"boss_phase_timer": enemy.boss_phase_timer,
		"boss_phase_burst_fired": enemy.boss_phase_burst_fired,
		"boss_phase_gap_angle": enemy.boss_phase_gap_angle,
		"boss_radial_volleys_remaining": enemy.boss_radial_volleys_remaining,
		"boss_radial_volley_timer": enemy.boss_radial_volley_timer,
		"boss_radial_volley_index": enemy.boss_radial_volley_index,
		"pillow": enemy.pillow_encounter.save_data() if enemy.pillow_encounter != null else {},
		"cloak": enemy.cloak_encounter.save_data() if enemy.cloak_encounter != null else {},
	}


static func restore(enemy: Enemy, entry: Dictionary, boss_pending: bool = false) -> void:
	enemy.sprite.flip_h = bool(entry.get("sprite_flip_h", enemy.sprite.flip_h)) if enemy.data.sprite_facing != EnemyData.SpriteFacing.FRONT else false
	# Legacy mobs had no random traits; never reroll traits while resuming.
	enemy.inflicted_statuses = DentiStatus.sanitize_attacks(entry.get("inflicted_statuses", []))
	enemy.queue_redraw()
	enemy.overtime_active = bool(entry.get("overtime_active", boss_pending)) and enemy.data.is_boss
	if enemy.overtime_active:
		enemy.advance_overtime(maxi(int(entry.get("overtime_seconds", 0)), 0))
		enemy.overtime_tick = clampf(float(entry.get("overtime_tick", 0.0)), 0.0, 0.999999)
	enemy.dying = bool(entry.get("dying", false))
	enemy.death_resolved = enemy.dying
	enemy.health = 0.0 if enemy.dying else clampf(float(entry.get("health", enemy.max_health)), 1.0, enemy.max_health)
	enemy.special_phase = clampi(int(entry.get("phase", 0)), 0, 2) as Enemy.SpecialPhase
	enemy.special_timer = maxf(float(entry.get("timer", 0.0)), 0.0)
	enemy.special_direction = SnapshotValues.read_vector(entry.get("direction", [0.0, 0.0]))
	# Old saves keep the already announced direction and reveal its full path.
	enemy.charge_aim_distance = maxf(float(entry.get("charge_aim_distance", 0.0)), 0.0)
	enemy.boss_move = clampi(int(entry.get("boss_move", Enemy.BossMove.PULSE)), 0, 1) as Enemy.BossMove
	enemy.boss_charge_next = bool(entry.get("boss_charge_next", true))
	enemy.boss_dash_end = SnapshotValues.read_vector(entry.get("boss_dash_end", [0.0, 0.0]))
	enemy.boss_dash_origin = SnapshotValues.read_vector(entry.get("boss_dash_origin", [0.0, 0.0]))
	enemy.death_elapsed = clampf(float(entry.get("death_elapsed", 0.0)), 0.0, Enemy.BOSS_DEATH_DURATION)
	enemy.is_enraged = enemy.overtime_active or bool(entry.get("enraged", enemy.health <= enemy.max_health * 0.5 and enemy.data.is_boss))
	enemy.sync_inflammation_aura(0.0, enemy.death_elapsed / Enemy.BOSS_DEATH_DURATION if enemy.dying else 0.0)
	if enemy.dying:
		enemy.remove_from_group("enemies")
	enemy.affix_effects.restore(entry.get("affix_effects", {}))
	enemy.bleed_stacks = clampi(int(entry.get("bleed_stacks", 0)), 0, Enemy.MAX_BLEED_STACKS)
	enemy.bleed_dps = maxf(float(entry.get("bleed_dps", 0.0)), 0.0)
	enemy.bleed_time = maxf(float(entry.get("bleed_time", 0.0)), 0.0)
	enemy.bleed_tick = clampf(float(entry.get("bleed_tick", 1.0)), 0.0, 1.0)
	enemy.chill_time = maxf(float(entry.get("chill_time", 0.0)), 0.0)
	enemy.wet_time = maxf(float(entry.get("wet_time", 0.0)), 0.0)
	enemy.exposure_time = maxf(float(entry.get("exposure_time", 0.0)), 0.0)
	enemy.enamel_exposure = clampf(float(entry.get("enamel_exposure", 0.0)), 0.0, 0.30)
	enemy.haste_time = clampf(float(entry.get("haste_time", 0.0)), 0.0, Enemy.AURA_HASTE_DURATION)
	enemy.haste_bonus = clampf(float(entry.get("haste_bonus", 0.0)), 0.0, 1.0)
	enemy.aura_timer = clampf(float(entry.get("aura_timer", 0.0)), 0.0, Enemy.AURA_PULSE_INTERVAL)
	if enemy.data.is_elite:
		enemy.elite_damage_budget = clampf(float(entry.get("elite_damage_budget", enemy.elite_damage_budget)), 0.0, enemy.max_health * enemy.data.elite_guard_fraction)
	if enemy.data.is_boss:
		enemy.boss_phase = clampi(int(entry.get("boss_phase", 2 if enemy.health <= enemy.max_health / 3.0 else (1 if enemy.health <= enemy.max_health * 2.0 / 3.0 else 0))), 0, 2)
		enemy.boss_damage_budget = clampf(float(entry.get("boss_damage_budget", enemy.boss_damage_budget)), 0.0, enemy.max_health * enemy.data.boss_guard_burst_fraction)
		enemy.boss_phase_timer = clampf(float(entry.get("boss_phase_timer", 0.0)), 0.0, enemy.data.boss_phase_duration)
		enemy.boss_phase_burst_fired = bool(entry.get("boss_phase_burst_fired", false))
		enemy.boss_phase_gap_angle = float(entry.get("boss_phase_gap_angle", 0.0))
		enemy.boss_radial_volleys_remaining = clampi(int(entry.get("boss_radial_volleys_remaining", 0)), 0, maxi(enemy.data.boss_radial_volley_count + enemy.difficulty.boss_volley_bonus, 1))
		enemy.boss_radial_volley_timer = clampf(float(entry.get("boss_radial_volley_timer", 0.0)), 0.0, enemy.data.boss_radial_volley_interval)
		enemy.boss_radial_volley_index = clampi(int(entry.get("boss_radial_volley_index", 0)), 0, maxi(enemy.data.boss_radial_volley_count + enemy.difficulty.boss_volley_bonus, 1))
	if enemy.pillow_encounter != null:
		enemy.pillow_encounter.restore(entry.get("pillow", {}))
	if enemy.cloak_encounter != null:
		enemy.cloak_encounter.restore(entry.get("cloak", {}))
	enemy.queue_redraw()
