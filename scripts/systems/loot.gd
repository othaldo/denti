class_name Loot
extends Node2D

signal collected(kind: StringName, amount: int)

const PICKUP_DISTANCE := 27.0
const MAGNET_DISTANCE := 110.0

var kind: StringName
var amount: int
var target: Player


func configure(loot_kind: StringName, loot_amount: int, player: Player) -> void:
	kind = loot_kind
	amount = loot_amount
	target = player
	queue_redraw()


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var distance := global_position.distance_to(target.global_position)
	if distance <= PICKUP_DISTANCE:
		collected.emit(kind, amount)
		queue_free()
	elif distance <= target.items.pickup_range():
		global_position = global_position.move_toward(target.global_position, 200.0 * delta)


func _draw() -> void:
	var color := Color(0.35, 0.84, 0.96) if kind == &"xp" else Color(1.0, 0.79, 0.29)
	draw_circle(Vector2.ZERO, 8.0, Color(0.2, 0.16, 0.2))
	draw_circle(Vector2.ZERO, 6.0, color)
	draw_circle(Vector2(-2.0, -2.0), 2.0, Color.WHITE)
