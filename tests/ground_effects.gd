extends "res://tests/support/test_runtime.gd"

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var image := Image.load_from_file("res://assets/vfx/ground_effects.png")
	_check(image.get_size() == Vector2i(1152, 384), "ground atlas dimensions changed without updating the drawing bounds")
	var middle := 192
	# The texture's nominal danger radius must agree with the gameplay radius.
	for offset: Vector2i in [Vector2i(176, 0), Vector2i(-176, 0), Vector2i(0, 176), Vector2i(0, -176)]:
		var at := Vector2i(768 + middle, middle) + offset
		_check(image.get_pixelv(at).a > 0.8, "danger boundary no longer marks the damage radius")
	_check(image.get_pixel(960, middle).a < 0.1, "danger field obscures the arena center")
	_check(image.get_pixel(576, middle).a == 0.0, "impact ripple lost its clear center")
	for tile in 3:
		# Transparent padding prevents neighboring atlas cells bleeding at scale.
		for edge in 384:
			_check(image.get_pixel(tile * 384 + edge, 0).a == 0.0 and image.get_pixel(tile * 384 + edge, 383).a == 0.0, "ground atlas has no transparent vertical padding")
			_check(image.get_pixel(tile * 384, edge).a == 0.0 and image.get_pixel(tile * 384 + 383, edge).a == 0.0, "ground atlas has no transparent horizontal padding")
	if failures == 0:
		print("Ground effects: radius, readability and atlas padding passed")
	finish(0 if failures == 0 else 1)
