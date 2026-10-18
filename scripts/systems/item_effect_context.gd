class_name ItemEffectContext
extends RefCounted

signal feedback(message: String, at: Vector2, color: Color)
signal enchantment_support(kind: StringName, amount: float)
signal line_requested(from: Vector2, to: Vector2, color: Color)
signal ring_requested(at: Vector2, radius: float, color: Color)
signal puddle_requested(at: Vector2)

var player: Player
var inventory_data: ItemInventoryData
var cooldowns: Dictionary = {}


func power(kind: StringName) -> float:
	return float(inventory_data.powers.get(kind, 0.0))


func ready_proc(kind: StringName, wait: float) -> bool:
	var key := str(kind)
	if float(cooldowns.get(key, 0.0)) > 0.0:
		return false
	cooldowns[key] = wait
	return true


func announce(message: String, at: Vector2, color: Color) -> void:
	feedback.emit(message, at + Vector2(0, -35), color)


func line(from: Vector2, to: Vector2, color: Color) -> void:
	line_requested.emit(from, to, color)


func ring(at: Vector2, radius: float, color: Color) -> void:
	ring_requested.emit(at, radius, color)


func create_puddle(at: Vector2) -> void:
	puddle_requested.emit(at)
