class_name NecrodentSkills
extends ClassSkillModule

## The tree owns the size of the retinue. Falling over only rests a member.
const TOOTH := preload("res://assets/denti/denti_unarmed.png")
const MINT := Color(0.58, 1.0, 0.76)
const MAX_TEETH := 14
const WALK_SPEED := 280.0
const SEEK_RANGE := 320.0
const LEASH := 475.0
const BITE_REACH := 17.0
const BITE_INTERVAL := 0.70
const BITE_DAMAGE := 27.0
const BITES_BEFORE_REST := 8
const RECOVERY_SECONDS := 1.8
const COMMAND_SECONDS := 4.0
const RETARGET_INTERVAL := 0.16

class Tooth:
	var at: Vector2
	var target: Enemy
	var cooldown := 0.0
	var recovery := 0.0
	var bites := 0
	var streak := 0
	var lunge := 0.0

var teeth: Array[Tooth] = []
var marked: Enemy
var command_left := 0.0
var guard_left := 0.0
var retarget_left := 0.0
var dance_time := 0.0


func _ready() -> void:
	super._ready()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR


func class_id() -> StringName:
	return ClassCatalog.NECRODENT_ID


func retinue_size() -> int:
	return clampi(1 + roundi(power("necro_teeth")), 1, MAX_TEETH)


func reset_wave() -> void:
	super.reset_wave()
	teeth.clear()
	marked = null
	command_left = 0.0
	guard_left = 0.0
	retarget_left = 0.0
	if active(): _prepare_retinue()


func _prepare_retinue() -> void:
	var count := retinue_size()
	if teeth.size() > count:
		teeth.resize(count)
	while teeth.size() < count:
		var tooth := Tooth.new()
		tooth.at = _formation(teeth.size())
		tooth.cooldown = (teeth.size() % 4) * 0.07
		teeth.append(tooth)


func _formation(index: int) -> Vector2:
	return player.global_position + Vector2.from_angle(index * 2.4 + 1.5) * (25.0 + 9.0 * (index % 4))


func _staff() -> WeaponInstance:
	var equipped := player.loadout.equipped()
	return equipped[0] if not equipped.is_empty() and equipped[0].data.id == &"extraction_staff" else null


func on_dash_ended(_start: Vector2, end: Vector2) -> void:
	if not active() or not player.combat_active(): return
	var staff := _staff()
	if staff == null: return
	var next := nearest_enemy(end, staff.data.range_at_tier(staff.tier))
	if not is_instance_valid(marked) or next != marked:
		for tooth in teeth: tooth.streak = 0
	marked = next
	command_left = COMMAND_SECONDS if marked != null else 0.0
	guard_left = 2.0 + power("necro_guard_duration") if power("necro_guard") > 0.0 else 0.0
	retarget_left = 0.0
	if marked != null:
		staff.aim_at(marked.global_position)
		beam(staff.muzzle_position(), marked.global_position, MINT)
		flash(marked.global_position, 25.0, MINT)
	elif guard_left > 0.0:
		flash(end, 42.0, MINT)


func advance(delta: float) -> void:
	if not active():
		if not teeth.is_empty(): reset_wave()
		return
	if teeth.is_empty(): _prepare_retinue()
	dance_time = fmod(dance_time + delta, TAU)
	command_left = maxf(command_left - delta, 0.0)
	guard_left = maxf(guard_left - delta, 0.0)
	retarget_left -= delta
	if not _usable(marked) or command_left <= 0.0:
		marked = null
	if retarget_left <= 0.0:
		retarget_left = RETARGET_INTERVAL
		_assign_targets()
	var staff := _staff()
	for index in teeth.size():
		_advance_tooth(teeth[index], index, staff, delta)
	super.advance(delta)


func _usable(enemy: Variant) -> bool:
	return is_instance_valid(enemy) and enemy.is_targetable()


func _assign_targets() -> void:
	var claimed: Array[Enemy] = []
	var swarm := power("necro_swarm") > 0.0
	var guard := guard_left > 0.0
	var origin := player.global_position
	var radius := 72.0 if guard else SEEK_RANGE
	var nearby: Array[Enemy] = []
	if swarm or guard: nearby = player.nearby_enemies(origin, radius)
	var default_target := marked
	if not guard and not swarm and default_target == null:
		default_target = nearest_enemy(origin, radius)
	for tooth in teeth:
		if tooth.recovery > 0.0: continue
		var next := default_target
		if guard or swarm and marked == null:
			next = _choose_target(nearby, tooth.at, claimed, swarm)
		if not is_instance_valid(tooth.target) or next != tooth.target:
			if swarm and is_instance_valid(tooth.target) and tooth.target.health <= 0.0:
				tooth.cooldown = minf(tooth.cooldown, 0.12)
				tooth.lunge = 0.32
			tooth.streak = 0
			tooth.target = next
		if next != null: claimed.append(next)


func _choose_target(candidates: Array[Enemy], at: Vector2, claimed: Array[Enemy], spread: bool) -> Enemy:
	var best: Enemy
	var best_score := INF
	for enemy: Enemy in candidates:
		if not _usable(enemy): continue
		var score := at.distance_squared_to(enemy.global_position)
		if spread and enemy in claimed: score += SEEK_RANGE * SEEK_RANGE
		if score < best_score:
			best_score = score
			best = enemy
	return best


func _advance_tooth(tooth: Tooth, index: int, staff: WeaponInstance, delta: float) -> void:
	if tooth.recovery > 0.0:
		var recovery_rate := 2.0 if guard_left > 0.0 and power("necro_guard_revive") > 0.0 else 1.0
		tooth.recovery = maxf(tooth.recovery - delta * recovery_rate, 0.0)
		if tooth.recovery <= 0.0: _revive(tooth, index)
		return
	tooth.cooldown = maxf(tooth.cooldown - delta, 0.0)
	tooth.lunge = maxf(tooth.lunge - delta, 0.0)
	var destination := _formation(index)
	var speed := WALK_SPEED + power("necro_speed")
	if tooth.lunge > 0.0: speed *= 1.7
	if tooth.at.distance_squared_to(player.global_position) > LEASH * LEASH:
		tooth.target = null
		speed *= 1.6
	var target := tooth.target
	if _usable(target):
		var reach := target.data.radius + BITE_REACH
		destination = target.global_position + Vector2.from_angle(index * 2.4) * (reach - 4.0)
		if tooth.cooldown <= 0.0 and tooth.at.distance_squared_to(target.global_position) <= reach * reach:
			_bite(tooth, target, staff)
	tooth.at = tooth.at.move_toward(destination, speed * delta)


func _bite(tooth: Tooth, enemy: Enemy, staff: WeaponInstance) -> void:
	var factor := 1.0
	if power("necro_small") > 0.0: factor *= 0.8
	if power("necro_heavy") > 0.0: factor *= 1.42
	if enemy == marked and power("necro_focus") > 0.0:
		factor *= 1.0 + minf(tooth.streak * 0.12, 0.60) * (1.0 + power("necro_focus_power"))
	var data := staff.data if staff != null else WeaponCatalog.EXTRACTION_STAFF
	var raw := (BITE_DAMAGE + player.stats.melee_damage) * factor
	var value := items().modify_damage(enemy, data, raw)
	var damage := player.stats.roll_critical_damage(value, data.crit_bonus, data.crit_multiplier)
	var critical := player.stats.last_roll_critical
	var direction := tooth.at.direction_to(enemy.global_position)
	var packets: Array[Dictionary] = []
	var affix_share := 1.0 / maxf(float(teeth.size()) * 0.7, 1.0)
	if staff != null:
		packets = WeaponEnchantmentEffects.packets(items().effect_context, enemy, data, staff.affixes, affix_share)
	if power("necro_bleeding") > 0.0:
		var dps := scaled(2.0 + items().power(&"bleed"))
		enemy.apply_bleed(dps, 2.0 + items().power(&"bleed_clock"), 3 + roundi(items().power(&"bleed_clock")))
	var was_chilled := enemy.chill_time > 0.0
	var dealt := enemy.take_damage(damage, null, critical, &"class_necrodent_bite", packets, direction)
	if dealt > 0.0:
		items().on_weapon_hit(enemy, dealt, data, critical)
		if staff != null:
			WeaponEnchantmentEffects.after_hit(items().effect_context, enemy, data, staff.affixes, critical, dealt, affix_share, was_chilled, staff.instance_uid, staff.tier)
			if _usable(enemy):
				enemy.global_position += direction * data.knockback_at_tier(staff.tier) * (1.0 - enemy.data.knockback_resistance)
		flash(tooth.at.lerp(enemy.global_position, 0.48), 13.0, MINT)
	tooth.streak = mini(tooth.streak + 1, 5)
	tooth.bites += 1
	var tempo := data.interval / WeaponCatalog.EXTRACTION_STAFF.interval
	var interval := BITE_INTERVAL * tempo * player.stats.attack_interval / PlayerStats.BASE_ATTACK_INTERVAL
	if power("necro_heavy") > 0.0: interval *= 1.15
	tooth.cooldown = maxf(interval * items().attack_interval_factor(), 0.19)
	if tooth.bites >= BITES_BEFORE_REST:
		tooth.recovery = RECOVERY_SECONDS
		tooth.streak = 0
		tooth.target = null
	elif enemy.health <= 0.0 and power("necro_swarm") > 0.0:
		tooth.cooldown = 0.12
		tooth.lunge = 0.32
		retarget_left = 0.0


func _revive(tooth: Tooth, index: int) -> void:
	tooth.at = _formation(index)
	tooth.bites = 0
	tooth.recovery = 0.0
	flash(tooth.at, 18.0, MINT)


func _draw() -> void:
	if not active(): return
	for index in teeth.size():
		var tooth := teeth[index]
		var at := to_local(tooth.at)
		draw_circle(at + Vector2(0, 8), 7.0, Color(0.14, 0.12, 0.12, 0.38), true, -1.0, true)
		if tooth.recovery > 0.0:
			draw_texture_rect(TOOTH, Rect2(at - Vector2(11, 0), Vector2(22, 10)), false, Color(0.55, 0.65, 0.60, 0.55))
		else:
			var bob := sin(dance_time * 9.0 + index * 1.9) * 2.1
			draw_texture_rect(TOOTH, Rect2(at - Vector2(15, 17 + bob), Vector2(30, 30)), false, Color(0.62, 0.92, 0.76))
	if _usable(marked):
		var at := to_local(marked.global_position) + Vector2(0, -marked.data.radius - 17.0)
		draw_colored_polygon(PackedVector2Array([at + Vector2(-6, -6), at + Vector2(6, -6), at + Vector2(0, 1)]), MINT)
	draw_effects()


func save_with_enemies(indices: Dictionary) -> Dictionary:
	if not active(): return {}
	var members: Array[Dictionary] = []
	for tooth in teeth:
		members.append({"at": [tooth.at.x, tooth.at.y], "bite": tooth.cooldown, "rest": tooth.recovery,
			"bites": tooth.bites, "streak": tooth.streak,
			"target": _enemy_index(tooth.target, indices), "lunge": tooth.lunge})
	return {"teeth": members, "mark": _enemy_index(marked, indices), "command": command_left, "guard": guard_left, "retarget": retarget_left}


func _enemy_index(enemy: Variant, indices: Dictionary) -> int:
	return int(indices.get(enemy.get_instance_id(), -1)) if is_instance_valid(enemy) else -1


func restore_with_enemies(saved: Dictionary, enemies: Array[Node]) -> void:
	reset_wave()
	if not active(): return
	var members: Variant = saved.get("teeth", [])
	if members is Array:
		for index in mini(teeth.size(), members.size()):
			if not members[index] is Dictionary: continue
			var entry: Dictionary = members[index]
			var tooth := teeth[index]
			tooth.at = SnapshotValues.read_vector(entry.get("at", [tooth.at.x, tooth.at.y]))
			tooth.cooldown = clampf(float(entry.get("bite", 0.0)), 0.0, 5.0)
			tooth.recovery = clampf(float(entry.get("rest", 0.0)), 0.0, RECOVERY_SECONDS)
			tooth.bites = clampi(int(entry.get("bites", 0)), 0, BITES_BEFORE_REST)
			tooth.streak = clampi(int(entry.get("streak", 0)), 0, 5)
			tooth.target = _restore_enemy(entry.get("target", -1), enemies)
			tooth.lunge = clampf(float(entry.get("lunge", 0.0)), 0.0, 0.32)
	marked = _restore_enemy(saved.get("mark", -1), enemies)
	command_left = clampf(float(saved.get("command", 0.0)), 0.0, COMMAND_SECONDS)
	guard_left = clampf(float(saved.get("guard", 0.0)), 0.0, 4.0)
	retarget_left = clampf(float(saved.get("retarget", 0.0)), 0.0, RETARGET_INTERVAL)
	queue_redraw()


func _restore_enemy(value: Variant, enemies: Array[Node]) -> Enemy:
	var index := int(value)
	return enemies[index] as Enemy if index >= 0 and index < enemies.size() else null
