extends SceneTree
## Rebuilds the editable native rig scene after changes to its parts or motion.

func _initialize() -> void:
	call_deferred("_build")

func _build() -> void:
	var rig := CountCloakRig.new()
	rig.name = &"CountCloakRig"
	root.add_child(rig)
	await process_frame
	var packed := PackedScene.new()
	var result := packed.pack(rig)
	if result == OK:
		result = ResourceSaver.save(packed, "res://scenes/enemies/count_cloak_rig.tscn")
	print("COUNT_RIG_BUILD ", result)
	rig.free()
	quit(0 if result == OK else 1)
