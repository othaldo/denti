extends SceneTree

class PreviewUpdates extends GameUpdateService:
	func can_update() -> bool: return true

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	var output := "res://.godot/updater-preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output))
	var service := PreviewUpdates.new()
	root.add_child(service)
	service.current_version = "0.5.0"
	service.available = {"version": "0.6.0", "assets": {"windows-x86_64": {"size": 170000000}}}
	var control := Control.new()
	root.add_child(control)
	control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	MenuStyle.backdrop(control, false)
	var stage := MenuStage.new()
	control.add_child(stage)
	for extent in [Vector2i(1280, 720), Vector2i(360, 640)]:
		root.size = extent
		root.content_scale_size = root.get_node("GameSession").mobile_base_size(extent) if extent.x < 700 else Vector2i(1280, 720)
		DisplayServer.window_set_size(extent)
		var view := MenuUpdates.new()
		stage.present("Updates", view, "", 680)
		view.configure(service)
		for state in [service.State.AVAILABLE, service.State.DOWNLOADING, service.State.READY, service.State.ERROR]:
			service.state = state
			service.progress = 62
			service.message = "Download unterbrochen. Bitte erneut versuchen."
			service.changed.emit()
			for frame in 10: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(output.path_join("%s_%dx%d.png" % [service.State.keys()[state].to_lower(), extent.x, extent.y]))
	control.queue_free()
	service.queue_free()
	await process_frame
	quit()
