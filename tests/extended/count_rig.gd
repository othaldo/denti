extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var scene := load("res://scenes/enemies/count_cloak_rig.tscn") as PackedScene
	var rig := scene.instantiate() as CountCloakRig
	var other := scene.instantiate() as CountCloakRig
	root.add_child(rig)
	root.add_child(other)
	await process_frame
	_check(rig.skeleton.get_bone_count() == 12, "Count rig lacks its twelve independent bones")
	_check(rig.cloth.size() == 2, "Count rig has no separate cloth panels")
	for panel in rig.cloth:
		_check(panel.get_bone_count() == 3, "cloak panel is not bound to its three-bone chain")
		_check(panel.polygon.size() == 49 and panel.polygons.size() == 72, "cloak has no subdivided cloth mesh")
		for binding in panel.get_bone_count():
			_check(rig.skeleton.get_node_or_null(panel.get_bone_path(binding)) is Bone2D, "cloth references an absent bone")
		for index in panel.polygon.size():
			var total := 0.0
			for binding in panel.get_bone_count():
				total += panel.get_bone_weights(binding)[index]
			_check(is_equal_approx(total, 1.0), "cloth vertex has missing or excess influence")
	# Extreme poses and the fast transitions must not collapse/invert the cloth.
	var smallest_ratio := INF
	for frame in 615:
		var style := frame / 205
		var moment := frame % 205
		if style == 0:
			rig.sample(float(moment) / 60.0)
		else:
			rig.sample_strike(style, minf(moment / 100.0, 1), maxf((moment - 100) / 104.0, 0))
		for panel in rig.cloth:
			var vertices := _project(rig, panel)
			for face: PackedInt32Array in panel.polygons:
				var rest := (panel.polygon[face[1]] - panel.polygon[face[0]]).cross(panel.polygon[face[2]] - panel.polygon[face[0]])
				var current := (vertices[face[1]] - vertices[face[0]]).cross(vertices[face[2]] - vertices[face[0]])
				smallest_ratio = minf(smallest_ratio, current / rest)
		var head: Sprite2D = rig.get_node("Skeleton2D/Torso/Head/Part1")
		_check(is_equal_approx(head.global_transform.x.length(), head.global_transform.y.length()) and absf(head.global_transform.x.dot(head.global_transform.y)) < 0.001, "face was stretched or sheared")
	_check(smallest_ratio > 0.08, "cloth mesh collapses/inverts in a transition: %f" % smallest_ratio)
	# Two actors share artwork, never their bone poses or playback state.
	other.sample(0)
	var resting := other.bones[&"LeftShoulder"].rotation
	rig.sample(1.09)
	_check(is_equal_approx(other.bones[&"LeftShoulder"].rotation, resting), "one rig changed another actor's bones")
	_check(not is_equal_approx(rig.bones[&"LeftShoulder"].rotation, resting), "rig did not actually animate its shoulder")
	var moving := rig.bones[&"LeftTip"].rotation
	rig.sample(1.20)
	_check(not is_equal_approx(rig.bones[&"LeftTip"].rotation, moving), "cloth tip has no independent follow-through")
	rig.sample(0)
	_check(is_equal_approx(rig.bones[&"LeftShoulder"].rotation, resting), "scrubbing cannot return to the resting pose")
	rig.apply_stride(0.07, 1.0)
	var lifted_foot := rig.bones[&"LeftFoot"].transform
	for repeat in 10:
		rig.sample(0)
		rig.apply_stride(0.07, 1.0)
	_check(rig.bones[&"LeftFoot"].transform.is_equal_approx(lifted_foot), "sampled walking accumulates foot drift")
	rig.sample(0)
	rig.apply_stride(0, 0)
	_check(is_equal_approx(rig.bones[&"LeftFoot"].position.y, rig.bones[&"LeftFoot"].rest.origin.y), "walking cannot return to planted feet")
	rig.play_combo()
	await process_frame
	paused = true
	var frozen := rig.animator.current_animation_position
	await process_frame
	await process_frame
	_check(is_equal_approx(rig.animator.current_animation_position, frozen), "paused tree keeps moving the rig")
	paused = false
	rig.animator.pause()
	var frozen_head := rig.bones[&"Head"].transform
	await process_frame
	_check(rig.bones[&"Head"].transform == frozen_head, "animation pause did not freeze its pose")
	print("COUNT_RIG smallest cloth area ratio=", smallest_ratio)
	if failures.is_empty(): print("PASS count_rig")
	finish(0 if failures.is_empty() else 1)

func _project(rig: CountCloakRig, panel: Polygon2D) -> PackedVector2Array:
	var vertices := PackedVector2Array()
	for index in panel.polygon.size():
		var point := Vector2.ZERO
		for binding in panel.get_bone_count():
			var bone := rig.skeleton.get_node(panel.get_bone_path(binding)) as Bone2D
			point += bone.global_transform * (bone.get_skeleton_rest().affine_inverse() * panel.polygon[index]) * panel.get_bone_weights(binding)[index]
		vertices.append(point)
	return vertices
