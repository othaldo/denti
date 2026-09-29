class_name Loot
extends Node2D

signal collected(kind: StringName, amount: int, reward_id: StringName)

const PICKUP_DISTANCE := 27.0
const MAGNET_DISTANCE := 110.0
const WAVE_COLLECTION_SPEED := 620.0

var kind: StringName
var amount: int
var reward_id: StringName = &""
var target: Player
var wave_collecting: bool = false


func configure(loot_kind: StringName, loot_amount: int, player: Player, loot_reward_id: StringName = &"") -> void:
	kind = loot_kind
	amount = loot_amount
	reward_id = loot_reward_id
	target = player
	queue_redraw()


func begin_wave_collection() -> void:
	wave_collecting = true


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var distance := global_position.distance_to(target.global_position)
	if distance <= PICKUP_DISTANCE:
		queue_free()
		collected.emit(kind, amount, reward_id)
	elif wave_collecting:
		global_position = global_position.move_toward(target.global_position, maxf(WAVE_COLLECTION_SPEED, distance * 3.0) * delta)
	elif distance <= target.items.pickup_range():
		global_position = global_position.move_toward(target.global_position, 200.0 * delta)


func _draw() -> void:
	if kind == &"chest":
		draw_rect(Rect2(-13.0, -9.0, 26.0, 20.0), Color(0.33, 0.16, 0.30))
		draw_rect(Rect2(-11.0, -7.0, 22.0, 16.0), Color(0.96, 0.69, 0.28))
		draw_rect(Rect2(-11.0, -1.0, 22.0, 3.0), Color(0.52, 0.20, 0.34))
		draw_circle(Vector2.ZERO, 3.0, Color(1.0, 0.95, 0.65))
		return
	var color := Color(0.35, 0.84, 0.96) if kind == &"xp" else Color(1.0, 0.79, 0.29)
	draw_circle(Vector2.ZERO, 8.0, Color(0.2, 0.16, 0.2))
	draw_circle(Vector2.ZERO, 6.0, color)
	draw_circle(Vector2(-2.0, -2.0), 2.0, Color.WHITE)
