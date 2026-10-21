class_name EmperorCourtRig
extends Node2D

var bones: Dictionary[StringName, Bone2D] = {}
var core: Sprite2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var skeleton := Skeleton2D.new()
	add_child(skeleton)
	_bone(skeleton, &"Body", Vector2(0, -88))
	_bone(bones.Body, &"Crown", Vector2(0, -95))
	_bone(bones.Body, &"Scepter", Vector2(41, -7))
	_bone(bones.Body, &"Seal", Vector2(-38, 5))
	_bone(bones.Body, &"Core", Vector2(0, 4))
	_piece(bones.Body, 0, 190, Vector2.ZERO, 2)
	_piece(bones.Crown, 1, 108, Vector2.ZERO, 3)
	_piece(bones.Scepter, 2, 146, Vector2(27, 2), 4)
	_piece(bones.Seal, 3, 88, Vector2(-23, 7), 4)
	core = _piece(bones.Core, 5, 43, Vector2.ZERO, 5)
	for index in 3:
		var id := StringName("Guard%d" % index)
		_bone(skeleton, id, Vector2.ZERO)
		_piece(bones[id], 4, 47, Vector2.ZERO, 6)
	sample(0, 0, 0, Vector2.DOWN, false)

func _bone(parent: Node, id: StringName, at: Vector2) -> void:
	var bone := Bone2D.new()
	bone.name = id
	bone.position = at
	bone.length = 20
	bone.set_autocalculate_length_and_angle(false)
	bone.rest = bone.transform
	parent.add_child(bone)
	bones[id] = bone

func _piece(parent: Node2D, index: int, extent: float, at: Vector2, layer: int) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = EmperorCourtArt.texture(index)
	sprite.position = at
	sprite.scale = Vector2.ONE * extent / maxf(sprite.texture.get_width(), sprite.texture.get_height())
	sprite.z_index = layer
	parent.add_child(sprite)
	return sprite

func sample(seconds: float, prep: float, kind: int, facing: Vector2, exposed: bool) -> void:
	if bones.is_empty(): return
	for bone: Bone2D in bones.values(): bone.transform = bone.rest
	bones.Body.position.y += sin(seconds * 2.4) * 3
	bones.Crown.position.y -= sin(seconds * 2.4 + 0.8) * 3
	bones.Scepter.rotation = (-0.42 if kind != 1 else -0.8) * smoothstep(0, 1, prep)
	bones.Seal.rotation = 0.35 * smoothstep(0, 1, prep)
	core.visible = exposed
	core.modulate = Color(1.1, 0.8, 1.2, 0.85 + 0.15 * sin(seconds * 8))
	for index in 3:
		var bone: Bone2D = bones[StringName("Guard%d" % index)]
		var direction := facing.rotated((index - 1) * deg_to_rad(48))
		bone.position = direction * (105 if not exposed else 125) + Vector2(0, -88)
		bone.rotation = direction.angle() - PI * 0.5
		bone.modulate.a = 0.3 if exposed else 1.0
