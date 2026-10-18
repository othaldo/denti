extends "res://tests/support/test_runtime.gd"

func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var extent := Vector2i(672, 272)
	root.content_scale_size = extent
	DisplayServer.window_set_size(extent)
	root.size = extent
	var canvas := ColorRect.new()
	canvas.color = DentiUIStyle.BACKGROUND
	canvas.size = Vector2(extent)
	canvas.theme = DentiUIStyle.make_theme()
	root.add_child(canvas)
	_caption(canvas, "Gemalte HUD-Symbole", Rect2(16, 12, 640, 30), 20)
	var ids: Array[StringName] = [&"poison", &"bleed", &"shield", &"inflammation", &"pause"]
	var names: Array[String] = ["Gift", "Blutung", "Schild", "Entzündung", "Pause"]
	for index in ids.size():
		var center := 88.0 + index * 124
		var texture := HUDStatusIcons.texture(ids[index])
		_icon(canvas, texture, Rect2(center - 32, 56, 64, 64))
		var actual := 18 if index == 3 else 22 if index == 4 else 24
		_icon(canvas, texture, Rect2(center - actual * 0.5, 158 - actual * 0.5, actual, actual))
		_caption(canvas, names[index], Rect2(center - 60, 184, 120, 24), 14)
	_caption(canvas, "Oben vergrößert · unten in tatsächlicher HUD-Größe", Rect2(16, 232, 640, 24), 14)
	for frame in 8:
		await process_frame
	await RenderingServer.frame_post_draw
	var path := ProjectSettings.globalize_path("res://docs/screenshots/combat_hud/painted_icons.png")
	root.get_texture().get_image().save_png(path)
	print(path)
	finish()


func _icon(parent: Node, texture: Texture2D, rect: Rect2) -> void:
	var icon := TextureRect.new()
	icon.texture = texture
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	parent.add_child(icon)
	icon.position = rect.position
	icon.size = rect.size


func _caption(parent: Node, text: String, rect: Rect2, font_size: int) -> void:
	var caption := Label.new()
	caption.text = text
	caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	caption.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	DentiUIStyle.style_hud_text(caption, DentiUIStyle.INK, font_size, 1)
	parent.add_child(caption)
	caption.position = rect.position
	caption.size = rect.size
