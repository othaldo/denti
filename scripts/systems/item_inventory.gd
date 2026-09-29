class_name ItemInventory
extends Node2D

signal feedback(message: String, at: Vector2, color: Color)

const CHAIN_RANGE := 190.0
const SPLASH_RADIUS := 82.0
const THORNS_RADIUS := 110.0
const BURST_RADIUS := 145.0

@onready var player: Player = get_node("../Player")

var owned: Dictionary = {}
var powers: Dictionary = {}
var cooldowns: Dictionary = {}
var coin_fraction: float = 0.0
var xp_fraction: float = 0.0
var kill_coin_progress: int = 0
var kill_heal_progress: int = 0
var kill_burst_progress: int = 0
var burst_busy: bool = false
var flashes: Array[Dictionary] = []


func _process(delta: float) -> void:
	for key in cooldowns:
		cooldowns[key] = maxf(float(cooldowns[key]) - delta, 0.0)
	var had_flashes := not flashes.is_empty()
	for index in range(flashes.size() - 1, -1, -1):
		flashes[index]["life"] = float(flashes[index]["life"]) - delta
		if float(flashes[index]["life"]) <= 0.0:
			flashes.remove_at(index)
	if had_flashes:
		queue_redraw()


func _draw() -> void:
	for flash in flashes:
		var alpha := clampf(float(flash["life"]) / 0.25, 0.0, 1.0)
		var color := Color(flash["color"] as Color, alpha)
		if flash["kind"] == &"line":
			draw_line(flash["from"], flash["to"], color, 5.0 * alpha + 1.0)
			draw_circle(flash["to"], 7.0 * alpha, color)
		else:
			draw_arc(flash["to"], float(flash["radius"]) * (1.0 - alpha * 0.35), 0.0, TAU, 32, color, 4.0)


func count(id: StringName) -> int:
	return int(owned.get(str(id), 0))


func can_acquire(item: ShopOfferData) -> bool:
	return item != null and item.weapon_data == null and (item.max_stacks == 0 or count(item.id) < item.max_stacks)


func acquire(item: ShopOfferData) -> bool:
	if not can_acquire(item):
		return false
	var key := str(item.id)
	owned[key] = count(item.id) + 1
	for stat in item.stat_changes:
		player.stats.apply_upgrade(StringName(stat), float(item.stat_changes[stat]))
	_rebuild_powers()
	return true


func all_items() -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for template in ShopController.CATALOG:
		var copies := count(template.id)
		if template.weapon_data == null and copies > 0:
			result.append({"name": template.display_name, "count": copies, "description": template.description, "tier": template.rarity_tier})
	return result


func preferred_tags(loadout: WeaponLoadout) -> Array[StringName]:
	var result: Array[StringName] = []
	for template in ShopController.CATALOG:
		if template.weapon_data == null and count(template.id) > 0:
			for tag in template.tags:
				if not result.has(tag):
					result.append(tag)
	for weapon in loadout.equipped():
		var tag: StringName = &"ranged" if weapon.data.attack_mode == &"projectile" or weapon.data.attack_mode == &"beam" else &"melee"
		if not result.has(tag):
			result.append(tag)
		if weapon.data.damage_type == "Schnitt" and not result.has(&"bleed"):
			result.append(&"bleed")
	return result


func pickup_range() -> float:
	return Loot.MAGNET_DISTANCE + _power(&"magnet")


func on_wave_start() -> void:
	var shield := roundi(_power(&"wave_shield"))
	if shield > 0:
		var before := player.stats.shield_charges
		player.stats.grant_shield(shield, 5)
		var gained := player.stats.shield_charges - before
		if gained > 0:
			_announce("Schild +%d" % gained, player.global_position, Color(0.45, 0.85, 1.0))
			_ring(player.global_position, 42.0, Color(0.45, 0.85, 1.0))


func on_pickup(kind: StringName, amount: int) -> int:
	if kind == &"coin":
		coin_fraction += float(amount) * _power(&"coin_bonus")
		var bonus := floori(coin_fraction + 0.0001)
		coin_fraction -= float(bonus)
		if bonus > 0:
			_announce("+%d Münze" % bonus, player.global_position, Color(1.0, 0.83, 0.30))
		return bonus
	xp_fraction += float(amount) * _power(&"xp_bonus")
	var extra_xp := floori(xp_fraction + 0.0001)
	xp_fraction -= float(extra_xp)
	var heal_amount := float(amount) * _power(&"xp_heal")
	if heal_amount > 0.0 and player.stats.heal(heal_amount) > 0.0 and _ready_proc(&"xp_heal_feedback", 0.75):
		_announce("+Leben", player.global_position, Color(0.50, 1.0, 0.70))
	return extra_xp


func on_kill(at: Vector2, is_boss: bool) -> int:
	var bonus_coins := 0
	if _power(&"kill_coin") > 0.0 and not is_boss:
		kill_coin_progress += 1
		if kill_coin_progress >= 12:
			kill_coin_progress -= 12
			bonus_coins = roundi(_power(&"kill_coin"))
			_announce("+%d Münze" % bonus_coins, at, Color(1.0, 0.83, 0.30))
	if _power(&"kill_heal") > 0.0 and not is_boss:
		kill_heal_progress += 1
		if kill_heal_progress >= 8:
			kill_heal_progress -= 8
			var healed := player.stats.heal(_power(&"kill_heal"))
			if healed > 0.0:
				_announce("+%d Leben" % ceili(healed), player.global_position, Color(0.50, 1.0, 0.70))
	if _power(&"kill_burst") > 0.0 and not is_boss:
		kill_burst_progress += 1
		if kill_burst_progress >= 10 and not burst_busy:
			kill_burst_progress -= 10
			burst_busy = true
			_area_damage(at, BURST_RADIUS, _power(&"kill_burst"), null)
			_ring(at, BURST_RADIUS, Color(1.0, 0.78, 0.34))
			_announce("Zahnblitz!", at, Color(1.0, 0.85, 0.40))
			burst_busy = false
	return bonus_coins


func modify_damage(enemy: Enemy, weapon: WeaponData, base: float) -> float:
	var value := base
	if enemy.data.is_boss:
		value *= 1.0 + _power(&"boss_bonus")
	if enemy.bleed_stacks > 0:
		value *= 1.0 + _power(&"bleed_bonus")
	value *= 1.0 + minf(maxf(player.stats.armor, 0.0) * _power(&"armor_damage"), 0.60)
	return value


func on_weapon_hit(enemy: Enemy, amount: float, weapon: WeaponData, critical: bool) -> void:
	if enemy.health > 0.0 and weapon.damage_type == "Schnitt" and _power(&"bleed") > 0.0:
		enemy.apply_bleed(_power(&"bleed"), 2.5)
	if _power(&"chain") > 0.0 and (weapon.damage_type == "Wasser" or weapon.damage_type == "Licht") and float(cooldowns.get("chain", 0.0)) <= 0.0:
		var next := _nearest_other(enemy.global_position, enemy, CHAIN_RANGE)
		if next != null and _ready_proc(&"chain", 0.45):
			next.take_damage(amount * minf(_power(&"chain"), 0.9))
			_line(enemy.global_position, next.global_position, Color(0.40, 0.94, 1.0))
	if _power(&"splash") > 0.0 and weapon.attack_mode == &"projectile" and _ready_proc(&"splash", 0.65):
		_area_damage(enemy.global_position, SPLASH_RADIUS, amount * minf(_power(&"splash"), 0.8), enemy)
		_ring(enemy.global_position, SPLASH_RADIUS, Color(0.44, 0.96, 0.78))
	if critical and _power(&"crit_burst") > 0.0 and _ready_proc(&"crit_burst", 0.8):
		_area_damage(enemy.global_position, 72.0, amount * minf(_power(&"crit_burst"), 0.8), enemy)
		_ring(enemy.global_position, 72.0, Color(1.0, 0.68, 0.97))


func on_player_hurt(_at: Vector2, amount: float) -> void:
	if amount <= 0.0 or _power(&"thorns") <= 0.0 or not _ready_proc(&"thorns", 0.9):
		return
	_area_damage(player.global_position, THORNS_RADIUS, _power(&"thorns"), null)
	_ring(player.global_position, THORNS_RADIUS, Color(0.82, 0.78, 1.0))
	_announce("Keramiksplitter!", player.global_position, Color(0.82, 0.78, 1.0))


func on_shield_blocked() -> void:
	_announce("BLOCK!", player.global_position, Color(0.45, 0.85, 1.0))
	_ring(player.global_position, 48.0, Color(0.45, 0.85, 1.0))


func save_data() -> Dictionary:
	return {"owned": owned.duplicate(), "cooldowns": cooldowns.duplicate(), "coin_fraction": coin_fraction,
		"xp_fraction": xp_fraction, "kill_coin": kill_coin_progress, "kill_heal": kill_heal_progress,
		"kill_burst": kill_burst_progress}


func restore(saved: Dictionary) -> void:
	owned.clear()
	for key in saved.get("owned", {}):
		var template := ShopController.by_id(StringName(str(key)))
		if template != null and template.weapon_data == null:
			owned[str(key)] = clampi(int(saved["owned"][key]), 0, template.max_stacks if template.max_stacks > 0 else 99)
	cooldowns = saved.get("cooldowns", {}).duplicate()
	coin_fraction = clampf(float(saved.get("coin_fraction", 0.0)), 0.0, 1.0)
	xp_fraction = clampf(float(saved.get("xp_fraction", 0.0)), 0.0, 1.0)
	kill_coin_progress = clampi(int(saved.get("kill_coin", 0)), 0, 11)
	kill_heal_progress = clampi(int(saved.get("kill_heal", 0)), 0, 7)
	kill_burst_progress = clampi(int(saved.get("kill_burst", 0)), 0, 10)
	_rebuild_powers()


func _rebuild_powers() -> void:
	powers.clear()
	for key in owned:
		var item := ShopController.by_id(StringName(str(key)))
		if item == null or item.effect_kind == &"":
			continue
		var effect_key := str(item.effect_kind)
		powers[effect_key] = float(powers.get(effect_key, 0.0)) + item.effect_value * int(owned[key])


func _power(effect_kind: StringName) -> float:
	return float(powers.get(str(effect_kind), 0.0))


func _ready_proc(effect_kind: StringName, wait: float) -> bool:
	var key := str(effect_kind)
	if float(cooldowns.get(key, 0.0)) > 0.0:
		return false
	cooldowns[key] = wait
	return true


func _nearest_other(at: Vector2, excluded: Enemy, radius: float) -> Enemy:
	var result: Enemy = null
	var best := radius * radius
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy == null or enemy == excluded or enemy.health <= 0.0:
			continue
		var distance := at.distance_squared_to(enemy.global_position)
		if distance < best:
			best = distance
			result = enemy
	return result


func _area_damage(at: Vector2, radius: float, amount: float, excluded: Enemy) -> void:
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and enemy != excluded and enemy.health > 0.0 and at.distance_to(enemy.global_position) <= radius + enemy.data.radius:
			enemy.take_damage(amount)


func _announce(message: String, at: Vector2, color: Color) -> void:
	feedback.emit(message, at + Vector2(0.0, -35.0), color)


func _ring(at: Vector2, radius: float, color: Color) -> void:
	flashes.append({"kind": &"ring", "to": at, "radius": radius, "color": color, "life": 0.25})
	queue_redraw()


func _line(from: Vector2, to: Vector2, color: Color) -> void:
	flashes.append({"kind": &"line", "from": from, "to": to, "color": color, "life": 0.25})
	queue_redraw()
