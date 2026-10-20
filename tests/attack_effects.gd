extends "res://tests/support/test_runtime.gd"

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _run() -> void:
	var image := Image.load_from_file("res://assets/vfx/attack_effects.png")
	_check(image.get_size() == Vector2i(2048, 1792), "attack atlas dimensions no longer match the packed regions")
	for kind in 9:
		for frame in AttackEffects.FRAMES:
			var source := AttackEffects.region(kind, (frame + 0.1) / AttackEffects.FPS)
			_check(source.position == Vector2(frame * 256, kind * 128), "animation sampled another effect's cell")
			for x in 256:
				_check(image.get_pixel(int(source.position.x) + x, int(source.position.y)).a == 0.0, "attack cell has no top gutter")
				_check(image.get_pixel(int(source.position.x) + x, int(source.position.y) + 127).a == 0.0, "attack cell has no bottom gutter")
		# Animated effects must actually change; impact is deliberately static.
		if kind != AttackEffects.Shape.FLASH:
			_check(image.get_region(Rect2i(0, kind * 128, 256, 128)).get_data() != image.get_region(Rect2i(256, kind * 128, 256, 128)).get_data(), "animation frames are identical")
	# The painted warning fills its width and fades out at the nominal edge.
	var edge := ceili(64.0 + 56.0 * AttackEffects.LANE_EDGE)
	_check(image.get_pixel(128, 3 * 128 + edge).a == 0.0, "ground warning extends past its configured width")
	_check(image.get_pixel(128, 3 * 128 + 64).a > 0.07 and image.get_pixel(128, 3 * 128 + 64).a <= 0.63, "ground warning is invisible or obscures the floor")
	# Timer phases must progress clockwise from the top, with a clear center.
	for step in [0, 16, 32, 64]:
		var origin := Vector2i(step % 12 * 80, 1152 + step / 12 * 80)
		_check(image.get_pixelv(origin + Vector2i(40, 40)).a == 0.0, "warning timer has an opaque center")
		_check((image.get_pixelv(origin + Vector2i(40, 8)).a > 0.5) == (step > 0), "warning timer does not start at the top")
		_check((image.get_pixelv(origin + Vector2i(8, 40)).a > 0.5) == (step == 64), "warning timer completion is incorrect")
	# World endpoints survive rotation, skew and mirroring in shared drawing.
	for base in [Transform2D.IDENTITY, Transform2D(0.5, Vector2(-1.2, 0.7), 0.2, Vector2(41, -23))]:
		for direction: Vector2 in [Vector2.RIGHT, Vector2.DOWN, Vector2(-2, 1).normalized()]:
			var start := Vector2(12, -17)
			var end := start + direction * 307
			var mapping := AttackEffects.strip_transform(start, end, base)
			_check((mapping * Vector2.ZERO).is_equal_approx(base * start), "effect emission moved away from its muzzle")
			_check((mapping * Vector2(307, 0)).is_equal_approx(base * end), "effect endpoint moved away from its target")
	AttackEffects.prepare_spray(65.0)
	var cache_size := AttackEffects.cone_uvs.size()
	for repeat in 100:
		AttackEffects.prepare_spray(65.0)
	_check(AttackEffects.cone_uvs.size() == cache_size and AttackEffects.cone_uvs[65.0].size() == 4, "prepared spray rebuilds geometry during repeated attacks")
	var points := AttackEffects.cone_points(65.0)
	_check(points[0] == Vector2.ZERO and is_equal_approx(rad_to_deg(points[1].angle()), -32.5) and is_equal_approx(rad_to_deg(points[-1].angle()), 32.5), "spray no longer matches the configured attack sector")
	for index in range(1, points.size()):
		_check(is_equal_approx(points[index].length(), 1.0), "spray extends past its attack range")
	if failures == 0:
		print("Attack effects: atlas, boundaries, timer phases, world alignment and prepared spray passed")
	finish(0 if failures == 0 else 1)
