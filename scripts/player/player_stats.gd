class_name PlayerStats
extends Node

signal changed
signal died
signal shield_blocked
signal damage_taken(amount: float)
signal healed(amount: float, overheal: float)
signal dodged

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
const MAX_DODGE_CHANCE := 0.60

var max_health: float = 100.0
var health: float = 100.0
var damage_bonus: float = 0.0
var melee_damage: float = 0.0
var ranged_damage: float = 0.0
var armor: float = 0.0
var speed_bonus: float = 0.0
var attack_speed: float = 0.0
var move_speed: float:
	get:
		return maxf(BASE_MOVE_SPEED * (1.0 + speed_bonus / 100.0), MIN_MOVE_SPEED)
var attack_interval: float:
	get:
		return attack_interval_with_bonus(0.0)
var regen: float = 0.0
var regen_progress: float = 0.0
var crit_chance: float = 0.05
var luck: float = 0.0
var shield_charges: int = 0
var dodge_chance: float = 0.0
var dodge_rng := RandomNumberGenerator.new()
var last_roll_critical: bool = false


func _init() -> void:
	dodge_rng.randomize()


func to_save_data() -> Dictionary:
	return {
		"stat_model_version": STAT_MODEL_VERSION,
		"max_health": max_health, "health": health, "damage_bonus": damage_bonus,
		"melee_damage": melee_damage, "ranged_damage": ranged_damage,
		"armor": armor, "speed_bonus": speed_bonus, "attack_speed": attack_speed,
		"regen": regen, "regen_progress": regen_progress,
		"crit_chance": crit_chance, "luck": luck, "shield_charges": shield_charges,
		"dodge_chance": dodge_chance,
	}


func load_save_data(saved: Dictionary) -> void:
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
	crit_chance = clampf(float(saved.get("crit_chance", crit_chance)), 0.0, 0.65)
	luck = maxf(float(saved.get("luck", 0.0)), 0.0)
	shield_charges = clampi(int(saved.get("shield_charges", 0)), 0, 5)
	dodge_chance = float(saved.get("dodge_chance", 0.0))
	changed.emit()


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
	var total := attack_speed + temporary_bonus
	# Negative bonuses lengthen the cooldown without a singularity at -100%.
	return BASE_ATTACK_INTERVAL / (1.0 + total / 100.0) if total >= 0.0 else BASE_ATTACK_INTERVAL * (1.0 - total / 100.0)


func regen_text() -> String:
	var points := str(roundi(regen)) if is_equal_approx(regen, roundf(regen)) else "%.1f" % regen
	return "%s · %.2f HP/s" % [points, regen_per_second()]


func damage_factor(additional_bonus: float = 0.0) -> float:
	return maxf(1.0 + (damage_bonus + additional_bonus) / 100.0, 0.0)


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
	return clampf(dodge_chance, 0.0, MAX_DODGE_CHANCE)


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
	var before := health
	health = maxf(health - maxf(amount * armor_damage_factor(), 1.0), 0.0)
	changed.emit()
	damage_taken.emit(before - health)
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
	match stat:
		&"damage_bonus":
			damage_bonus += amount
		&"melee_damage":
			melee_damage += amount
		&"ranged_damage":
			ranged_damage += amount
		&"armor":
			armor += amount
		&"max_health":
			max_health = maxf(max_health + amount, 1.0)
			health = clampf(health + amount, 1.0, max_health)
		&"speed_bonus":
			speed_bonus += amount
		&"attack_speed":
			attack_speed += amount
		&"regen":
			regen += amount
		&"crit_chance":
			crit_chance = clampf(crit_chance + amount, 0.0, 0.65)
		&"luck":
			luck = maxf(luck + amount, 0.0)
		&"dodge_chance":
			dodge_chance += amount
	changed.emit()
