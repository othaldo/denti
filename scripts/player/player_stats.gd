class_name PlayerStats
extends Node

signal changed
signal root_capacity_changed
signal died
signal shield_blocked
signal damage_taken(amount: float)
signal healed(amount: float, overheal: float)
signal dodged
signal status_damage_taken(kind: DentiStatus.Type, amount: float)

const STAT_MODEL_VERSION := 3
const TEMPO_MODEL_VERSION := 2
const LEGACY_BASE_DAMAGE := 18.0
const ARMOR_EFFECTIVE_HP_PER_POINT := 1.0 / 15.0
const BASE_MOVE_SPEED := 230.0
const MIN_MOVE_SPEED := 80.0
const BASE_ATTACK_INTERVAL := 0.65
const REGEN_INTERVAL_SCALE := 11.25
const REGEN_POINT_OFFSET := 1.25
const LEGACY_REGEN_POINT_FACTOR := 2.0
const MAX_DODGE_CHANCE := PlayerStatKeys.DEFAULT_DODGE_LIMIT
const MAX_CRIT_CHANCE := PlayerStatKeys.DEFAULT_CRIT_LIMIT
const DEFAULT_ROOT_CAPACITY := 6
const DASH_CONFIG: DashData = preload("res://data/player/dash.tres")

var _raw_values: Dictionary = {"max_health": 100.0, "damage_bonus": 0.0, "melee_damage": 0.0, "ranged_damage": 0.0, "armor": 0.0, "speed_bonus": 0.0, "attack_speed": 0.0, "regen": 0.0, "crit_chance": 0.05, "luck": 0.0, "dodge_chance": 0.0, "dash_recovery_bonus": 0.0}
var class_data: PlayerClassData = ClassCatalog.DEFAULT
var _class_initialized := false

@export_range(1, 64, 1, "or_greater") var root_capacity: int = DEFAULT_ROOT_CAPACITY:
	set(value):
		var normalized := maxi(value, 1)
		if root_capacity == normalized:
			return
		root_capacity = normalized
		root_capacity_changed.emit()
		changed.emit()

var max_health: float:
	get: return _effective(&"max_health")
	set(value): _raw_values["max_health"] = value if is_finite(value) else 0.0
var health: float = 100.0
var damage_bonus: float:
	get: return _effective(&"damage_bonus")
	set(value): _raw_values["damage_bonus"] = value if is_finite(value) else 0.0
var melee_damage: float:
	get: return _effective(&"melee_damage")
	set(value): _raw_values["melee_damage"] = value if is_finite(value) else 0.0
var ranged_damage: float:
	get: return _effective(&"ranged_damage")
	set(value): _raw_values["ranged_damage"] = value if is_finite(value) else 0.0
var armor: float:
	get: return _effective(&"armor")
	set(value): _raw_values["armor"] = value if is_finite(value) else 0.0
var speed_bonus: float:
	get: return _effective(&"speed_bonus")
	set(value): _raw_values["speed_bonus"] = value if is_finite(value) else 0.0
var attack_speed: float:
	get: return _effective(&"attack_speed")
	set(value): _raw_values["attack_speed"] = value if is_finite(value) else 0.0
var move_speed: float:
	get:
		return maxf(BASE_MOVE_SPEED * (1.0 + speed_bonus / 100.0), MIN_MOVE_SPEED)
var attack_interval: float:
	get:
		return attack_interval_with_bonus(0.0)
var regen: float:
	get: return _effective(&"regen")
	set(value): _raw_values["regen"] = value if is_finite(value) else 0.0
var regen_progress: float = 0.0
var crit_chance: float:
	get: return _effective(&"crit_chance")
	set(value): _raw_values["crit_chance"] = value if is_finite(value) else 0.0
var luck: float:
	get: return _effective(&"luck")
	set(value): _raw_values["luck"] = value if is_finite(value) else 0.0
var shield_charges: int = 0
var dodge_chance: float:
	get: return _effective(&"dodge_chance")
	set(value): _raw_values["dodge_chance"] = value if is_finite(value) else 0.0
var dodge_rng := RandomNumberGenerator.new()
var last_roll_critical: bool = false
# Legacy save/resource key; now additive stamina points, not a percentage.
var dash_recovery_bonus: float:
	get: return _effective(&"dash_recovery_bonus")
	set(value): _raw_values["dash_recovery_bonus"] = value if is_finite(value) else 0.0


func _init() -> void:
	dodge_rng.randomize()


func _ready() -> void:
	if _class_initialized: return
	# Initialize profiles once, while preserving an explicit challenge root limit.
	var configured_roots := root_capacity
	begin_class(class_data)
	if configured_roots != DEFAULT_ROOT_CAPACITY: root_capacity = configured_roots


func begin_class(profile: PlayerClassData) -> bool:
	if _class_initialized or profile == null or not profile.valid(): return false
	var full := health >= max_health
	class_data = profile
	root_capacity = profile.root_capacity
	for key in profile.starting_stats:
		_raw_values[str(key)] = raw_stat(StringName(str(key))) + float(profile.starting_stats[key])
	_class_initialized = true
	health = max_health if full else minf(health, max_health)
	changed.emit()
	return true


func raw_stat(stat: StringName) -> float:
	return float(_raw_values.get(str(stat), 0.0))


func _effective(stat: StringName) -> float:
	return class_data.effective(_raw_values, stat) if not class_data.stat_rules.is_empty() or not class_data.conversions.is_empty() else raw_stat(stat)


func class_save_data() -> Dictionary:
	return {"id": str(class_data.id), "version": class_data.rules_version, "raw_stats": _raw_values.duplicate()}


func maximum_for(stat: StringName) -> float:
	var rule := class_data.rule_for(stat)
	return rule.maximum if rule != null and rule.has_maximum else INF


func preview_upgrade(stat: StringName, amount: float) -> float:
	var values := _raw_values.duplicate()
	values[str(stat)] = _upgraded_raw(stat, amount)
	return class_data.effective(values, stat)


func _with_temporary_bonus(stat: StringName, amount: float) -> float:
	# Ordinary attacks must not allocate a preview dictionary on every hit.
	if is_zero_approx(amount): return _effective(stat)
	if class_data.stat_rules.is_empty() and class_data.conversions.is_empty(): return raw_stat(stat) + amount
	return preview_upgrade(stat, amount)


func _upgraded_raw(stat: StringName, amount: float) -> float:
	var rule := class_data.rule_for(stat)
	var result := raw_stat(stat) + (rule.contribution(amount) if rule != null else amount)
	# Preserve legacy acquisition rules where no explicit class boundary exists.
	if stat == &"max_health": result = maxf(result, 1.0)
	if stat == &"crit_chance" and (rule == null or not rule.has_maximum): result = clampf(result, 0.0, MAX_CRIT_CHANCE)
	if stat == &"luck" and (rule == null or not rule.has_minimum): result = maxf(result, 0.0)
	return result


func upgrade_has_effect(stat: StringName, amount: float) -> bool:
	if not _raw_values.has(str(stat)): return false
	var after := preview_upgrade(stat, amount)
	if stat == &"dodge_chance": return not is_equal_approx(effective_dodge_chance(), clampf(after, 0, dodge_limit()))
	if stat == &"dash_recovery_bonus": return not is_equal_approx(stamina_bonus(), clampf(after, 0, class_data.dash_config().max_stamina_bonus))
	return not is_equal_approx(_effective(stat), after)


func to_save_data() -> Dictionary:
	return {
		"stat_model_version": STAT_MODEL_VERSION,
		"root_capacity": root_capacity,
		"max_health": max_health, "health": health, "damage_bonus": damage_bonus,
		"melee_damage": melee_damage, "ranged_damage": ranged_damage,
		"armor": armor, "speed_bonus": speed_bonus, "attack_speed": attack_speed,
		"regen": regen, "regen_progress": regen_progress,
		"crit_chance": crit_chance, "luck": luck, "shield_charges": shield_charges,
		"dodge_chance": dodge_chance,
		"dash_recovery_bonus": dash_recovery_bonus,
	}


func load_save_data(saved: Dictionary, class_state: Dictionary = {}) -> bool:
	if not ClassCatalog.valid_state(class_state): return false
	class_data = ClassCatalog.DEFAULT if class_state.is_empty() else ClassCatalog.by_id(StringName(class_state.id))
	root_capacity = int(saved.get("root_capacity", DEFAULT_ROOT_CAPACITY))
	max_health = maxf(float(saved.get("max_health", max_health)), 1.0)
	health = clampf(float(saved.get("health", health)), 1.0, max_health)
	var saved_version := int(saved.get("stat_model_version", 1))
	if saved_version < STAT_MODEL_VERSION:
		damage_bonus = (maxf(float(saved.get("damage", LEGACY_BASE_DAMAGE)), 1.0) / LEGACY_BASE_DAMAGE - 1.0) * 100.0
		melee_damage = 0.0
		ranged_damage = 0.0
	else:
		damage_bonus = float(saved.get("damage_bonus", 0.0))
		melee_damage = float(saved.get("melee_damage", 0.0))
		ranged_damage = float(saved.get("ranged_damage", 0.0))
	armor = float(saved.get("armor", armor))
	if saved_version < TEMPO_MODEL_VERSION:
		# Preserve existing movement/attack rates; old HP/s become two regen points.
		speed_bonus = (maxf(float(saved.get("move_speed", BASE_MOVE_SPEED)), MIN_MOVE_SPEED) / BASE_MOVE_SPEED - 1.0) * 100.0
		var old_interval := maxf(float(saved.get("attack_interval", BASE_ATTACK_INTERVAL)), 0.18)
		attack_speed = (BASE_ATTACK_INTERVAL / old_interval - 1.0) * 100.0 if old_interval <= BASE_ATTACK_INTERVAL else (1.0 - old_interval / BASE_ATTACK_INTERVAL) * 100.0
		regen = maxf(float(saved.get("regen", 0.0)), 0.0) * LEGACY_REGEN_POINT_FACTOR
		regen_progress = 0.0
	else:
		speed_bonus = float(saved.get("speed_bonus", 0.0))
		attack_speed = float(saved.get("attack_speed", 0.0))
		regen = float(saved.get("regen", 0.0))
		regen_progress = clampf(float(saved.get("regen_progress", 0.0)), 0.0, 0.999999)
	crit_chance = clampf(float(saved.get("crit_chance", crit_chance)), 0.0, MAX_CRIT_CHANCE)
	luck = maxf(float(saved.get("luck", 0.0)), 0.0)
	shield_charges = clampi(int(saved.get("shield_charges", 0)), 0, 5)
	dodge_chance = float(saved.get("dodge_chance", 0.0))
	dash_recovery_bonus = float(saved.get("dash_recovery_bonus", 0.0))
	if not class_state.is_empty(): _raw_values.assign(class_state.raw_stats)
	health = clampf(float(saved.get("health", health)), 1.0, max_health)
	_class_initialized = true
	changed.emit()
	return true


func stamina_bonus() -> float:
	return clampf(dash_recovery_bonus, 0, class_data.dash_config().max_stamina_bonus)


func max_stamina() -> float:
	return class_data.dash_config().capacity + stamina_bonus()


func stamina_text() -> String:
	var config := class_data.dash_config()
	return "%.0f Wurzelkraft · %.2f/s · %.1f s Auffüllzeit%s" % [max_stamina(), config.recharge_rate, config.refill_time(max_stamina()), " (max.)" if dash_recovery_bonus >= minf(config.max_stamina_bonus, maximum_for(&"dash_recovery_bonus")) else ""]


func _process(delta: float) -> void:
	if regen <= 0.0 or health <= 0.0 or health >= max_health:
		regen_progress = 0.0
		return
	regen_progress += regen_per_second() * delta
	var ticks := floori(regen_progress + 0.000001)
	if ticks > 0:
		regen_progress = maxf(regen_progress - float(ticks), 0.0)
		# Passive regeneration never banks overhealing for free shields.
		heal(minf(float(ticks), max_health - health))
		if health >= max_health:
			regen_progress = 0.0


func regen_per_second() -> float:
	return (regen + REGEN_POINT_OFFSET) / REGEN_INTERVAL_SCALE if regen > 0.0 else 0.0


func attack_interval_with_bonus(temporary_bonus: float) -> float:
	var total := _with_temporary_bonus(&"attack_speed", temporary_bonus)
	# Negative bonuses lengthen the cooldown without a singularity at -100%.
	return BASE_ATTACK_INTERVAL / (1.0 + total / 100.0) if total >= 0.0 else BASE_ATTACK_INTERVAL * (1.0 - total / 100.0)


func regen_text() -> String:
	var points := str(roundi(regen)) if is_equal_approx(regen, roundf(regen)) else "%.1f" % regen
	return "%s · %.2f HP/s" % [points, regen_per_second()]


func damage_factor(additional_bonus: float = 0.0) -> float:
	return maxf(1.0 + _with_temporary_bonus(&"damage_bonus", additional_bonus) / 100.0, 0.0)


func scale_damage(base_damage: float, additional_bonus: float = 0.0) -> float:
	return maxf(base_damage * damage_factor(additional_bonus), 1.0)


func roll_critical_damage(base_damage: float, bonus_crit: float = 0.0, critical_multiplier: float = 1.5, guaranteed_crit: bool = false) -> float:
	last_roll_critical = guaranteed_crit or randf() < clampf(crit_chance + bonus_crit, 0.0, 1.0)
	return base_damage * critical_multiplier if last_roll_critical else base_damage


func armor_damage_factor() -> float:
	var protection := 1.0 / (1.0 + absf(armor) * ARMOR_EFFECTIVE_HP_PER_POINT)
	return protection if armor >= 0.0 else 2.0 - protection


func armor_text() -> String:
	return "%.0f · %+.0f %% Schaden" % [armor, (armor_damage_factor() - 1.0) * 100.0]


func effective_dodge_chance() -> float:
	# Keep the raw bonus so later penalties still apply above the effective cap.
	return clampf(dodge_chance, 0.0, dodge_limit())


func dodge_limit() -> float:
	var maximum := maximum_for(&"dodge_chance")
	return maximum if is_finite(maximum) else MAX_DODGE_CHANCE


func take_damage(amount: float, can_dodge: bool = true) -> float:
	if health <= 0.0 or amount <= 0.0:
		return 0.0
	var chance := effective_dodge_chance()
	if can_dodge and chance > 0.0 and dodge_rng.randf() < chance:
		dodged.emit()
		return 0.0
	if shield_charges > 0:
		shield_charges -= 1
		changed.emit()
		shield_blocked.emit()
		return 0.0
	return _lose_health(maxf(amount * armor_damage_factor(), 1.0))


func take_status_damage(amount: float, kind: DentiStatus.Type) -> float:
	# An existing ailment cannot be dodged or consume shield charges/i-frames.
	# Fractional ticks keep their actual value instead of the direct-hit floor.
	if health <= 0.0 or amount <= 0.0:
		return 0.0
	return _lose_health(amount * (1.0 if kind == DentiStatus.Type.POISON else armor_damage_factor()), kind)


func _lose_health(amount: float, status_kind: int = -1) -> float:
	var before := health
	health = maxf(health - amount, 0.0)
	changed.emit()
	damage_taken.emit(before - health)
	if status_kind >= 0:
		status_damage_taken.emit(status_kind as DentiStatus.Type, before - health)
	if health <= 0.0:
		died.emit()
	return before - health


func heal(amount: float) -> float:
	var before := health
	var requested := maxf(amount, 0.0)
	health = minf(health + requested, max_health)
	if health > before:
		changed.emit()
	if requested > 0.0:
		healed.emit(health - before, maxf(requested - (health - before), 0.0))
	return health - before


func grant_shield(charges: int, cap: int = 5) -> void:
	shield_charges = mini(shield_charges + maxi(charges, 0), cap)
	changed.emit()


func apply_upgrade(stat: StringName, amount: float) -> void:
	if not _raw_values.has(str(stat)) or not is_finite(amount): return
	var before_health := max_health
	_raw_values[str(stat)] = _upgraded_raw(stat, amount)
	# A capped max-HP purchase must not heal by its discarded raw contribution.
	if stat == &"max_health": health = clampf(health + max_health - before_health, 1.0, max_health)
	else: health = minf(health, max_health)
	changed.emit()
