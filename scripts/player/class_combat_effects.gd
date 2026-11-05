class_name ClassCombatEffects
extends RefCounted

var profile: PlayerClassData
var powers: Dictionary = {}
var opener_time := 0.0
var focus_time := 0.0
var focus_lock := 0.0
var focus_stacks := 0
var focus: WeakRef
var last_opener: WeakRef
var opener_history := false
var fallback := ClassCombatData.new()

func rules() -> ClassCombatData:
	return profile.combat_rules if profile != null and profile.combat_rules != null else fallback

func power(id: String) -> float:
	return float(powers.get(id, 0))

func reset_wave() -> void:
	opener_time = 0
	focus_time = 0
	focus_lock = 0
	focus_stacks = 0
	focus = null
	last_opener = null
	opener_history = false

func on_dash() -> void:
	if rules().opener_bonus + power("opener_bonus") > 0: opener_time = rules().opener_duration

func advance(delta: float) -> void:
	opener_time = maxf(opener_time - delta, 0)
	focus_lock = maxf(focus_lock - delta, 0)
	focus_time = maxf(focus_time - delta, 0)
	if focus_time <= 0:
		focus = null
		focus_stacks = 0

func _eligible(weapon: WeaponData) -> bool:
	return rules().opener_roles.is_empty() or rules().opener_roles.any(func(role: StringName) -> bool: return role in weapon.class_roles)

func damage_bonus(enemy: Enemy, weapon: WeaponData) -> float:
	if not _eligible(weapon): return 0
	var bonus := 0.0
	if opener_time > 0:
		bonus += rules().opener_bonus + power("opener_bonus")
		var previous := last_opener.get_ref() as Enemy if last_opener != null else null
		if opener_history and previous != enemy: bonus += power("switch_opener_bonus")
	var target := focus.get_ref() as Enemy if focus != null else null
	if target == enemy and focus_time > 0:
		bonus += focus_stacks * power("focus_bonus")
		if focus_stacks >= rules().focus_limit: bonus += power("focus_finish_bonus")
	return bonus

func after_hit(effects: ItemEffectContext, enemy: Enemy, weapon: WeaponData, tier: int, dealt: float) -> void:
	if dealt <= 0 or not _eligible(weapon): return
	if opener_time > 0:
		var previous := last_opener.get_ref() as Enemy if last_opener != null else null
		if power("switch_opener_bonus") > 0 and opener_history and previous != enemy:
			effects.enchantment_support.emit(&"class_switch_openers", 1)
		opener_time = 0
		last_opener = weakref(enemy)
		opener_history = true
		effects.enchantment_support.emit(&"class_openers", 1)
		if power("opener_poison") > 0:
			effects.poison_build.apply_depot(effects, enemy, weapon, tier, maxf(power("opener_poison"), effects.power(&"poison_depot")))
	var target := focus.get_ref() as Enemy if focus != null else null
	if target == enemy and focus_time > 0 and focus_stacks >= rules().focus_limit and power("focus_finish_bonus") > 0:
		effects.enchantment_support.emit(&"class_focus_finish_hits", 1)
	if power("focus_bonus") <= 0 or enemy.health <= 0: return
	if not is_instance_valid(target) or target.health <= 0 or focus_time <= 0:
		focus = weakref(enemy)
		focus_stacks = 0
		focus_lock = 0
		target = enemy
	if target != enemy: return
	focus_time = rules().focus_duration
	if focus_lock <= 0:
		focus_stacks = mini(focus_stacks + 1, rules().focus_limit)
		focus_lock = rules().focus_interval
		effects.enchantment_support.emit(&"class_focus_steps", 1)

func save_data(indices: Dictionary) -> Dictionary:
	var target := focus.get_ref() as Enemy if focus != null else null
	var previous := last_opener.get_ref() as Enemy if last_opener != null else null
	return {"opener_time": opener_time, "opener_history": int(opener_history), "focus_time": focus_time, "focus_lock": focus_lock, "focus_stacks": focus_stacks,
		"focus": indices.get(target.get_instance_id(), -1) if is_instance_valid(target) else -1,
		"last_opener": indices.get(previous.get_instance_id(), -1) if is_instance_valid(previous) else -1}

static func valid(saved: Dictionary) -> bool:
	for key in saved:
		if not (saved[key] is int or saved[key] is float) or not is_finite(float(saved[key])): return false
	return true

func restore(saved: Dictionary, enemies: Array[Node]) -> void:
	reset_wave()
	opener_time = clampf(float(saved.get("opener_time", 0)), 0, rules().opener_duration)
	focus_time = clampf(float(saved.get("focus_time", 0)), 0, rules().focus_duration)
	focus_lock = clampf(float(saved.get("focus_lock", 0)), 0, rules().focus_interval)
	focus_stacks = clampi(int(saved.get("focus_stacks", 0)), 0, rules().focus_limit)
	var index := int(saved.get("focus", -1))
	if index >= 0 and index < enemies.size(): focus = weakref(enemies[index])
	index = int(saved.get("last_opener", -1))
	if index >= 0 and index < enemies.size(): last_opener = weakref(enemies[index])
	opener_history = bool(saved.get("opener_history", index >= 0))
