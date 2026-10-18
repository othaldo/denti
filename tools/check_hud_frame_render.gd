extends "res://tests/support/test_runtime.gd"

# Native rendering regression: changing width must leave both painted caps
# pixel-identical. Headless layout tests cannot detect texture deformation.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = Vector2i(680, 260)
	DisplayServer.window_set_size(Vector2i(680, 260))
	root.size = Vector2i(680, 260)
	var background := ColorRect.new()
	background.color = DentiUIStyle.BACKGROUND
	background.size = Vector2(680, 260)
	root.add_child(background)
	var frames: Array[HUDPaintedFrame] = []
	for index in 3:
		var frame := HUDPaintedFrame.new("res://assets/ui/boss_hud_frame.png")
		frame.position = Vector2(20, 20 + index * 80)
		frame.size = Vector2([240, 360, 600][index], 48)
		root.add_child(frame)
		frames.append(frame)
	for tick in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var screenshot := root.get_texture().get_image()
	var matches := true
	var cap := floori(frames[0].cap_width())
	for index in range(1, frames.size()):
		for y in 48:
			for x in cap:
				for side in 2:
					var base_x := 20 + x + (240 - cap if side == 1 else 0)
					var test_x := 20 + x + (int(frames[index].size.x) - cap if side == 1 else 0)
					var original := screenshot.get_pixel(base_x, 20 + y)
					var rendered := screenshot.get_pixel(test_x, 20 + index * 80 + y)
					if not original.is_equal_approx(rendered):
						matches = false
	var directory := ProjectSettings.globalize_path("res://.godot/hud_frame_check")
	DirAccess.make_dir_recursive_absolute(directory)
	screenshot.save_png(directory.path_join("frame_widths.png"))
	if matches:
		print("Native frame check: both painted caps are pixel-identical at 240, 360 and 600 px width")
	else:
		push_error("Painted frame caps change when only width changes")
	finish(0 if matches else 1)
