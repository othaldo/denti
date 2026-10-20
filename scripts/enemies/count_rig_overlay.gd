class_name CountRigOverlay
extends Node2D
## Debug-only projection of the same bone weights used by the GPU cloth mesh.

func _draw() -> void:
	var rig := get_parent() as CountCloakRig
	if rig == null or not rig.debug_bones:
		return
	for panel in rig.cloth:
		var projected := PackedVector2Array()
		for index in panel.polygon.size():
			var point := Vector2.ZERO
			for binding in panel.get_bone_count():
				var bone := rig.skeleton.get_node(panel.get_bone_path(binding)) as Bone2D
				var weight := panel.get_bone_weights(binding)[index]
				var rest_point := bone.get_skeleton_rest().affine_inverse() * panel.polygon[index]
				point += to_local(bone.to_global(rest_point)) * weight
			projected.append(point)
		for face: PackedInt32Array in panel.polygons:
			draw_polyline(PackedVector2Array([projected[face[0]], projected[face[1]], projected[face[2]], projected[face[0]]]), Color(0.05, 0.80, 0.85, 0.4), 0.45, true)
	for bone: Bone2D in rig.bones.values():
		var point := to_local(bone.global_position)
		if bone.get_parent() is Bone2D:
			draw_line(to_local(bone.get_parent().global_position), point, Color(0.15, 1, 0.85), 1.2, true)
		draw_circle(point, 1.8, Color(1, 0.82, 0.2))
