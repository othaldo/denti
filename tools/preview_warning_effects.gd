extends SceneTree
## The charge comparison uses the retained old atlas row and the real new path.

class Study extends Node2D:
	var progress := 0.0
	func _draw() -> void:
		for row in 3:
			var width: float = [17.0, 73.0, 119.0][row]
			for column in 2:
				var at := Vector2(50 + column * 640, 195 + row * 220)
				var end := at + Vector2(500, 0)
				var tint := Color(1, 0.34, 0.26, 0.85)
				if column == 0:
					AttackEffects.strip(self, AttackEffects.Shape.LANE, at, end, width * 2 / AttackEffects.LANE_EDGE, Color(tint, tint.a * lerpf(0.55, 1, progress)), progress * 0.6)
				else:
					AttackEffects.lane(self, at, end, width, tint, progress)
				AttackEffects.warning_ring(self, at, 27, progress, Color(1, 0.72, 0.27))

func _initialize() -> void: call_deferred("_run")

func _label(parent: Node, text: String, at: Vector2, size := 22) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("fff1ce"))
	label.add_theme_color_override("font_shadow_color", Color("302a3b"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1280, 820)
	root.content_scale_size = root.size
	var study := Study.new()
	root.add_child(study)
	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = DentiArena.FLOOR
	floor_sprite.centered = false
	floor_sprite.scale = Vector2(root.size) / floor_sprite.texture.get_size()
	floor_sprite.show_behind_parent = true
	study.add_child(floor_sprite)
	_label(study, "Bisher: gestreckte Rissgrafik", Vector2(36, 25), 27)
	_label(study, "Neu: feste Enden, gekachelte Mitte", Vector2(660, 25), 27)
	for row in 3:
		_label(study, ["Schmaler Ansturm", "Geschossbahn", "Breite Boss-Charge"][row], Vector2(36, 85 + row * 220))
	var output := "res://.godot/warning_preview"
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(output.path_join("frames")))
	for frame in 90:
		study.progress = float(frame) / 89.0
		study.queue_redraw()
		for tick in 2: await process_frame
		await RenderingServer.frame_post_draw
		var shot := root.get_texture().get_image()
		shot.save_png(output.path_join("frames/%03d.png" % frame))
		if frame == 50: shot.save_png(output.path_join("charge_comparison.png"))
	study.free()
	quit()
