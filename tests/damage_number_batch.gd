extends SceneTree

const SCENE := preload("res://scenes/ui/damage_number.tscn")
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _run() -> void:
	var batch := DamageNumberBatch.new()
	root.add_child(batch)
	batch.set_process(false)
	var number := batch.acquire(SCENE)
	number.show_amount(Vector2(200, 150), 123)
	var id := number.get_instance_id()
	check(number.text == "123" and not number.visible and number.render_line.get_line_width() > 0, "damage text was not prepared for shared drawing")
	check(number.render_color == Color(1.0, 0.88, 0.37) and number.render_outline_size == 5, "enemy damage text lost its color or outline")
	var origin := number.origin
	var travel := number.travel
	batch._process(0.29)
	# Cubic ease-out at half its duration is 7/8; the scale is settled.
	check(number.render_transform.origin.is_equal_approx(origin + travel * 0.875), "shared number animation changed cubic movement or scale pivot")
	check(is_equal_approx(number.render_alpha, 1.0 - 0.21 / 0.58), "shared number animation lost its delayed fade")
	check(number.position == origin, "hidden Label still incurs transform updates")
	batch._process(0.36)
	check(batch.get_child_count() == 1, "number retired before the delayed fade completed")
	batch._process(0.02)
	check(batch.get_child_count() == 0 and batch.idle.size() == 1 and number.get_parent() == null, "expired number is not an inactive reserve object")
	var reused := batch.acquire(SCENE)
	reused.show_amount(Vector2(200, 150), 8, true)
	check(reused.get_instance_id() == id and reused.text == "-8" and reused.render_alpha == 1.0 and reused.elapsed == 0.0, "reused player damage retained old text, opacity or elapsed time")
	check(reused.render_color == Color(1.0, 0.40, 0.35), "player damage is no longer red")
	batch._process(0.67)
	reused = batch.acquire(SCENE)
	reused.show_message(Vector2.ZERO, "Schild!", Color.CYAN)
	check(reused.text == "Schild!" and reused.render_color == Color.CYAN and batch.created == 1, "important feedback lost its text/color or bypassed reuse")
	batch._process(0.67)
	reused = batch.acquire(SCENE)
	reused.show_message(Vector2.ZERO, "Sehr lange wichtige Meldung!", Color.WHITE)
	batch._process(0.67)
	reused = batch.acquire(SCENE)
	reused.show_amount(Vector2.ZERO, 2)
	check(reused.render_extent.x == reused.custom_minimum_size.x and absf(reused.origin.x + reused.render_extent.x * 0.5) <= 12.0, "reusing a long message shifted the next damage number")
	batch._process(0.67)
	for index in 150:
		batch.acquire(SCENE).show_amount(Vector2.ZERO, index + 1)
	batch._process(0.67)
	check(batch.get_child_count() == 0 and batch.idle.size() == batch.MAX_IDLE, "idle text pool is unbounded")
	var reserved_id := batch.idle[0].get_instance_id()
	batch.free()
	check(not is_instance_id_valid(reserved_id), "arena exit leaked pooled damage text")
	if DisplayServer.get_name() != "headless":
		await _render_comparison()
	if failures == 0:
		print("Denti shared damage text test passed")
	quit(0 if failures == 0 else 1)

func _render_comparison() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(320, 80)
	viewport.transparent_bg = true
	viewport.world_2d = World2D.new()
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var label: DamageNumber = SCENE.instantiate()
	label.text = "123"
	label.position = Vector2(20, 20)
	viewport.add_child(label)
	var batch := DamageNumberBatch.new()
	batch.position = Vector2(160, 0)
	viewport.add_child(batch)
	batch.set_process(false)
	var number := batch.acquire(SCENE)
	number.show_amount(Vector2.ZERO, 123)
	number.render_transform = Transform2D(0, Vector2(20, 20))
	for frame in 3:
		await process_frame
	await RenderingServer.frame_post_draw
	var image := viewport.get_texture().get_image()
	var original := image.get_region(Rect2i(0, 0, 160, 80))
	var shared := image.get_region(Rect2i(160, 0, 160, 80))
	var differences := 0
	var painted := 0
	for y in 80:
		for x in 160:
			var left := original.get_pixel(x, y)
			var right := shared.get_pixel(x, y)
			if left.a > 0.1:
				painted += 1
			if absf(left.a - right.a) > 0.1:
				differences += 1
	check(painted > 100 and differences < 20, "shared text differs from Label font, size, alignment or outline")
	image.save_png("res://.godot/damage_text_comparison.png")
	viewport.free()
