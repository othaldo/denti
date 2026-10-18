extends "res://tests/support/test_runtime.gd"

# Enlarged native render of the exact in-game component, not a mock animation.
func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.content_scale_size = Vector2i(384, 448)
	DisplayServer.window_set_size(Vector2i(384, 448))
	root.size = Vector2i(384, 448)
	root.get_node("GameSession").reduced_ui_motion = false
	var background := ColorRect.new()
	background.color = DentiUIStyle.BACKGROUND
	background.size = Vector2(384, 448)
	root.add_child(background)
	var vessel := HUDToothVessel.new()
	root.add_child(vessel)
	vessel.position = Vector2(12, 10)
	vessel.size = Vector2(120, 140)
	vessel.scale = Vector2.ONE * 3
	vessel.show_value(100, 100, "100 / 100")
	var directory := ProjectSettings.globalize_path("res://.godot/tooth_animation_frames")
	DirAccess.make_dir_recursive_absolute(directory)
	for frame in 240:
		if frame in [40, 100, 150, 190]:
			var value: int = {40: 35, 100: 75, 150: 10, 190: 100}[frame]
			vessel.show_value(value, 100, "%d / 100" % value)
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(directory.path_join("frame_%03d.png" % frame))
	print("Native animation frames: " + directory)
	finish()
