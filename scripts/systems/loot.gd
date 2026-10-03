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
var sprite: Sprite2D


func configure(loot_kind: StringName, loot_amount: int, player: Player, loot_reward_id: StringName = &"") -> void:
	kind = loot_kind
	amount = loot_amount
	reward_id = loot_reward_id
	target = player
	if sprite == null:
		sprite = Sprite2D.new()
		add_child(sprite)
	sprite.texture = CombatSpriteTextures.loot(kind)
	sprite.scale = Vector2.ONE / CombatSpriteTextures.RESOLUTION


func begin_wave_collection() -> void:
	wave_collecting = true


func _physics_process(delta: float) -> void:
	if target == null:
		return
	var distance_squared := global_position.distance_squared_to(target.global_position)
	if distance_squared <= PICKUP_DISTANCE * PICKUP_DISTANCE:
		queue_free()
		collected.emit(kind, amount, reward_id)
	elif wave_collecting:
		var distance := sqrt(distance_squared)
		global_position = global_position.move_toward(target.global_position, maxf(WAVE_COLLECTION_SPEED, distance * 3.0) * delta)
	elif distance_squared <= target.items.cached_pickup_range * target.items.cached_pickup_range:
		global_position = global_position.move_toward(target.global_position, 200.0 * delta)
