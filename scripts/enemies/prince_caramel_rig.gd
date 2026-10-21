class_name PrinceCaramelRig
extends Node2D
## Rigid painted pieces rotate at real skeleton joints; no whole-sprite stretching.

var bones: Dictionary[StringName, Bone2D] = {}
var held_heart: Sprite2D

func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	var skeleton := Skeleton2D.new()
	skeleton.name = &"Skeleton2D"
	add_child(skeleton)
	_bone(skeleton, &"Body", Vector2(0, -64))
	_bone(bones.Body, &"Ladle", Vector2(38, 0))
	_bone(bones.Body, &"BombHand", Vector2(-42, -6))
	_bone(skeleton, &"LeftFoot", Vector2(-26, -15))
	_bone(skeleton, &"RightFoot", Vector2(26, -15))
	_piece(bones.Body, 0, 130, Vector2(0, -8), 2)
	# Source elbow/shoulder anchors align to the cauldron's side, behind its lip.
	_piece(bones.Ladle, 1, 109, Vector2(30, -27), 1)
	_piece(bones.BombHand, 2, 83, Vector2(-12, 31), 3)
	_piece(bones.LeftFoot, 3, 49, Vector2(-2, 0), 0)
	_piece(bones.RightFoot, 4, 49, Vector2(2, 0), 0)
	held_heart = Sprite2D.new()
	held_heart.texture = PrinceCaramelArt.texture(8)
	held_heart.position = Vector2(46, -60)
	held_heart.scale = Vector2.ONE * 39 / 226.0
	held_heart.z_index = 5
	bones.Ladle.add_child(held_heart)
	sample(0, 0, 0, false)

func _bone(parent: Node, id: StringName, at: Vector2) -> void:
	var bone := Bone2D.new()
	bone.name = id
	bone.position = at
	bone.length = 18
	bone.set_autocalculate_length_and_angle(false)
	bone.rest = bone.transform
	parent.add_child(bone)
	bones[id] = bone

func _piece(parent: Node2D, index: int, extent: float, at: Vector2, layer: int) -> void:
	var sprite := Sprite2D.new()
	sprite.texture = PrinceCaramelArt.texture(index)
	sprite.scale = Vector2.ONE * extent / maxf(sprite.texture.get_width(), sprite.texture.get_height())
	sprite.position = at
	sprite.z_index = layer
	parent.add_child(sprite)

func sample(seconds: float, windup: float, release: float, walking: bool) -> void:
	if bones.is_empty(): return
	held_heart.visible = false
	for bone: Bone2D in bones.values(): bone.transform = bone.rest
	var prep := smoothstep(0, 1, windup)
	var snap := smoothstep(0, 0.7, release)
	var settle := smoothstep(0.7, 1, release)
	bones.Body.rotation = deg_to_rad(lerpf(-5 * prep, 8, snap) * (1 - settle) + sin(seconds * 2) * 1.5)
	bones.Body.position.y -= prep * 3 * (1 - snap)
	bones.Ladle.rotation = deg_to_rad(lerpf(-38 * prep, 62, snap) * (1 - settle))
	bones.BombHand.rotation = deg_to_rad(lerpf(44 * prep, -52, snap) * (1 - settle))
	var stride := sin(seconds * TAU * 2.5) if walking else 0.0
	bones.LeftFoot.rotation = deg_to_rad(10 * stride)
	bones.RightFoot.rotation = -bones.LeftFoot.rotation
	bones.LeftFoot.position.y -= maxf(stride, 0) * 3
	bones.RightFoot.position.y -= maxf(-stride, 0) * 3
	bones.Body.position.y -= absf(stride) * 1.5

func projectile_origin() -> Vector2:
	return bones.Ladle.to_global(Vector2(46, -60))

func sample_heart(seconds: float, preparation: float, release: float, burst := false, walking := false) -> void:
	sample(seconds, 0, 0, walking)
	var prep := smoothstep(0, 1, preparation)
	var snap := smoothstep(0, 0.6, release)
	bones.Ladle.rotation = deg_to_rad(lerpf(-48 if burst else -66, 28, snap) * prep)
	bones.BombHand.rotation = deg_to_rad((72 if burst else 25) * prep * (1 - snap))
	bones.Body.rotation = deg_to_rad(-3 * prep + sin(release * PI) * 7)
	bones.Body.position.y -= prep * (4 if burst else 2)
	held_heart.visible = true
	held_heart.modulate.a = maxf(1 - release, 0)

func sample_rush(seconds: float, preparation: float, charging: bool, direction: Vector2) -> void:
	sample(seconds, 0, 0, charging)
	var prep := smoothstep(0, 1, preparation)
	var side := 1.0 if direction.x >= 0 else -1.0
	bones.Body.rotation = deg_to_rad(10 * side * prep)
	bones.Body.position.y += prep * 4
	bones.Ladle.rotation = deg_to_rad(42 * prep)
	bones.BombHand.rotation = deg_to_rad(-28 * prep)
	if charging:
		bones.LeftFoot.rotation = sin(seconds * 38) * 0.35
		bones.RightFoot.rotation = -bones.LeftFoot.rotation
