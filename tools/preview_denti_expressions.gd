extends SceneTree

const LABELS := ["Normal", "Blinzeln", "Autsch!", "Heilung", "Wenig HP", "Schildblock", "Jubel", "Tod", "Vergiftet", "Blutend", "Ausweichen", "Gift + Blutung"]

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.content_scale_size = Vector2i(1200, 850)
	root.size = Vector2i(1200, 850)
	DisplayServer.window_set_size(root.size)
	var background := ColorRect.new()
	background.color = Color("fff7e5")
	background.size = Vector2(root.size)
	root.add_child(background)
	var title := Label.new()
	title.text = "Denti · Gesichtsausdrücke"
	title.position = Vector2(24, 12)
	title.add_theme_font_override("font", DentiUIStyle.FONT)
	title.add_theme_font_size_override("font_size", 29)
	title.add_theme_color_override("font_color", DentiUIStyle.INK)
	root.add_child(title)
	for index in LABELS.size():
		var origin := Vector2((index % 4) * 300, floori(index / 4.0) * 255 + 75)
		var label := Label.new()
		label.text = LABELS[index]
		label.position = origin + Vector2(22, 5)
		label.add_theme_font_override("font", DentiUIStyle.FONT)
		label.add_theme_font_size_override("font_size", 23)
		label.add_theme_color_override("font_color", DentiUIStyle.INK)
		root.add_child(label)
		for size in [85.76, 170.0]:
			var sprite := Sprite2D.new()
			sprite.texture = preload("res://assets/denti/denti_unarmed.png")
			sprite.scale = Vector2.ONE * size / 1280.0
			sprite.position = origin + Vector2(70 if size < 100 else 207, 136)
			var expressions := DentiExpressions.new()
			sprite.add_child(expressions)
			root.add_child(sprite)
			expressions.set_process(false)
			if index in [8, 11]:
				expressions.set_status(DentiExpressions.Status.POISON)
			if index in [9, 11]:
				expressions.set_status(DentiExpressions.Status.BLEED)
			expressions._set_face(index)
	for frame in 8:
		await process_frame
	var path := "res://docs/screenshots/denti_expressions.png"
	root.get_texture().get_image().save_png(ProjectSettings.globalize_path(path))
	print(path)
	quit()
