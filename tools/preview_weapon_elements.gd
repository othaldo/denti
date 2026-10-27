extends SceneTree
## Art review only. Does not replace the equipped weapon or touch a run save.

const OUTPUT := "res://docs/screenshots/weapon_elements/"
const FORMS := [
	["fire", "Feuer", "Flammenborsten", Color("ff9b4a")],
	["ice", "Eis", "Kristallkopf", Color("9bdfff")],
	["poison", "Gift", "Gifttank", Color("b5ed66")],
	["electric", "Elektro", "Spulen & Blitzborsten", Color("ffe06a")],
]


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.title = "Denti · Zauberbürste · Elementformen"
	root.content_scale_size = Vector2i(1280, 800)
	root.size = Vector2i(1280, 800)
	var board := Control.new()
	board.theme = DentiUIStyle.make_theme()
	root.add_child(board)
	board.size = Vector2(1280, 800)
	var background := ColorRect.new()
	background.color = DentiUIStyle.BACKGROUND
	background.size = board.size
	board.add_child(background)
	_label(board, "Zauberbürste · Elementformen", Rect2(40, 28, 1200, 48), 34)
	_label(board, "Vier Entwürfe · gleiche Grundwaffe, eigene Köpfe und Materialien", Rect2(40, 82, 1200, 30), 19, DentiUIStyle.MUTED)
	for index in FORMS.size():
		var form: Array = FORMS[index]
		var panel := Panel.new()
		panel.add_theme_stylebox_override("panel", MenuStyle.box(DentiUIStyle.PANEL, form[3], 18, 2))
		board.add_child(panel)
		panel.position = Vector2(40 + index * 304, 130)
		panel.size = Vector2(288, 584)
		_label(panel, form[1], Rect2(20, 12, 248, 34), 25, form[3])
		_label(panel, form[2], Rect2(20, 48, 248, 26), 16, DentiUIStyle.MUTED)
		var image := Image.load_from_file("res://docs/art/weapon_elements/zauberbuerste_%s.png" % form[0])
		image.generate_mipmaps()
		var source := ImageTexture.create_from_image(image)
		# Review crop only: the underlying generated PNG and its grip remain intact.
		var crop := AtlasTexture.new()
		crop.atlas = source
		crop.region = Rect2(320, 0, 460, 1536)
		_art(panel, crop, Rect2(50, 82, 188, 396))
		_label(panel, "Kampfgröße · 70 px", Rect2(20, 484, 168, 70), 16, DentiUIStyle.MUTED)
		_art(panel, source, Rect2(202, 484, 47, 70))
	_label(board, "Grafikstudie · noch nicht als Waffenform im Spiel aktiviert", Rect2(40, 736, 1200, 30), 17, DentiUIStyle.MUTED)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var captured := root.get_texture().get_image()
	if captured == null or captured.is_empty():
		push_error("Element preview requires a rendering display")
		quit(1)
		return
	captured.save_png(OUTPUT + "zauberbuerste_four_forms.png")
	print("PASS four native element-form previews, including original 70px combat scale")
	if "--interactive" not in OS.get_cmdline_user_args(): quit()


func _label(parent: Control, value: String, rect: Rect2, font_size: int, color: Color = DentiUIStyle.INK) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	parent.add_child(label)
	label.position = rect.position
	label.size = rect.size


func _art(parent: Control, texture: Texture2D, rect: Rect2) -> void:
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	parent.add_child(art)
	art.position = rect.position
	art.size = rect.size
