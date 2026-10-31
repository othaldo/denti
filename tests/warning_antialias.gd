extends "res://tests/support/test_runtime.gd"

const AA := preload("res://scripts/vfx/warning_antialias.gd")

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	var first := Node2D.new()
	var second := Node2D.new()
	root.add_child(first)
	root.add_child(second)
	AA.apply_to(first)
	AA.apply_to(second)
	assert(first.material == second.material and first.material is ShaderMaterial, "Warnings must share one material")
	var original := first.material
	for tick in 100: AA.apply_to(first)
	assert(first.material == original, "Warning frames must not allocate materials")
	var custom := CanvasItemMaterial.new()
	second.material = custom
	AA.apply_to(second)
	assert(second.material == custom, "Existing caller material was overwritten")
	second.material = null
	second.use_parent_material = true
	AA.apply_to(second)
	assert(second.material == null, "Inherited caller material was overwritten")
	assert(WarningEffects.ATLAS.get_size() == Vector2(2048, 1792), "Atlas dimensions changed: update analytic cell mapping")
	assert(WarningEffects.CHARGE_HEAD == Rect2(1152, 1728, 64, 64), "Charge cell changed: update analytic cell mapping")
	print("PASS warning_antialias: shared/reused material, caller ownership and atlas mapping")
	finish()
