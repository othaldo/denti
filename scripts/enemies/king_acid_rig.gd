class_name KingAcidRig
extends Node2D

var bones: Dictionary[StringName, Bone2D] = {}
var core: Sprite2D
var reservoirs: Array[ShaderMaterial] = []

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var skeleton := Skeleton2D.new()
	add_child(skeleton)
	_bone(skeleton, &"Body", Vector2(0, -94))
	_bone(bones.Body, &"Siphon", Vector2(-40, 6))
	_bone(bones.Body, &"Hammer", Vector2(42, 7))
	_bone(skeleton, &"LeftFoot", Vector2(-30, -14))
	_bone(skeleton, &"RightFoot", Vector2(30, -14))
	_bone(bones.Body, &"Core", Vector2(0, 37))
	_piece(bones.Body, 0, 165, Vector2(0, -4), 2)
	_piece(bones.Siphon, 1, 128, Vector2(-25, 20), 3)
	_piece(bones.Hammer, 2, 123, Vector2(26, 24), 3)
	_piece(bones.LeftFoot, 3, 65, Vector2.ZERO, 1)
	_piece(bones.RightFoot, 4, 65, Vector2.ZERO, 1)
	core = _piece(bones.Core, 5, 41, Vector2.ZERO, 4)
	sample(0, 0, 0, 0, false)

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
	sprite.texture = KingAcidArt.texture(index)
	sprite.position = at
	sprite.scale = Vector2.ONE * extent / maxf(sprite.texture.get_width(), sprite.texture.get_height())
	sprite.z_index = layer
	if index in [1, 2]:
		var liquid := ShaderMaterial.new()
		liquid.shader = preload("res://scripts/enemies/king_acid_reservoir.gdshader")
		sprite.material = liquid
		reservoirs.append(liquid)
	parent.add_child(sprite)
	return sprite

func sample(seconds: float, preparation: float, release: float, kind: int, walking: bool, exposed := false) -> void:
	if bones.is_empty(): return
	for bone: Bone2D in bones.values(): bone.transform = bone.rest
	var stride := sin(seconds * 10) if walking else 0.0
	bones.LeftFoot.rotation = stride * 0.10
	bones.RightFoot.rotation = -stride * 0.10
	bones.Body.position.y -= absf(stride) * 2
	var prep := smoothstep(0, 1, preparation)
	if kind == 1:
		bones.Hammer.rotation = lerpf(-0.9 * prep, 0.45, release)
		bones.Body.rotation = -0.08 * prep + sin(release * PI) * 0.12
		bones.LeftFoot.position.y -= prep * 7 * (1 - release)
	else:
		bones.Siphon.rotation = (-0.45 if kind == 2 else 0.35) * prep
		bones.Hammer.rotation = -0.25 * prep
		bones.Body.rotation = sin(seconds * 2) * 0.015
	core.visible = exposed
	core.modulate = Color(1.0, 1.18, 0.8, 0.82 + 0.18 * sin(seconds * 7))

func show_acid_level(value: float) -> void:
	for reservoir in reservoirs: reservoir.set_shader_parameter("acid_level", clampf(value, 0, 1))
