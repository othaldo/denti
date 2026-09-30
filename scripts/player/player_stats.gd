class_name PlayerStats
extends Node

signal changed
signal died
signal shield_blocked
signal damage_taken(amount: float)
signal healed(amount: float, overheal: float)

var max_health: float = 100.0
var health: float = 100.0
var damage: float = 18.0
var armor: float = 0.0
var move_speed: float = 230.0
var attack_interval: float = 0.65
var regen: float = 0.0
var crit_chance: float = 0.05
var luck: float = 0.0
var shield_charges: int = 0
var last_roll_critical: bool = false


func to_save_data() -> Dictionary:
	return {
		"max_health": max_health, "health": health, "damage": damage,
		"armor": armor, "move_speed": move_speed, "attack_interval": attack_interval,
		"regen": regen, "crit_chance": crit_chance, "luck": luck, "shield_charges": shield_charges,
	}


func load_save_data(saved: Dictionary) -> void:
	max_health = maxf(float(saved.get("max_health", max_health)), 1.0)
	health = clampf(float(saved.get("health", health)), 1.0, max_health)
	damage = maxf(float(saved.get("damage", damage)), 1.0)
	armor = float(saved.get("armor", armor))
	move_speed = maxf(float(saved.get("move_speed", move_speed)), 80.0)
	attack_interval = maxf(float(saved.get("attack_interval", attack_interval)), 0.18)
	regen = maxf(float(saved.get("regen", regen)), 0.0)
	crit_chance = clampf(float(saved.get("crit_chance", crit_chance)), 0.0, 0.65)
	luck = maxf(float(saved.get("luck", 0.0)), 0.0)
	shield_charges = clampi(int(saved.get("shield_charges", 0)), 0, 5)
	changed.emit()


func _process(delta: float) -> void:
	if regen > 0.0 and health > 0.0 and health < max_health:
		health = minf(health + regen * delta, max_health)
		changed.emit()


func roll_damage(multiplier: float = 1.0, bonus_crit: float = 0.0, critical_multiplier: float = 1.5, guaranteed_crit: bool = false) -> float:
	var result := damage * multiplier
	last_roll_critical = guaranteed_crit or randf() < clampf(crit_chance + bonus_crit, 0.0, 1.0)
	return result * critical_multiplier if last_roll_critical else result


func take_damage(amount: float) -> float:
	if shield_charges > 0:
		shield_charges -= 1
		changed.emit()
		shield_blocked.emit()
		return 0.0
	var before := health
	health = maxf(health - maxf(amount - armor, 1.0), 0.0)
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
		&"damage":
			damage = maxf(damage + amount, 1.0)
		&"armor":
			armor += amount
		&"max_health":
			max_health = maxf(max_health + amount, 1.0)
			health = clampf(health + amount, 1.0, max_health)
		&"move_speed":
			move_speed = maxf(move_speed + amount, 80.0)
		&"attack_interval":
			attack_interval = maxf(attack_interval - amount, 0.18)
		&"regen":
			regen = maxf(regen + amount, 0.0)
		&"crit_chance":
			crit_chance = clampf(crit_chance + amount, 0.0, 0.65)
		&"luck":
			luck = maxf(luck + amount, 0.0)
	changed.emit()
