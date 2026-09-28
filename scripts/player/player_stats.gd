class_name PlayerStats
extends Node

signal changed
signal died

var max_health: float = 100.0
var health: float = 100.0
var damage: float = 18.0
var armor: float = 0.0
var move_speed: float = 230.0
var attack_interval: float = 0.65
var regen: float = 0.0
var crit_chance: float = 0.05


func _process(delta: float) -> void:
	if regen > 0.0 and health > 0.0 and health < max_health:
		health = minf(health + regen * delta, max_health)
		changed.emit()


func roll_damage(multiplier: float = 1.0) -> float:
	var result := damage * multiplier
	return result * 1.5 if randf() < crit_chance else result


func take_damage(amount: float) -> void:
	health = maxf(health - maxf(amount - armor, 1.0), 0.0)
	changed.emit()
	if health <= 0.0:
		died.emit()


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
	changed.emit()
