class_name LootGoblinRig
extends Node2D

const REFERENCE_SIZE := 180.0
const ATLAS: Texture2D = preload("res://assets/enemies/loot_goblin/parts.png")
const REGIONS: Array[Rect2] = [Rect2(46, 49, 555, 517), Rect2(598, 96, 495, 466),
	Rect2(1158, 121, 324, 403), Rect2(77, 587, 372, 366),
	Rect2(595, 647, 342, 295), Rect2(1137, 647, 353, 295)]
static var parts: Array[AtlasTexture] = []
static var prepared_atlas: ImageTexture
var joints: Dictionary[StringName, Node2D] = {}
var sack: Sprite2D
var skeleton: Skeleton2D

static func texture(index: int) -> AtlasTexture:
	if parts.is_empty():
		var image := ATLAS.get_image()
		if not image.has_mipmaps(): image.generate_mipmaps()
		prepared_atlas = ImageTexture.create_from_image(image)
		for piece in 6:
			var tile := AtlasTexture.new()
			tile.atlas = prepared_atlas
			tile.region = REGIONS[piece]
			tile.filter_clip = true
			parts.append(tile)
	return parts[index]

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	skeleton = Skeleton2D.new()
	add_child(skeleton)
	_piece(&"FootL", 4, Vector2(-23, 36), 39, 0)
	_piece(&"FootR", 5, Vector2(22, 36), 39, 0)
	sack = _piece(&"Sack", 1, Vector2(44, -10), 105, 1)
	_piece(&"Body", 0, Vector2(-10, -25), 128, 2)
	_piece(&"ArmL", 3, Vector2(-46, -8), 65, 3).position.y = 28
	_piece(&"ArmR", 2, Vector2(23, -8), 65, 3).position.y = 28
	sample(0, false, false, false, 0, 1)

func _piece(id: StringName, index: int, at: Vector2, extent: float, layer: int) -> Sprite2D:
	var joint := Bone2D.new()
	joint.set_autocalculate_length_and_angle(false)
	joint.length = 16
	joint.position = at
	joint.rest = joint.transform
	joint.set_meta("rest", at)
	skeleton.add_child(joint)
	joints[id] = joint
	var sprite := Sprite2D.new()
	sprite.texture = texture(index)
	sprite.scale = Vector2.ONE * extent / maxf(sprite.texture.get_width(), sprite.texture.get_height())
	sprite.set_meta("base_scale", sprite.scale)
	sprite.z_index = layer
	joint.add_child(sprite)
	return sprite

func sample(seconds: float, walking: bool, sprinting: bool, grabbing: bool, fullness: float, facing: float) -> void:
	if joints.is_empty(): return
	scale.x = absf(scale.x) * facing
	for joint in joints.values():
		joint.position = joint.get_meta("rest")
		joint.rotation = 0
	var stride := sin(seconds * (25 if sprinting else 16)) if walking else 0.0
	joints.FootL.rotation = stride * 0.28
	joints.FootR.rotation = -stride * 0.28
	joints.FootL.position.y -= maxf(stride, 0) * 6
	joints.FootR.position.y -= maxf(-stride, 0) * 6
	joints.Body.position.y -= absf(stride) * 2
	joints.Body.rotation = 0.07 if sprinting else sin(seconds * 2.0) * 0.018
	joints.ArmL.rotation = (-0.6 + sin(seconds * 17) * 0.12) if grabbing else -stride * 0.23
	joints.ArmR.rotation = -0.36 if sprinting else (0.6 if grabbing else stride * 0.20)
	joints.Sack.rotation = sin(seconds * (22 if sprinting else 9)) * (0.12 if walking else 0.025)
	sack.scale = sack.get_meta("base_scale") * lerpf(0.84, 1.04, clampf(fullness, 0, 1))

static func departure(parent: Node, at: Vector2, fullness: float, direction: float) -> void:
	var rig := LootGoblinRig.new()
	parent.add_child(rig)
	rig.position = at
	rig.z_index = 6
	rig.scale = Vector2.ONE * 0.33
	rig.sample(0.2, true, true, false, fullness, direction)
	var tween := rig.create_tween()
	tween.tween_property(rig, "position", at + Vector2(direction * 85, -15), 0.45)
	tween.parallel().tween_property(rig, "modulate:a", 0.0, 0.45).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)
	tween.tween_callback(rig.queue_free)
