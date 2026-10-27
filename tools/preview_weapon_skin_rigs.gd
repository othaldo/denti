extends SceneTree

const OUTPUT := "res://docs/screenshots/weapon_skins/"
const ELEMENTS := [&"", &"fire", &"ice", &"poison", &"electric", &"bleed", &"wet"]
var heads: Array[WeaponWorkingHead] = []
var slings: Array[WeaponElastic] = []


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1960, 1100)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(viewport)
	var board := Control.new()
	board.theme = DentiUIStyle.make_theme()
	viewport.add_child(board)
	var background := ColorRect.new()
	background.size = viewport.size
	background.color = DentiUIStyle.BACKGROUND
	board.add_child(background)
	_label(board, "Waffen im Spiel · Animationsteile", Vector2(24, 16), 30)
	var ids := [&"cavity_grinder", &"prophylaxis_polisher", &"amalgam_slingshot"]
	for row in ids.size():
		var template := WeaponCatalog.by_id(ids[row])
		_label(board, template.display_name, Vector2(24, 72 + row * 336), 23)
		for column in ELEMENTS.size():
			var element: StringName = ELEMENTS[column]
			var data := WeaponSkins.with_element(template, element)
			var panel := Panel.new()
			panel.position = Vector2(24 + column * 274, 110 + row * 336)
			panel.size = Vector2(260, 284)
			panel.add_theme_stylebox_override("panel", MenuStyle.box(DentiUIStyle.PANEL, DentiUIStyle.LINE, 14, 1))
			board.add_child(panel)
			_label(panel, "Normal" if element == &"" else WeaponAffixes.by_id(element).display_name, Vector2(14, 8), 19)
			var tool := Node2D.new()
			tool.scale = Vector2.ONE * 0.43
			tool.position = Vector2(130, 154) + (data.grip_anchor - Vector2.ONE * 0.5) * 512 * 0.43
			panel.add_child(tool)
			var body := Sprite2D.new()
			body.texture = data.held_texture()
			body.offset = (Vector2.ONE * 0.5 - data.grip_anchor) * body.texture.get_size()
			body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			tool.add_child(body)
			if data.working_head_texture != null:
				var head := WeaponWorkingHead.new()
				head.configure(data)
				body.add_child(head)
				heads.append(head)
			if data.pull_texture != null:
				var sling := WeaponElastic.new()
				sling.configure(data)
				body.add_child(sling)
				slings.append(sling)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	DirAccess.make_dir_recursive_absolute("res://.godot/weapon_skin_rig_frames")
	for frame in 32:
		for head in heads:
			head.advance(TAU / 32.0)
		for sling in slings:
			sling.set_progress(float(frame) / 31.0)
		await process_frame
		await RenderingServer.frame_post_draw
		var captured := viewport.get_texture().get_image()
		captured.save_png("res://.godot/weapon_skin_rig_frames/%02d.png" % frame)
		if frame == 0:
			captured.save_png(OUTPUT + "animation_parts.png")
	viewport.free()
	print("PASS native skin rigs: 14 rotating heads and seven elastic slings")
	quit()


func _label(parent: Node, value: String, at: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
