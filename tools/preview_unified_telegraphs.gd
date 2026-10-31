extends "res://tests/support/test_runtime.gd"
const OUTPUT := "res://.godot/unified_telegraphs"
class Gallery extends Node2D:
	var progress := 0.78
	func _draw() -> void:
		WarningEffects.circle(self, Vector2(160, 280), 95, progress, Color(1, 0.43, 0.18))
		WarningEffects.ring(self, Vector2(480, 280), 48, 95, progress, false, false, Transform2D.IDENTITY, Color(1, 0.32, 0.53))
		WarningEffects.sector(self, Vector2(730, 280), Vector2.RIGHT, 150, deg_to_rad(57), progress, false, false, Transform2D.IDENTITY, Color(0.72, 0.46, 1))
		WarningEffects.timer(self, Vector2(1120, 280), 95, progress, Color(0.3, 0.86, 1))
		WarningEffects.lane(self, Vector2(45, 600), Vector2(275, 535), 35, Color(1, 0.43, 0.18), progress)
		WarningEffects.capsule(self, Vector2(420, 585), Vector2(540, 555), 43, Color(0.66, 0.94, 0.15), progress)
		WarningEffects.rectangle(self, Rect2(700, 510, 200, 125), progress, Color(1, 0.69, 0.23))
		for end in [Vector2(1235, 525), Vector2(1235, 615)]:
			WarningEffects.aim(self, Vector2(1010, 570), end, Color(1, 0.32, 0.53), progress)
		WarningEffects.timer(self, Vector2(1010, 570), 20, progress, Color(1, 0.32, 0.53))
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	if DisplayServer.get_name() == "headless": finish(1); return
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1280, 760)
	root.content_scale_size = root.size
	var floor := DentiArena.new()
	floor.z_index = -100
	root.add_child(floor)
	var shade := ColorRect.new()
	shade.size = Vector2(1280, 760)
	shade.color = Color(0.035, 0.04, 0.07, 0.48)
	root.add_child(shade)
	var gallery := Gallery.new()
	root.add_child(gallery)
	_label("EINE SPRACHE FÜR ALLE WARNFLÄCHEN", Vector2(35, 24), 29)
	_label("Klare Kontur · bewegtes Licht · beschleunigtes Aufladen", Vector2(35, 70), 20)
	var names := ["Kreis", "Ring · sichere Mitte", "Sektor", "Timer", "Charge / Bahn", "Säure / Kapsel", "Kissen / Rechteck", "Zielstrahlen"]
	for index in names.size(): _label(names[index], Vector2(35 + index % 4 * 320, 125 + (index / 4) * 310), 22)
	var phase := _label("", Vector2(35, 710), 20)
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for frame in 12: await process_frame
	for step in [0.25, 0.60, 0.90]:
		gallery.progress = step
		phase.text = "Aufladen: %d %%" % roundi(step * 100)
		gallery.queue_redraw()
		for frame in 3: await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png(OUTPUT.path_join("shapes_%02d.png" % roundi(step * 100)))
	if "--video" in OS.get_cmdline_user_args():
		for frame in 100:
			gallery.progress = minf(frame / 84.0, 1.0)
			phase.text = "Aufladen: %d %%" % roundi(gallery.progress * 100)
			gallery.queue_redraw()
			await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUTPUT.path_join("frame_%03d.png" % frame))
	print("PASS unified native gallery: eight forms rendered")
	finish()
func _label(value: String, at: Vector2, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("fff1dc"))
	label.add_theme_color_override("font_shadow_color", Color("201d29"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	root.add_child(label)
	return label
