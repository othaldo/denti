extends "res://tests/support/test_runtime.gd"

# Compare the actual, integrated tooth component on light and dark floors.
func _initialize() -> void:
	call_deferred("_run")


func _caption(text: String, rect: Rect2, font_size: int = 18) -> void:
	var label := Label.new()
	label.text = text
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	DentiUIStyle.style_hud_text(label, DentiUIStyle.INK, font_size, 3, DentiUIStyle.BACKGROUND)
	root.add_child(label)


func _run() -> void:
	root.content_scale_size = Vector2i(1024, 600)
	DisplayServer.window_set_size(Vector2i(1024, 600))
	root.size = Vector2i(1024, 600)
	root.get_node("GameSession").reduced_ui_motion = false
	var background := ColorRect.new()
	background.color = DentiUIStyle.BACKGROUND
	background.size = Vector2(1024, 600)
	root.add_child(background)
	var floor := TextureRect.new()
	floor.texture = load("res://assets/environment/dental_arena_floor.png")
	floor.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	floor.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
	floor.position = Vector2(0, 350)
	floor.size = Vector2(1024, 250)
	root.add_child(floor)
	_caption("Schutzhülle · vergrößert", Rect2(0, 12, 1024, 28), 16)
	_caption("Tatsächliche HUD-Größe · heller Arenaboden", Rect2(0, 360, 1024, 28), 14)
	var counts := [0, 1, 3, 5]
	for index in counts.size():
		var count: int = counts[index]
		_caption("Ohne Schild" if count == 0 else "%d Schild%s" % [count, "" if count == 1 else "e"], Rect2(index * 256, 62, 256, 28))
		for enlarged in [true, false]:
			var vessel := HUDToothVessel.new()
			root.add_child(vessel)
			vessel.position = Vector2(index * 256 + (26 if enlarged else 64), 130 if enlarged else 430)
			vessel.size = Vector2(128, 108)
			vessel.scale = Vector2.ONE * (1.6 if enlarged else 1.0)
			vessel.show_value(61, 100, "61 / 100")
			vessel.show_shield(count)
	var directory := ProjectSettings.globalize_path("res://docs/screenshots/shield_aura")
	DirAccess.make_dir_recursive_absolute(directory)
	var frames := ProjectSettings.globalize_path("res://.godot/shield_smooth_frames")
	DirAccess.make_dir_recursive_absolute(frames)
	for frame in 120:
		await process_frame
		await RenderingServer.frame_post_draw
		var screenshot := root.get_texture().get_image()
		screenshot.save_png(frames.path_join("frame_%03d.png" % frame))
		if frame == 30:
			screenshot.save_png(directory.path_join("shield_comparison.png"))
	print("Native shield comparison: " + directory)
	finish()
