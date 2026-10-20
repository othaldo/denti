class_name CountCloakRig
extends Node2D
## Skeletal presentation: gameplay owns attack timing; the rig only presents it.

const ART: Texture2D = preload("res://assets/enemies/count_rig/parts.png")
const REGIONS: Array[Rect2] = [
	Rect2(55, 70, 331, 336), Rect2(433, 129, 379, 245),
	Rect2(827, 48, 407, 362), Rect2(23, 445, 424, 364),
	Rect2(514, 475, 255, 302), Rect2(902, 477, 256, 300),
	Rect2(72, 853, 266, 318), Rect2(483, 875, 255, 293),
	Rect2(763, 849, 484, 300),
]
const MESH_STEPS := 6

var skeleton: Skeleton2D
var animator: AnimationPlayer
var bones: Dictionary[StringName, Bone2D] = {}
var cloth: Array[Polygon2D] = []
var debug_bones := false:
	set(value):
		debug_bones = value
		if has_node("BoneOverlay"):
			get_node("BoneOverlay").queue_redraw()


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	if not has_node("Skeleton2D"):
		_build()
	skeleton = get_node("Skeleton2D")
	animator = get_node("AnimationPlayer")
	_cache_bones(skeleton)
	cloth.assign([get_node("LeftCloth"), get_node("RightCloth")])
	if not has_node("BoneOverlay"):
		var overlay := CountRigOverlay.new()
		overlay.z_index = 100
		_put(self, overlay, &"BoneOverlay")
	sample(0.0)


func _process(_delta: float) -> void:
	if debug_bones:
		get_node("BoneOverlay").queue_redraw()


func play_combo() -> void:
	animator.play(&"combo")


func sample(seconds: float) -> void:
	animator.play(&"combo")
	animator.seek(clampf(seconds, 0.0, CountRigMotion.DURATION), true)
	animator.pause()
	queue_redraw()

func blend_sample(from_seconds: float, to_seconds: float, weight: float) -> void:
	# Blend a third strike into the two-sided study without snapping the joints.
	sample(from_seconds)
	var from: Dictionary[StringName, Transform2D] = {}
	for key in bones: from[key] = bones[key].transform
	sample(to_seconds)
	for key in bones:
		bones[key].transform = from[key].interpolate_with(bones[key].transform, clampf(weight, 0, 1))


func capture_pose() -> Dictionary[StringName, Transform2D]:
	var pose: Dictionary[StringName, Transform2D] = {}
	for key in bones: pose[key] = bones[key].transform
	return pose

func blend_from(pose: Dictionary[StringName, Transform2D], weight: float) -> void:
	for key in bones:
		bones[key].transform = pose[key].interpolate_with(bones[key].transform, clampf(weight, 0, 1))

func sample_strike(kind: int, preparation: float, release: float) -> void:
	sample(0)
	var prep := smoothstep(0, 1, preparation)
	var snap := smoothstep(0, 0.5, release)
	var ring := kind == CloakStrikeData.Kind.RING
	var folded := -112.0 if ring else -18.0
	var opened := -8.0 if ring else -112.0
	var shoulder := lerpf(lerpf(-60, folded, prep), opened, snap)
	bones[&"LeftShoulder"].rotation = deg_to_rad(shoulder)
	bones[&"RightShoulder"].rotation = -deg_to_rad(shoulder)
	bones[&"LeftMiddle"].rotation = deg_to_rad(lerpf(-8, 12, snap) * prep)
	bones[&"RightMiddle"].rotation = -bones[&"LeftMiddle"].rotation
	bones[&"LeftTip"].rotation = deg_to_rad(sin(release * PI) * 15)
	bones[&"RightTip"].rotation = -bones[&"LeftTip"].rotation
	bones[&"Torso"].position.y += lerpf(-4 * prep, 5, snap)
	bones[&"Head"].rotation = deg_to_rad(lerpf(-3 * prep, 3, snap))

func apply_stride(seconds: float, strength: float) -> void:
	# Add small alternating steps after sampling; no scaling of the painted pieces.
	var step := sin(seconds * TAU * 3.2) * strength
	bones[&"LeftFoot"].rotation += deg_to_rad(12) * step
	bones[&"RightFoot"].rotation -= deg_to_rad(12) * step
	bones[&"LeftFoot"].position.y = bones[&"LeftFoot"].rest.origin.y - maxf(step, 0) * 2.5
	bones[&"RightFoot"].position.y = bones[&"RightFoot"].rest.origin.y - maxf(-step, 0) * 2.5
	bones[&"Torso"].position.y -= absf(step) * 1.2

func _put(parent: Node, child: Node, node_name: StringName) -> void:
	child.name = node_name
	parent.add_child(child)
	child.owner = self


func _bone(parent: Node2D, bone_name: StringName, at: Vector2, length: float) -> Bone2D:
	var bone := Bone2D.new()
	bone.position = at
	bone.rest = bone.transform
	bone.set_autocalculate_length_and_angle(false)
	bone.set_length(length)
	_put(parent, bone, bone_name)
	bones[bone_name] = bone
	return bone


func _piece(parent: Node2D, part: int, width: float, at: Vector2, layer: int, pivot := Vector2(0.5, 0.5)) -> Sprite2D:
	var atlas := AtlasTexture.new()
	atlas.atlas = ART
	atlas.region = REGIONS[part]
	atlas.filter_clip = true
	var sprite := Sprite2D.new()
	sprite.texture = atlas
	sprite.centered = false
	sprite.offset = -REGIONS[part].size * pivot
	sprite.scale = Vector2.ONE * width / REGIONS[part].size.x
	sprite.position = at
	sprite.z_index = layer
	_put(parent, sprite, StringName("Part%d" % part))
	return sprite


func _build() -> void:
	skeleton = Skeleton2D.new()
	_put(self, skeleton, &"Skeleton2D")
	var torso := _bone(skeleton, &"Torso", Vector2(0, -45), 28)
	var head := _bone(torso, &"Head", Vector2(0, -44), 22)
	_bone(head, &"LeftAntenna", Vector2(-18, -18), 25)
	_bone(head, &"RightAntenna", Vector2(18, -18), 25)
	_bone(skeleton, &"LeftFoot", Vector2(-14, -23), 25)
	_bone(skeleton, &"RightFoot", Vector2(14, -23), 25)
	for side in [-1, 1]:
		var prefix := "Left" if side < 0 else "Right"
		var shoulder := _bone(torso, StringName(prefix + "Shoulder"), Vector2(side * 25, -40), 33)
		var middle := _bone(shoulder, StringName(prefix + "Middle"), Vector2(side * 27, 18), 27)
		_bone(middle, StringName(prefix + "Tip"), Vector2(side * 24, 15), 23)
		_cloth(side, shoulder)
	_piece(torso, 0, 70, Vector2.ZERO, 1)
	_piece(head, 1, 76, Vector2.ZERO, 8)
	_piece(bones[&"LeftAntenna"], 4, 24, Vector2.ZERO, 7, Vector2(0.77, 0.94))
	_piece(bones[&"RightAntenna"], 5, 24, Vector2.ZERO, 7, Vector2(0.23, 0.94))
	_piece(bones[&"LeftFoot"], 6, 17, Vector2(0, 9), 0, Vector2(0.60, 0.08))
	_piece(bones[&"RightFoot"], 7, 17, Vector2(0, 9), 0, Vector2(0.40, 0.08))
	_piece(torso, 8, 88, Vector2(0, -30), 6)
	animator = AnimationPlayer.new()
	_put(self, animator, &"AnimationPlayer")
	var library := AnimationLibrary.new()
	library.add_animation(&"combo", CountRigMotion.combo())
	animator.add_animation_library(&"", library)


func _cloth(side: int, shoulder: Bone2D) -> void:
	var panel := Polygon2D.new()
	var prefix := "Left" if side < 0 else "Right"
	_put(self, panel, StringName(prefix + "Cloth"))
	panel.texture = ART
	panel.skeleton = panel.get_path_to(skeleton)
	panel.z_index = 3
	var region := REGIONS[2 if side < 0 else 3]
	var pixel_pivot := Vector2(region.size.x * (0.93 if side < 0 else 0.07), region.size.y * 0.10)
	var source_scale := 76.0 / region.size.x
	var anchor := Vector2(side * 25, -85)
	var points := PackedVector2Array()
	var uvs := PackedVector2Array()
	var weights: Array[PackedFloat32Array] = [PackedFloat32Array(), PackedFloat32Array(), PackedFloat32Array()]
	# Explicit triangles form a regular mesh, including its internal vertices.
	var faces: Array[PackedInt32Array] = []
	for row in MESH_STEPS + 1:
		for column in MESH_STEPS + 1:
			var unit := Vector2(float(column), float(row)) / float(MESH_STEPS)
			var pixel := region.size * unit
			points.append(anchor + (pixel - pixel_pivot) * source_scale)
			uvs.append(region.position + pixel)
			var reach := clampf(((1.0 - unit.x if side < 0 else unit.x) + unit.y) * 0.5, 0, 1)
			weights[0].append(maxf(1.0 - reach * 2.0, 0.0))
			weights[1].append(1.0 - absf(reach - 0.5) * 2.0)
			weights[2].append(maxf(reach * 2.0 - 1.0, 0.0))
	for row in MESH_STEPS:
		for column in MESH_STEPS:
			var index := row * (MESH_STEPS + 1) + column
			faces.append(PackedInt32Array([index, index + 1, index + MESH_STEPS + 2]))
			faces.append(PackedInt32Array([index, index + MESH_STEPS + 2, index + MESH_STEPS + 1]))
	panel.polygon = points
	panel.uv = uvs
	panel.polygons = faces
	panel.add_bone(skeleton.get_path_to(shoulder), weights[0])
	panel.add_bone(skeleton.get_path_to(bones[StringName(prefix + "Middle")]), weights[1])
	panel.add_bone(skeleton.get_path_to(bones[StringName(prefix + "Tip")]), weights[2])


func _cache_bones(parent: Node) -> void:
	for child in parent.get_children():
		if child is Bone2D:
			bones[child.name] = child
		_cache_bones(child)
