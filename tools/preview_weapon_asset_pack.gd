extends SceneTree
## Renders a staged seven-image weapon pack without loading gameplay or .tres files.

const ROOT := "res://assets/weapons/reference/element_forms/"
const OUTPUT := "res://docs/screenshots/weapon_elements/"
const DESCRIPTIONS := {
	"normal": "Original",
	"fire": "Flammenborsten",
	"ice": "Kristallkopf",
	"poison": "Gifttank",
	"electric": "Spulen & Blitzborsten",
	"bleed": "Rubinborsten & Dornen",
	"wet": "Wellenborsten & Wasser",
}
const COLORS := {
	"normal": Color("eee7f1"), "fire": Color("ff9b4a"),
	"ice": Color("9bdfff"), "poison": Color("b5ed66"),
	"electric": Color("ffe06a"), "bleed": Color("ff7c9f"),
	"wet": Color("69dbed"),
}


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var weapon_id := "magic_toothbrush"
	for argument in OS.get_cmdline_user_args():
		if argument.begins_with("--weapon="): weapon_id = argument.trim_prefix("--weapon=")
	var folder := ROOT + weapon_id + "/"
	var manifest: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(folder + "manifest.json"))
	assert(manifest.variants.size() == 7)
	var crop_values: Array = manifest.get("preview_region", [300, 0, 480, 1536])
	var preview_region := Rect2(float(crop_values[0]), float(crop_values[1]), float(crop_values[2]), float(crop_values[3]))
	var preview_size: int = int(manifest.get("preview_size_px", 70))
	root.title = "Denti · " + str(manifest.display_name) + " · Assetpaket"
	root.content_scale_size = Vector2i(1920, 960)
	root.size = Vector2i(1920, 960)
	var board := Control.new()
	board.theme = DentiUIStyle.make_theme()
	root.add_child(board)
	board.size = Vector2(1920, 960)
	var background := ColorRect.new()
	background.color = DentiUIStyle.BACKGROUND
	background.size = board.size
	board.add_child(background)
	_label(board, str(manifest.display_name) + " · vollständiges Assetpaket", Rect2(32, 24, 1856, 50), 38)
	_label(board, "7 Einzelbilder · jeweils 1024 × 1536 px · transparente PNGs", Rect2(32, 80, 1856, 32), 22, DentiUIStyle.MUTED)
	var width := (1856.0 - 6 * 12) / 7
	var index := 0
	for variant: Dictionary in manifest.variants:
		var panel := Panel.new()
		var color: Color = COLORS.get(variant.id, DentiUIStyle.GOLD)
		panel.add_theme_stylebox_override("panel", MenuStyle.box(DentiUIStyle.PANEL, color, 18, 2))
		board.add_child(panel)
		panel.position = Vector2(32 + index * (width + 12), 132)
		panel.size = Vector2(width, 752)
		_label(panel, variant.label, Rect2(20, 14, width - 40, 36), 26, color)
		_label(panel, str(variant.get("description", DESCRIPTIONS.get(variant.id, ""))), Rect2(20, 54, width - 40, 28), 16, DentiUIStyle.MUTED)
		var image := Image.load_from_file(folder + str(variant.file))
		assert(image.get_size() == Vector2i(1024, 1536))
		image.generate_mipmaps()
		var texture := ImageTexture.create_from_image(image)
		# Same review crop for all seven. Asset PNG dimensions and pixels stay intact.
		var crop := AtlasTexture.new()
		crop.atlas = texture
		crop.region = preview_region
		_art(panel, crop, Rect2(24, 92, width - 48, 500))
		_label(panel, "Spritegröße\n%d px" % preview_size, Rect2(20, 614, width - 92, 70), 17, DentiUIStyle.MUTED)
		_art(panel, texture, Rect2(width - 70, 614 + (70 - preview_size) / 2.0, preview_size * 2.0 / 3.0, preview_size))
		_label(panel, variant.file, Rect2(20, 708, width - 40, 26), 16, DentiUIStyle.MUTED)
		index += 1
	_label(board, "Normal + Feuer + Eis + Gift + Elektro + Blut + Wasser · Assetphase, noch ohne Spieleinbindung", Rect2(32, 908, 1856, 30), 19, DentiUIStyle.MUTED)
	for frame in 12: await process_frame
	await RenderingServer.frame_post_draw
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	var captured := root.get_texture().get_image()
	assert(captured != null and not captured.is_empty())
	captured.save_png(OUTPUT + weapon_id + "_complete_pack.png")
	print("PASS complete weapon asset pack: seven equal RGBA canvases, native preview and %dpx sprite scale" % preview_size)
	if "--interactive" not in OS.get_cmdline_user_args(): quit()


func _label(parent: Control, value: String, rect: Rect2, font_size: int, color: Color = DentiUIStyle.INK) -> void:
	var label := Label.new()
	label.text = value
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
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
