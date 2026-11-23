class_name NecrodentSkills
extends ClassSkillModule

## The tree owns the size of the retinue. Falling over only rests a member.
const RETINUE_ATLAS: Texture2D = preload("res://assets/classes/necrodent_retinue.png")
const ROLE_ATLAS: Texture2D = preload("res://assets/classes/necrodent_tooth_roles.png")
enum Pose { IDLE, STEP, BITE, DOWN }
enum Kind { MILK, MOLAR, GUARD }
const TOOTH_FRAMES: Array[Rect2] = [
	Rect2(134, 99, 415, 428), Rect2(763, 95, 417, 434),
	Rect2(133, 634, 417, 476), Rect2(735, 766, 469, 344),
]
const TOOTH_SCALE := 0.079
const ROLE_FRAMES: Array[Rect2] = [
	Rect2(46, 74, 357, 341), Rect2(488, 75, 354, 339), Rect2(928, 59, 359, 356), Rect2(1354, 151, 392, 273),
	Rect2(85, 483, 285, 357), Rect2(524, 480, 280, 359), Rect2(964, 476, 284, 364), Rect2(1365, 572, 359, 279),
]
const TOOTH_NAMES := ["Milchzahn", "Backenzahn", "Wachzahn"]
const BASE_SCHMELZ := [75.0, 100.0, 140.0]
const BASE_BITE := [32.0, 38.0, 28.0]
const TOOTH_CONTACT_RADIUS := 16.0
const CONTACT_INTERVAL := 0.8
const CONTACT_SCAN_INTERVAL := 0.12
const SNAP_SECONDS := 0.18
const MINT := Color(0.58, 1.0, 0.76)
const FOCUS_GOLD := Color(1.0, 0.82, 0.51)
const MAX_TEETH := 19
const WALK_SPEED := 280.0
const SEEK_RANGE := 320.0
const LEASH := 475.0
const BITE_REACH := 17.0
const BITE_INTERVAL := 0.70
const RECOVERY_SECONDS := 1.3
const COMMAND_SECONDS := 4.0
const RETARGET_INTERVAL := 0.16
const ESCORT_RANGE := 72.0
const LEASH_BUFFER := 40.0
const CROWD_DISTANCE := 76.0
const TARGET_HOLD_DISTANCE := 34.0
const SWARM_LUNGE := 0.32
const SWARM_BITE_DELAY := 0.12

class Tooth:
	var at: Vector2
	var target: Enemy
	var cooldown := 0.0
	var recovery := 0.0
	var kind: Kind = Kind.MILK
	var health := 0.0
	var contact_left := 0.0
	var streak := 0
	var lunge := 0.0
	var snapping := 0.0
	var walking := false
	var facing_left := false
	var heading := Vector2.RIGHT
	var emerge_left := 0.0
	var emerge_at := Vector2.ZERO

var teeth: Array[Tooth] = []
var marked: Enemy
var command_left := 0.0
var guard_left := 0.0
var retarget_left := 0.0
var dance_time := 0.0
var cast_left := 0.0
var escort_targets: Dictionary[int, Tooth] = {}


func _ready() -> void:
	super._ready()
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS


func class_id() -> StringName:
	return ClassCatalog.NECRODENT_ID


func retinue_size() -> int:
	return clampi(1 + roundi(power("necro_teeth")), 1, MAX_TEETH)


func roster_counts() -> PackedInt32Array:
	var total := retinue_size()
	var molars := clampi(roundi(power("necro_molar_teeth")), 0, total - 1)
	var guards := clampi(roundi(power("necro_guard_teeth")), 0, total - 1 - molars)
	return PackedInt32Array([total - molars - guards, molars, guards])


func tooth_max_health(kind: int) -> float:
	return maxf(BASE_SCHMELZ[kind] + (player.stats.max_health - 100.0) * 0.5, 1.0)


static func for_player(denti: Player) -> NecrodentSkills:
	if denti.stats.class_data.id != ClassCatalog.NECRODENT_ID: return null
	return denti.skill_module(ClassCatalog.NECRODENT_ID) as NecrodentSkills


func pursuit_destination(enemy: Enemy, fallback: Vector2) -> Vector2:
	if guard_left <= 0.0 or enemy.active_special_attack != EnemyData.SpecialAttack.NONE or enemy.data.is_boss or enemy.data.is_elite:
		return fallback
	var tooth: Tooth = escort_targets.get(enemy.get_instance_id())
	if tooth != null and tooth.recovery <= 0.0 and tooth.at.distance_squared_to(fallback) <= ESCORT_RANGE * ESCORT_RANGE:
		return tooth.at
	return fallback


func reset_wave() -> void:
	super.reset_wave()
	teeth.clear()
	marked = null
	command_left = 0.0
	guard_left = 0.0
	escort_targets.clear()
	retarget_left = 0.0
	cast_left = 0.0
	if active(): _prepare_retinue()


func _prepare_retinue() -> void:
	var count := retinue_size()
	var roster := roster_counts()
	if teeth.size() > count:
		teeth.resize(count)
	if teeth.size() < count: cast_left = NecrodentSummon.CAST_SECONDS
	while teeth.size() < count:
		var tooth := Tooth.new()
		if teeth.size() >= roster[0] + roster[1]: tooth.kind = Kind.GUARD
		elif teeth.size() >= roster[0]: tooth.kind = Kind.MOLAR
		tooth.health = tooth_max_health(tooth.kind)
		tooth.at = _formation(teeth.size())
		tooth.cooldown = (teeth.size() % 4) * 0.07
		tooth.emerge_at = tooth.at
		tooth.emerge_left = NecrodentSummon.RISE_SECONDS + NecrodentSummon.FIRST_DELAY + NecrodentSummon.STAGGER * (teeth.size() % 7)
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
		var element := WeaponElementVisuals.element(staff.data, staff.affixes)
		beam(staff.muzzle_position(), marked.global_position, WeaponElementVisuals.color(element, MINT))
		flash(marked.global_position, 25.0, MINT)
	elif guard_left > 0.0:
		flash(end, 42.0, MINT)


func advance(delta: float) -> void:
	if not active():
		if not teeth.is_empty(): reset_wave()
		return
	if teeth.is_empty(): _prepare_retinue()
	dance_time = fmod(dance_time + delta, TAU)
	cast_left = maxf(cast_left - delta, 0.0)
	command_left = maxf(command_left - delta, 0.0)
	guard_left = maxf(guard_left - delta, 0.0)
	retarget_left -= delta
	var staff := _staff()
	var leash := LEASH
	if staff != null: leash = maxf(leash, staff.data.range_at_tier(staff.tier) + LEASH_BUFFER)
	if not _usable(marked) or command_left <= 0.0 or player.global_position.distance_squared_to(marked.global_position) > leash * leash:
		marked = null
	if retarget_left <= 0.0:
		retarget_left = RETARGET_INTERVAL
		_assign_targets()
	for index in teeth.size():
		_advance_tooth(teeth[index], index, staff, leash, delta)
	super.advance(delta)


func _usable(enemy: Variant) -> bool:
	return is_instance_valid(enemy) and enemy.is_targetable()


func _assign_targets() -> void:
	escort_targets.clear()
	var swarm := power("necro_swarm") > 0.0
	var escort := guard_left > 0.0
	var preferred: Enemy = null if escort else marked
	var nearby := player.nearby_enemies(player.global_position, ESCORT_RANGE if escort else SEEK_RANGE)
	if preferred != null and preferred not in nearby: nearby.append(preferred)
	var bite_damage := scaled(_base_bite_damage())
	var slots: Dictionary[Enemy, int] = {}
	var assigned: Dictionary[Enemy, int] = {}
	for enemy in nearby:
		if not _usable(enemy): continue
		var expected_damage := maxf(bite_damage * (1.0 - enemy.damage_reduction), 1.0)
		# Reserve roughly one bite per tooth. A command still stops sending more
		# teeth as soon as the marked target has enough attackers.
		slots[enemy] = clampi(ceili(enemy.health / expected_damage), 1, teeth.size())
	for tooth in teeth:
		if tooth.recovery > 0.0: continue
		var next: Enemy
		if preferred != null and slots.get(preferred, 0) > assigned.get(preferred, 0):
			next = preferred
		else:
			next = _choose_target(tooth, slots, assigned, swarm)
		if next != null: assigned[next] = assigned.get(next, 0) + 1
		if escort and next != null:
			var id := next.get_instance_id()
			if not escort_targets.has(id) or tooth.kind == Kind.GUARD: escort_targets[id] = tooth
		if is_instance_valid(tooth.target) and next == tooth.target: continue
		tooth.streak = 0
		tooth.target = next


func _choose_target(tooth: Tooth, slots: Dictionary[Enemy, int], assigned: Dictionary[Enemy, int], swarm: bool) -> Enemy:
	var best: Enemy
	var best_score := INF
	for enemy in slots:
		var count: int = assigned.get(enemy, 0)
		if count >= slots[enemy]: continue
		var score := tooth.at.distance_squared_to(enemy.global_position) + count * CROWD_DISTANCE * CROWD_DISTANCE
		if swarm and count > 0: score += SEEK_RANGE * SEEK_RANGE
		if is_instance_valid(tooth.target) and enemy == tooth.target: score -= TARGET_HOLD_DISTANCE * TARGET_HOLD_DISTANCE
		if score < best_score:
			best_score = score
			best = enemy
	return best


func on_enemy_died(enemy: Enemy) -> void:
	if not active(): return
	escort_targets.erase(enemy.get_instance_id())
	var swarm := power("necro_swarm") > 0.0
	for tooth in teeth:
		if not is_instance_valid(tooth.target) or tooth.target != enemy: continue
		tooth.target = null
		tooth.streak = 0
		retarget_left = 0.0
		if swarm and tooth.recovery <= 0.0:
			tooth.cooldown = minf(tooth.cooldown, SWARM_BITE_DELAY)
			tooth.lunge = SWARM_LUNGE


func _advance_tooth(tooth: Tooth, index: int, staff: WeaponInstance, leash: float, delta: float) -> void:
	tooth.emerge_left = maxf(tooth.emerge_left - delta, 0.0)
	if tooth.recovery > 0.0:
		var recovery_rate := 2.0 if guard_left > 0.0 and power("necro_guard_revive") > 0.0 else 1.0
		tooth.recovery = maxf(tooth.recovery - delta * recovery_rate, 0.0)
		if tooth.recovery <= 0.0: _revive(tooth, index)
		return
	_check_contact(tooth, delta)
	if tooth.recovery > 0.0: return
	tooth.cooldown = maxf(tooth.cooldown - delta, 0.0)
	tooth.lunge = maxf(tooth.lunge - delta, 0.0)
	tooth.snapping = maxf(tooth.snapping - delta, 0.0)
	var destination := _formation(index)
	var speed := WALK_SPEED + power("necro_speed")
	if tooth.lunge > 0.0: speed *= 1.7
	if tooth.at.distance_squared_to(player.global_position) > leash * leash:
		tooth.target = null
		speed *= 1.6
	var target := tooth.target
	if _usable(target):
		var reach := target.data.radius + BITE_REACH
		destination = target.global_position + Vector2.from_angle(index * 2.4) * (reach - 4.0)
		if tooth.cooldown <= 0.0 and tooth.at.distance_squared_to(target.global_position) <= reach * reach:
			_bite(tooth, target, staff)
	var next_position := tooth.at.move_toward(destination, speed * delta)
	var traveled := next_position - tooth.at
	tooth.walking = traveled.length_squared() > 0.04
	if tooth.walking and tooth.snapping <= 0.0:
		tooth.heading = traveled.normalized()
		if absf(tooth.heading.x) > 0.15: tooth.facing_left = tooth.heading.x < 0.0
	tooth.at = next_position


func _check_contact(tooth: Tooth, delta: float) -> void:
	tooth.contact_left = maxf(tooth.contact_left - delta, 0.0)
	if tooth.contact_left > 0.0: return
	tooth.contact_left = CONTACT_SCAN_INTERVAL
	var damage := 0.0
	for enemy in player.nearby_enemies(tooth.at, TOOTH_CONTACT_RADIUS):
		if _usable(enemy) and enemy.simulation_enabled and not enemy.data.is_boss_objective and enemy.loot_goblin == null:
			damage = maxf(damage, enemy.contact_damage)
	if damage <= 0.0: return
	tooth.contact_left = CONTACT_INTERVAL
	tooth.health = maxf(tooth.health - damage, 0.0)
	if tooth.health > 0.0: return
	tooth.recovery = RECOVERY_SECONDS
	tooth.emerge_left = 0.0
	tooth.target = null
	tooth.streak = 0
	retarget_left = 0.0


func _base_bite_damage(kind: int = Kind.MILK) -> float:
	var factor := 1.0
	if power("necro_small") > 0.0: factor *= 0.8
	if power("necro_heavy") > 0.0: factor *= 1.42
	return (BASE_BITE[kind] + player.stats.melee_damage) * factor


func bite_damage_before_target_bonuses(kind: int = Kind.MILK) -> float:
	return player.stats.scale_damage(_base_bite_damage(kind), items().base_weapon_damage_bonus())


func bite_interval(data: WeaponData) -> float:
	var tempo := data.interval / WeaponCatalog.EXTRACTION_STAFF.interval
	var interval := BITE_INTERVAL * tempo * player.stats.attack_interval / PlayerStats.BASE_ATTACK_INTERVAL
	if power("necro_heavy") > 0.0: interval *= 1.15
	return maxf(interval * items().attack_interval_factor(), 0.19)


static func enchantment_share(count: int) -> float:
	return 1.0 / maxf(float(count) * 0.7, 1.0)


func _bite(tooth: Tooth, enemy: Enemy, staff: WeaponInstance) -> void:
	var raw := _base_bite_damage(tooth.kind)
	if enemy == marked and power("necro_focus") > 0.0:
		raw *= 1.0 + minf(tooth.streak * 0.12, 0.60) * (1.0 + power("necro_focus_power"))
	var data := staff.data if staff != null else WeaponCatalog.EXTRACTION_STAFF
	var value := items().modify_damage(enemy, data, raw)
	var damage := player.stats.roll_critical_damage(value, data.crit_bonus, data.crit_multiplier)
	var critical := player.stats.last_roll_critical
	var direction := tooth.at.direction_to(enemy.global_position)
	tooth.snapping = SNAP_SECONDS
	if not direction.is_zero_approx(): tooth.heading = direction
	if absf(direction.x) > 0.15: tooth.facing_left = direction.x < 0.0
	var packets: Array[Dictionary] = []
	var affix_share := enchantment_share(teeth.size())
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
			var element := WeaponElementVisuals.element(data, staff.affixes)
			if element != &"":
				ElementImpactBatch.emit_from(enemy, element, enemy.global_position, direction, 20.0)
			WeaponEnchantmentEffects.after_hit(items().effect_context, enemy, data, staff.affixes, critical, dealt, affix_share, was_chilled, staff.instance_uid, staff.tier)
			if _usable(enemy):
				enemy.global_position += direction * data.knockback_at_tier(staff.tier) * (1.0 - enemy.data.knockback_resistance)
		var accent := FOCUS_GOLD if enemy == marked and power("necro_focus") > 0.0 else MINT
		flash(tooth.at.lerp(enemy.global_position, 0.48), 13.0, accent)
	tooth.streak = mini(tooth.streak + 1, 5)
	tooth.cooldown = bite_interval(data)
	if enemy.health <= 0.0 and power("necro_swarm") > 0.0:
		tooth.cooldown = SWARM_BITE_DELAY
		tooth.lunge = SWARM_LUNGE
		retarget_left = 0.0


func _revive(tooth: Tooth, index: int) -> void:
	tooth.at = _formation(index)
	tooth.health = tooth_max_health(tooth.kind)
	tooth.contact_left = CONTACT_INTERVAL
	tooth.recovery = 0.0
	tooth.snapping = 0.0
	tooth.walking = false
	tooth.emerge_at = tooth.at
	tooth.emerge_left = NecrodentSummon.RISE_SECONDS + NecrodentSummon.REVIVE_DELAY
	if cast_left <= 0.0: cast_left = NecrodentSummon.CAST_SECONDS


func _draw_tooth(tooth: Tooth, index: int) -> void:
	var at := to_local(tooth.at)
	var height := 1.0
	var rise := 1.0
	if tooth.emerge_left > 0.0:
		rise = 1.0 - tooth.emerge_left / NecrodentSummon.RISE_SECONDS
		var ground := to_local(tooth.emerge_at) + Vector2(0, 10)
		NecrodentSummon.draw_ground(self, ground, rise, 16.0 if tooth.kind == Kind.MILK else 21.0, index)
		# Combat stays live. A tooth that bites or takes a hit is immediately readable.
		if tooth.snapping <= 0.0 and tooth.health >= tooth_max_health(tooth.kind):
			height = smoothstep(0.01, 0.68, rise)
			if height <= 0.0: return
			at = (ground - Vector2(0, 10)).lerp(at, smoothstep(0.0, 0.85, rise))
	draw_set_transform(at + Vector2(0, 8), 0.0, Vector2(1.0, 0.45))
	draw_circle(Vector2.ZERO, 9.0, Color(0.16, 0.09, 0.19, 0.34), true, -1.0, true)
	draw_set_transform(Vector2.ZERO)
	var pose := Pose.IDLE
	var color := Color.WHITE
	var offset := Vector2(0, 10)
	offset.y -= sin(PI * smoothstep(0.35, 1.0, rise)) * 6.0
	if tooth.recovery > 0.0:
		pose = Pose.DOWN
		color = Color(0.83, 0.79, 0.86, 0.78)
	elif tooth.snapping > 0.0:
		pose = Pose.BITE
		offset += tooth.heading * sin(PI * tooth.snapping / SNAP_SECONDS) * 8.0
	elif tooth.walking:
		var step := dance_time * 12.0 + index * 1.83
		if sin(step) > 0.0: pose = Pose.STEP
		offset.y -= absf(sin(step)) * 2.4
		if tooth.lunge > 0.0:
			var trail := 13.0 * tooth.lunge / SWARM_LUNGE
			draw_line(at - tooth.heading * trail, at - tooth.heading * 3.0, Color(MINT, 0.55), 2.0, true)
	var frame := TOOTH_FRAMES[pose]
	var atlas := RETINUE_ATLAS
	var scale := TOOTH_SCALE
	if tooth.kind != Kind.MILK:
		atlas = ROLE_ATLAS
		frame = ROLE_FRAMES[(tooth.kind - 1) * 4 + pose]
		scale = 0.102
	var extent := frame.size * scale
	# Draw the crown first and uncover the roots as the tooth clears the floor.
	frame.size.y *= height
	extent.y *= height
	draw_set_transform(at + offset, 0.0, Vector2(-1.0 if tooth.facing_left else 1.0, 1.0))
	draw_texture_rect_region(atlas, Rect2(Vector2(-extent.x * 0.5, -extent.y), extent), frame, color)
	draw_set_transform(Vector2.ZERO)
	if height < 0.85: return
	var bar := Rect2(at + Vector2(-11.0, -extent.y + offset.y - 5.0), Vector2(22.0, 3.0))
	var ratio := clampf(tooth.health / tooth_max_health(tooth.kind), 0.0, 1.0)
	if tooth.recovery > 0.0: ratio = 1.0 - tooth.recovery / RECOVERY_SECONDS
	draw_rect(bar.grow(1.0), Color("292131"))
	bar.size.x *= ratio
	draw_rect(bar, Color("88b1be") if tooth.recovery > 0.0 else MINT.lerp(Color("f5877d"), 1.0 - ratio))


func _draw() -> void:
	if not active(): return
	if cast_left > 0.0:
		var staff := _staff()
		if staff != null:
			var tip := to_local(staff.muzzle_position())
			var lift := NecrodentSummon.lift(cast_left)
			NecrodentSummon.draw_focus(self, tip, lift)
			var wisps := 0
			for tooth in teeth:
				var rise := 1.0 - tooth.emerge_left / NecrodentSummon.RISE_SECONDS
				var alpha := lift * smoothstep(-0.30, 0.03, rise) * (1.0 - smoothstep(0.1, 0.40, rise))
				if alpha <= 0.0: continue
				NecrodentSummon.draw_wisp(self, tip, to_local(tooth.emerge_at) + Vector2(0, 10), alpha)
				wisps += 1
				if wisps == 3: break
	if guard_left > 0.0:
		var origin := to_local(player.global_position)
		var color := Color(MINT, 0.8 * minf(guard_left * 4.0, 1.0))
		draw_arc(origin, 41.0, 0.20, 1.10, 12, color, 2.0, true)
		draw_arc(origin, 41.0, 3.34, 4.24, 12, color, 2.0, true)
	for index in teeth.size():
		_draw_tooth(teeth[index], index)
	if _usable(marked):
		var at := to_local(marked.global_position) + Vector2(0, -marked.data.radius - 17.0)
		var accent := FOCUS_GOLD if power("necro_focus") > 0.0 else MINT
		var tip := at + Vector2(0, 1)
		var left := at + Vector2(-6, -6)
		var right := at + Vector2(6, -6)
		draw_colored_polygon(PackedVector2Array([left, right, tip]), accent)
		draw_polyline(PackedVector2Array([left, right, tip, left]), Color("432b47"), 1.5, true)
	draw_effects()


func save_with_enemies(indices: Dictionary) -> Dictionary:
	if not active(): return {}
	var members: Array[Dictionary] = []
	for tooth in teeth:
		members.append({"at": [tooth.at.x, tooth.at.y], "bite": tooth.cooldown, "rest": tooth.recovery,
			"health": tooth.health, "contact": tooth.contact_left, "streak": tooth.streak,
			"target": _enemy_index(tooth.target, indices), "lunge": tooth.lunge})
	return {"teeth": members, "mark": _enemy_index(marked, indices), "command": command_left, "guard": guard_left, "retarget": retarget_left}


func _enemy_index(enemy: Variant, indices: Dictionary) -> int:
	return int(indices.get(enemy.get_instance_id(), -1)) if is_instance_valid(enemy) else -1


func restore_with_enemies(saved: Dictionary, enemies: Array[Node]) -> void:
	reset_wave()
	if not active(): return
	cast_left = 0.0
	for tooth in teeth: tooth.emerge_left = 0.0
	var members: Variant = saved.get("teeth", [])
	if members is Array:
		for index in mini(teeth.size(), members.size()):
			if not members[index] is Dictionary: continue
			var entry: Dictionary = members[index]
			var tooth := teeth[index]
			tooth.at = SnapshotValues.read_vector(entry.get("at", [tooth.at.x, tooth.at.y]))
			tooth.cooldown = clampf(float(entry.get("bite", 0.0)), 0.0, 5.0)
			tooth.recovery = clampf(float(entry.get("rest", 0.0)), 0.0, RECOVERY_SECONDS)
			tooth.health = clampf(float(entry.get("health", tooth.health)), 0.0, tooth_max_health(tooth.kind))
			tooth.contact_left = clampf(float(entry.get("contact", 0.0)), 0.0, CONTACT_INTERVAL)
			if tooth.recovery > 0.0: tooth.health = 0.0
			tooth.streak = clampi(int(entry.get("streak", 0)), 0, 5)
			tooth.target = _restore_enemy(entry.get("target", -1), enemies)
			tooth.lunge = clampf(float(entry.get("lunge", 0.0)), 0.0, SWARM_LUNGE)
	marked = _restore_enemy(saved.get("mark", -1), enemies)
	command_left = clampf(float(saved.get("command", 0.0)), 0.0, COMMAND_SECONDS)
	guard_left = clampf(float(saved.get("guard", 0.0)), 0.0, 4.0)
	retarget_left = clampf(float(saved.get("retarget", 0.0)), 0.0, RETARGET_INTERVAL)
	queue_redraw()


func _restore_enemy(value: Variant, enemies: Array[Node]) -> Enemy:
	var index := int(value)
	return enemies[index] as Enemy if index >= 0 and index < enemies.size() else null
