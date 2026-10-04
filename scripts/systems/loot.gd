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
var spatial_index: LootSpatialIndex
var spatial_order: int = 0


func _ready() -> void:
	spatial_index = get_parent() as LootSpatialIndex
	if spatial_index != null:
		spatial_index.register(self)
		set_notify_local_transform(true)
		set_physics_process(false)


func _notification(what: int) -> void:
	if what == NOTIFICATION_LOCAL_TRANSFORM_CHANGED and is_instance_valid(spatial_index):
		spatial_index.update(self)


func _exit_tree() -> void:
	if is_instance_valid(spatial_index):
		spatial_index.unregister(self)


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
	if is_instance_valid(spatial_index):
		spatial_index.collecting[get_instance_id()] = self


func _physics_process(delta: float) -> void:
	if target == null:
		return
	advance_collection(delta, target.global_position, target.items.cached_pickup_range * target.items.cached_pickup_range)


# Return whether movement needs another tick while Denti stands still.
func advance_collection(delta: float, at: Vector2, magnet_squared: float) -> bool:
	if is_queued_for_deletion():
		return false
	var distance_squared := global_position.distance_squared_to(at)
	if distance_squared <= PICKUP_DISTANCE * PICKUP_DISTANCE:
		queue_free()
		collected.emit(kind, amount, reward_id)
	elif wave_collecting:
		var distance := sqrt(distance_squared)
		global_position = global_position.move_toward(at, maxf(WAVE_COLLECTION_SPEED, distance * 3.0) * delta)
		return true
	elif distance_squared <= magnet_squared:
		global_position = global_position.move_toward(at, 200.0 * delta)
		return true
	return false
