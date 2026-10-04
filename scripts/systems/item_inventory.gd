class_name ItemInventory
extends Node2D

signal feedback(message: String, at: Vector2, color: Color)

const CHAIN_RANGE := 190.0
const SPLASH_RADIUS := 82.0
const THORNS_RADIUS := 110.0
const BURST_RADIUS := 145.0
const PUDDLE_RADIUS := 72.0
const PUDDLE_DURATION := 2.0
const OVERHEAL_SHIELD_THRESHOLD := 20.0
const DODGE_HEAL_COOLDOWN := 1.5
const DODGE_GUARD_COOLDOWN := 8.0
const DODGE_GUARD_THRESHOLD := 3

@onready var player: Player = get_node("../Player")
@onready var relics: RelicInventory = get_node("../Relics")

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
var puddles: Array[Dictionary] = []
var overheal_bank: float = 0.0
var sugar_kills_progress: int = 0
var sugar_rush_time: float = 0.0
var sugar_crash_time: float = 0.0
var dodge_guard_progress: int = 0
var cached_pickup_range: float = Loot.MAGNET_DISTANCE


func _process(delta: float) -> void:
	for key in cooldowns:
		cooldowns[key] = maxf(float(cooldowns[key]) - delta, 0.0)
	if sugar_rush_time > 0.0:
		sugar_rush_time = maxf(sugar_rush_time - delta, 0.0)
		if sugar_rush_time <= 0.0:
			sugar_crash_time = 3.0
			_announce("Zuckertief!", player.global_position, Color(0.94, 0.48, 0.65))
	elif sugar_crash_time > 0.0:
		sugar_crash_time = maxf(sugar_crash_time - delta, 0.0)
	var had_puddles := not puddles.is_empty()
	for index in range(puddles.size() - 1, -1, -1):
		var puddle := puddles[index]
		puddle["life"] = float(puddle["life"]) - delta
		if float(puddle["life"]) <= 0.0:
			puddles.remove_at(index)
			continue
		puddle["tick"] = float(puddle["tick"]) - delta
		if float(puddle["tick"]) <= 0.0:
			puddle["tick"] = 0.5
			_puddle_tick(puddle["at"])
	var had_flashes := not flashes.is_empty()
	for index in range(flashes.size() - 1, -1, -1):
		flashes[index]["life"] = float(flashes[index]["life"]) - delta
		if float(flashes[index]["life"]) <= 0.0:
			flashes.remove_at(index)
	if had_flashes or had_puddles:
		queue_redraw()


func _draw() -> void:
	for puddle in puddles:
		var at: Vector2 = puddle["at"]
		var fade := clampf(float(puddle["life"]) / PUDDLE_DURATION, 0.0, 1.0)
		draw_circle(at, PUDDLE_RADIUS, Color(0.18, 0.79, 0.87, 0.14 * fade))
		CombatDrawCache.arc(self, at, PUDDLE_RADIUS, 0.0, TAU, 32, Color(0.28, 0.94, 1.0, 0.50 * fade), 3.0)
	for flash in flashes:
		var alpha := clampf(float(flash["life"]) / 0.25, 0.0, 1.0)
		var color := Color(flash["color"] as Color, alpha)
		if flash["kind"] == &"line":
			draw_line(flash["from"], flash["to"], color, 5.0 * alpha + 1.0)
			draw_circle(flash["to"], 7.0 * alpha, color)
		else:
			CombatDrawCache.arc(self, flash["to"], float(flash["radius"]) * (1.0 - alpha * 0.35), 0.0, TAU, 32, color, 4.0)


func count(id: StringName) -> int:
	return int(owned.get(str(id), 0))


func can_acquire(item: ShopOfferData) -> bool:
	if item == null or item.weapon_data != null:
		return false
	if item.rarity_tier == 5 and count(item.id) > 0:
		return false
	if item.max_stacks > 0 and count(item.id) >= item.max_stacks:
		return false
	return item.family_limit == 0 or family_count(item.family_id) < item.family_limit


func family_count(family_id: StringName) -> int:
	var total := 0
	if family_id == &"":
		return total
	for template in ShopController.CATALOG:
		if template.weapon_data == null and template.family_id == family_id:
			total += count(template.id)
	return total


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
			var description := template.effect_text() + "\n" + template.limit_text()
			if template.effect_kind == &"armor_damage":
				description += "\n\n" + armor_damage_explanation()
			result.append({"name": template.display_name, "count": copies, "description": description, "tier": template.rarity_tier, "icon": template.icon_texture if template.icon_texture != null else DentiUIIcons.item(template.icon_index)})
	return result


func preferred_tags(loadout: WeaponLoadout) -> Array[StringName]:
	var result: Array[StringName] = []
	for template in ShopController.CATALOG:
		if template.weapon_data == null and count(template.id) > 0:
			for tag in template.tags:
				if not result.has(tag):
					result.append(tag)
	for weapon in loadout.equipped():
		var tag: StringName = &"ranged" if weapon.data.attack_mode in [&"projectile", &"beam", &"beam_line", &"cone"] else &"melee"
		if not result.has(tag):
			result.append(tag)
		if weapon.data.damage_type == "Schnitt" and not result.has(&"bleed"):
			result.append(&"bleed")
	return result


func pickup_range() -> float:
	return cached_pickup_range


func coin_double_chance() -> float:
	var chance := _power(&"coin_double")
	if chance <= 0.0:
		return 0.0
	return minf(chance + clampf(player.stats.luck, 0.0, 100.0) * 0.001, 0.50)


# Roll once when an enemy drops gold. Merged loot and saved loot retain this value.
# The extractor checks the enemy's base value, not a previously doubled pickup.
func coin_drop_value(base_coins: int) -> int:
	if base_coins <= 0:
		return 0
	var chance := coin_double_chance()
	var value := base_coins * (2 if chance > 0.0 and randf() < chance else 1)
	if base_coins >= 2:
		value += roundi(_power(&"rich_coin_bonus"))
	return value


func scrap_value(base_coins: int) -> int:
	return maxi(roundi(float(base_coins) * (1.0 + minf(_power(&"scrap_bonus"), 1.0))), 1)


func projectile_return_factor() -> float:
	return _power(&"projectile_return")


func attack_interval_factor() -> float:
	var temporary_bonus := 0.0
	if sugar_rush_time > 0.0:
		temporary_bonus = minf(_power(&"sugar_rush"), 0.50) * 100.0
	elif sugar_crash_time > 0.0:
		temporary_bonus = -25.0
	return player.stats.attack_interval_with_bonus(temporary_bonus) / player.stats.attack_interval


func on_wave_start() -> void:
	puddles.clear()
	sugar_kills_progress = 0
	sugar_rush_time = 0.0
	sugar_crash_time = 0.0
	queue_redraw()
	var shield := roundi(_power(&"wave_shield"))
	if shield > 0:
		var before := player.stats.shield_charges
		player.stats.grant_shield(shield, 5)
		var gained := player.stats.shield_charges - before
		if gained > 0:
			_announce("Schild +%d" % gained, player.global_position, Color(0.45, 0.85, 1.0))
			_ring(player.global_position, 42.0, Color(0.45, 0.85, 1.0))


func on_wave_end(coins: int) -> int:
	puddles.clear()
	queue_redraw()
	var stacks := count(&"interest_tooth")
	if stacks <= 0:
		return 0
	var interest := mini(floori(float(coins) * _power(&"wave_interest")), 6 * stacks)
	if interest > 0:
		_announce("Zins +%d" % interest, player.global_position, Color(1.0, 0.83, 0.30))
	return interest


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
	if _power(&"sugar_rush") > 0.0 and not is_boss and sugar_rush_time <= 0.0 and sugar_crash_time <= 0.0:
		sugar_kills_progress += 1
		if sugar_kills_progress >= 12:
			sugar_kills_progress = 0
			sugar_rush_time = 4.0
			_announce("Zuckerschock!", player.global_position, Color(1.0, 0.54, 0.71))
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
			_area_damage(at, BURST_RADIUS, player.stats.scale_damage(_power(&"kill_burst")), null, &"kill_burst")
			_ring(at, BURST_RADIUS, Color(1.0, 0.78, 0.34))
			_announce("Zahnblitz!", at, Color(1.0, 0.85, 0.40))
			burst_busy = false
	return bonus_coins


func modify_damage(enemy: Enemy, weapon: WeaponData, base: float) -> float:
	var bonus := base_weapon_damage_bonus()
	if enemy.data.is_boss:
		bonus += _power(&"boss_bonus") * 100.0
	if enemy.bleed_stacks > 0:
		bonus += _power(&"bleed_bonus") * 100.0
	if enemy.wet_time > 0.0 and (weapon.damage_type == "Wasser" or weapon.damage_type == "Licht"):
		bonus += _power(&"conductive_wet") * 100.0
	if player.is_moving:
		bonus += _power(&"moving_damage") * 100.0
	return player.stats.scale_damage(base, bonus)


func base_weapon_damage_bonus() -> float:
	return (relics.damage_factor() - 1.0) * 100.0 + armor_damage_bonus()


func armor_damage_bonus() -> float:
	return minf(maxf(player.stats.armor, 0.0) * _power(&"armor_damage"), 0.60) * 100.0


func armor_damage_explanation() -> String:
	return "Aktuell: +%s %% Waffenschaden\n%s Härte × %s %% je Härte\nMaximal +60 %%. Negative Härte gibt keinen Bonus.\nAddiert sich zu Bisskraft; ist bereits in den Waffenwerten enthalten." % [
		("%.1f" % armor_damage_bonus()).trim_suffix(".0"), ("%.1f" % player.stats.armor).trim_suffix(".0"),
		("%.1f" % (_power(&"armor_damage") * 100.0)).trim_suffix(".0")]


func on_weapon_hit(enemy: Enemy, amount: float, weapon: WeaponData, critical: bool) -> void:
	player.loadout.evolution_hit(enemy, amount, weapon, critical)
	# Copies scale damage, not proc frequency. Secondary damage has no weapon,
	# so it cannot recursively trigger these on-hit effects.
	if enemy.health > 0.0 and weapon.enamel_exposure > 0.0:
		enemy.apply_enamel_exposure(weapon.enamel_exposure, weapon.exposure_duration)
	if enemy.health > 0.0 and weapon.bleed_dps > 0.0:
		var extra_stacks := roundi(_power(&"bleed_clock"))
		enemy.apply_bleed((weapon.bleed_dps + _power(&"bleed")) * player.stats.damage_factor(), weapon.bleed_duration + _power(&"bleed_clock"), 3 + extra_stacks)
	if enemy.health > 0.0 and weapon.wet_duration > 0.0:
		enemy.apply_wet(weapon.wet_duration + (0.5 if _power(&"conductive_wet") > 0.0 else 0.0))
	if weapon.damage_type == "Wasser" and _power(&"water_puddle") > 0.0 and _ready_proc(&"water_puddle", 1.5):
		puddles.append({"at": enemy.global_position, "life": PUDDLE_DURATION, "tick": 0.0})
		if puddles.size() > 4:
			puddles.pop_front()
		queue_redraw()
	if enemy.health <= 0.0 and enemy.bleed_stacks > 0 and _power(&"bleed_spread") > 0.0 and float(cooldowns.get("bleed_spread", 0.0)) <= 0.0:
		var nearby := _nearest_other(enemy.global_position, enemy, 110.0 + _power(&"bleed_spread"))
		if nearby != null and _ready_proc(&"bleed_spread", 0.4):
			nearby.apply_bleed(enemy.bleed_dps, 2.5 + _power(&"bleed_clock"), 3 + roundi(_power(&"bleed_clock")))
			_line(enemy.global_position, nearby.global_position, Color(0.86, 0.31, 0.51))
	if _power(&"chain") > 0.0 and (weapon.damage_type == "Wasser" or weapon.damage_type == "Licht") and float(cooldowns.get("chain", 0.0)) <= 0.0:
		var chain_range := CHAIN_RANGE + (85.0 if enemy.wet_time > 0.0 else 0.0)
		var next := _nearest_other(enemy.global_position, enemy, chain_range)
		if next != null and _ready_proc(&"chain", 0.45):
			next.take_damage(amount * _power(&"chain"), null, false, &"chain")
			_line(enemy.global_position, next.global_position, Color(0.40, 0.94, 1.0))
	if _power(&"splash") > 0.0 and weapon.attack_mode == &"projectile" and _ready_proc(&"splash", 0.65):
		_area_damage(enemy.global_position, SPLASH_RADIUS, amount * _power(&"splash"), enemy, &"splash")
		_ring(enemy.global_position, SPLASH_RADIUS, Color(0.44, 0.96, 0.78))
	if critical and _power(&"crit_burst") > 0.0 and _ready_proc(&"crit_burst", 0.8):
		_area_damage(enemy.global_position, 72.0, amount * _power(&"crit_burst"), enemy, &"crit_burst")
		_ring(enemy.global_position, 72.0, Color(1.0, 0.68, 0.97))
	if critical and _power(&"crit_beam") > 0.0 and float(cooldowns.get("crit_beam", 0.0)) <= 0.0:
		var beam_target := _nearest_other(enemy.global_position, enemy, 240.0)
		if beam_target != null and _ready_proc(&"crit_beam", 0.65):
			var beam_factor := _power(&"crit_beam") * (1.5 if weapon.damage_type == "Licht" else 1.0)
			beam_target.take_damage(amount * beam_factor, null, false, &"crit_beam")
			_line(enemy.global_position, beam_target.global_position, Color(1.0, 0.88, 0.42))


func on_player_hurt(_at: Vector2, amount: float) -> void:
	if amount <= 0.0 or _power(&"thorns") <= 0.0 or not _ready_proc(&"thorns", 0.9):
		return
	_area_damage(player.global_position, THORNS_RADIUS, player.stats.scale_damage(_power(&"thorns")), null, &"thorns")
	_ring(player.global_position, THORNS_RADIUS, Color(0.82, 0.78, 1.0))
	_announce("Keramiksplitter!", player.global_position, Color(0.82, 0.78, 1.0))


func on_player_dodged() -> void:
	_announce("Zahnflutsch!", player.global_position, Color(0.50, 0.94, 1.0))
	var healing := minf(_power(&"dodge_heal"), 4.0)
	if healing > 0.0 and _ready_proc(&"dodge_heal", DODGE_HEAL_COOLDOWN):
		player.stats.heal(healing)
	# Further copies improve the stat, not shield rate or shared cooldown.
	if _power(&"dodge_guard") > 0.0 and float(cooldowns.get("dodge_guard", 0.0)) <= 0.0:
		dodge_guard_progress += 1
		if dodge_guard_progress >= DODGE_GUARD_THRESHOLD:
			dodge_guard_progress = 0
			_ready_proc(&"dodge_guard", DODGE_GUARD_COOLDOWN)
			player.stats.grant_shield(1, 5)
			_announce("Schild +1", player.global_position, Color(0.45, 0.85, 1.0))


func on_shield_blocked() -> void:
	_announce("BLOCK!", player.global_position, Color(0.45, 0.85, 1.0))
	_ring(player.global_position, 48.0, Color(0.45, 0.85, 1.0))
	if _power(&"shield_shards") > 0.0 and _ready_proc(&"shield_shards", 0.9):
		_area_damage(player.global_position, THORNS_RADIUS, player.stats.scale_damage(_power(&"shield_shards")), null, &"shield_shards")
		_ring(player.global_position, THORNS_RADIUS, Color(0.94, 0.89, 0.76))


func on_healed(_amount: float, overheal: float) -> void:
	if _power(&"overheal_shield") <= 0.0 or overheal <= 0.0:
		return
	overheal_bank += overheal * minf(_power(&"overheal_shield"), 1.0)
	while overheal_bank >= OVERHEAL_SHIELD_THRESHOLD and player.stats.shield_charges < 5:
		overheal_bank -= OVERHEAL_SHIELD_THRESHOLD
		player.stats.grant_shield(1, 5)
		_announce("Schild +1", player.global_position, Color(0.45, 0.85, 1.0))
	overheal_bank = minf(overheal_bank, OVERHEAL_SHIELD_THRESHOLD)


func save_data() -> Dictionary:
	var puddle_data: Array[Dictionary] = []
	for puddle in puddles:
		var at: Vector2 = puddle["at"]
		puddle_data.append({"x": at.x, "y": at.y, "life": puddle["life"], "tick": puddle["tick"]})
	return {"owned": owned.duplicate(), "cooldowns": cooldowns.duplicate(), "coin_fraction": coin_fraction,
		"xp_fraction": xp_fraction, "kill_coin": kill_coin_progress, "kill_heal": kill_heal_progress,
		"kill_burst": kill_burst_progress, "puddles": puddle_data, "overheal_bank": overheal_bank,
		"sugar_kills": sugar_kills_progress, "sugar_rush": sugar_rush_time, "sugar_crash": sugar_crash_time,
		"dodge_guard": dodge_guard_progress}


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
	puddles.clear()
	for entry in saved.get("puddles", []):
		if entry is Dictionary and puddles.size() < 4:
			puddles.append({"at": Vector2(float(entry.get("x", 0.0)), float(entry.get("y", 0.0))),
				"life": clampf(float(entry.get("life", 0.0)), 0.0, PUDDLE_DURATION),
				"tick": clampf(float(entry.get("tick", 0.0)), 0.0, 0.5)})
	overheal_bank = clampf(float(saved.get("overheal_bank", 0.0)), 0.0, OVERHEAL_SHIELD_THRESHOLD)
	sugar_kills_progress = clampi(int(saved.get("sugar_kills", 0)), 0, 11)
	sugar_rush_time = clampf(float(saved.get("sugar_rush", 0.0)), 0.0, 4.0)
	sugar_crash_time = clampf(float(saved.get("sugar_crash", 0.0)), 0.0, 3.0)
	dodge_guard_progress = clampi(int(saved.get("dodge_guard", 0)), 0, DODGE_GUARD_THRESHOLD - 1)
	_rebuild_powers()
	queue_redraw()


func _rebuild_powers() -> void:
	powers.clear()
	for key in owned:
		var item := ShopController.by_id(StringName(str(key)))
		if item == null or item.effect_kind == &"":
			continue
		var effect_key := str(item.effect_kind)
		powers[effect_key] = float(powers.get(effect_key, 0.0)) + item.effect_value * int(owned[key])
	cached_pickup_range = Loot.MAGNET_DISTANCE + _power(&"magnet")


func _power(effect_kind: StringName) -> float:
	return float(powers.get(str(effect_kind), 0.0))


func _ready_proc(effect_kind: StringName, wait: float) -> bool:
	var key := str(effect_kind)
	if float(cooldowns.get(key, 0.0)) > 0.0:
		return false
	cooldowns[key] = wait
	return true


func _nearest_other(at: Vector2, excluded: Enemy, radius: float) -> Enemy:
	var result := EnemySpatialIndex.nearest(get_tree(), player.enemy_index, at, radius, false, excluded)
	# These item procs have always used a strict range boundary.
	return result if result != null and at.distance_squared_to(result.global_position) < radius * radius else null


func _area_damage(at: Vector2, radius: float, amount: float, excluded: Enemy, proc_id: StringName) -> void:
	for enemy in player.nearby_enemies(at, radius):
		if enemy != excluded and enemy.health > 0.0:
			enemy.take_damage(amount, null, false, proc_id)


func _puddle_tick(at: Vector2) -> void:
	for enemy in player.nearby_enemies(at, PUDDLE_RADIUS):
		if enemy.health > 0.0:
			enemy.apply_wet(1.1)
			enemy.take_damage(player.stats.scale_damage(_power(&"water_puddle")), null, false, &"water_puddle")


func _announce(message: String, at: Vector2, color: Color) -> void:
	feedback.emit(message, at + Vector2(0.0, -35.0), color)


func _ring(at: Vector2, radius: float, color: Color) -> void:
	flashes.append({"kind": &"ring", "to": at, "radius": radius, "color": color, "life": 0.25})
	queue_redraw()


func _line(from: Vector2, to: Vector2, color: Color) -> void:
	flashes.append({"kind": &"line", "from": from, "to": to, "color": color, "life": 0.25})
	queue_redraw()
