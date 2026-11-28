extends SceneTree

## Godot --path . --script res://tools/preview_denti_walk.gd
## Add -- --capture for both comparison pages, or -- --play to control Denti.
const ROOT_MOTION := preload("res://scripts/player/denti_root_motion.gdshader")
const ATLAS_BY_CLASS := {
	&"good_old_molar": "res://tools/art/denti_turnaround_prototype.png",
	&"assassin": "res://tools/art/assassin_turnaround_prototype.png",
	&"tooth_fairy": "res://tools/art/tooth_fairy_turnaround_prototype.png",
	&"ember": "res://tools/art/ember_turnaround_prototype.png",
	&"rinser": "res://tools/art/rinser_turnaround_prototype.png",
	&"frost_warden": "res://tools/art/frost_warden_turnaround_prototype.png",
	&"necrodent": "res://tools/art/necrodent_turnaround_prototype.png",
	&"herb_druid": "res://tools/art/herb_druid_turnaround_prototype.png",
}
# These classes have equipment fixed to one hand. Keep the painted poses on
# both sides of the compass so a turn cannot swap the hands holding it.
const EAST_ATLAS_BY_CLASS := {
	&"tooth_fairy": "res://tools/art/tooth_fairy_east_turnaround_prototype.png",
	&"rinser": "res://tools/art/rinser_east_turnaround_prototype.png",
	&"frost_warden": "res://tools/art/frost_warden_east_turnaround_prototype.png",
}
const CELL_BY_HEADING := [4, 3, 2, 1, 0, 1, 2, 3]
const ROOT_SPLIT_BY_CELL: Array[float] = [0.50, 0.47, 0.32, 0.50, 0.50]
const PROFILE_ROOT_SPLIT := {
	&"ember": 0.36,
	&"rinser": 0.42,
	&"frost_warden": 0.39,
	&"necrodent": 0.47,
	&"herb_druid": 0.41,
}
# Long hems, wings and equipment reach farther down the painted silhouette.
const ROOT_START_BY_CLASS := {
	&"tooth_fairy": 0.74,
	&"ember": 0.78,
	&"rinser": 0.75,
	&"frost_warden": 0.78,
	&"necrodent": 0.75,
	&"herb_druid": 0.80,
}
const HEADING_NAMES := ["N", "NO", "O", "SO", "S", "SW", "W", "NW"]
const PLAY_SIZE := Vector2i(960, 404)
const COMPARE_SIZE := Vector2i(960, 660)
const PANEL := Vector2(106, 108)
const ROWS_PER_PAGE := 4
const BODY_HEIGHT := 76.0
const WALK_CYCLE := 80.0
const FPS := 30
const LOOP_FRAMES := 48
const INK := Color("483246")


class WalkLook extends RefCounted:
	var display_name: String
	var textures: Array[Texture2D] = []
	var root_split: Array[float] = []
	var mirror_east := true
	var root_start := 0.70


class Walker extends Node2D:
	var body := Sprite2D.new()
	var motion := ShaderMaterial.new()

	func _ready() -> void:
		var gradient := Gradient.new()
		gradient.colors = PackedColorArray([Color("30233878"), Color("30233800")])
		var shade := GradientTexture2D.new()
		shade.gradient = gradient
		shade.fill = GradientTexture2D.FILL_RADIAL
		shade.fill_from = Vector2(0.5, 0.5)
		shade.fill_to = Vector2(1, 0.5)
		shade.width = 74
		shade.height = 21
		var shadow := Sprite2D.new()
		shadow.texture = shade
		add_child(shadow)
		motion.shader = ROOT_MOTION
		body.material = motion
		body.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		add_child(body)

	func pose(look: WalkLook, heading: int, phase: float, weight: float) -> void:
		body.texture = look.textures[heading]
		body.flip_h = look.mirror_east and heading >= 1 and heading <= 3
		var horizontal := sin(heading * TAU / 8)
		var step := sin(phase)
		var lift := Vector2(maxf(step, 0.0), maxf(-step, 0.0)) * weight
		motion.set_shader_parameter("root_split", look.root_split[heading])
		motion.set_shader_parameter("root_start", look.root_start)
		motion.set_shader_parameter("root_lift", lift * 0.092)
		var reach := lerpf(0.025, 0.080, absf(horizontal))
		motion.set_shader_parameter("root_swing", Vector2(-1, 1) * cos(phase) * weight * reach)
		var bounce := absf(step) * weight
		var lean := (horizontal * 0.065 + step * 0.065) * weight
		var shape := Vector2(1.0 - bounce * 0.038, 1.0 + bounce * 0.038)
		var deformation := Transform2D(lean, shape, 0.0, Vector2.ZERO)
		# Padding is one tenth of the painted height on each side.
		var painted_height := body.texture.get_height() / 1.2
		body.scale = shape * (BODY_HEIGHT / painted_height)
		body.rotation = lean
		body.position = -deformation.basis_xform(Vector2(0, BODY_HEIGHT * 0.5)) - Vector2(0, bounce * 2.5)


func _initialize() -> void:
	_run.call_deferred()


func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("The Denti walk preview needs a display.")
		quit(1)
		return
	var looks: Array[WalkLook] = []
	for class_id: StringName in ATLAS_BY_CLASS:
		var look := _load_look(class_id)
		if look == null:
			quit(1)
			return
		looks.append(look)
	var args := OS.get_cmdline_user_args()
	var play := args.has("--play")
	var viewport_size := PLAY_SIZE if play else COMPARE_SIZE
	root.title = "Denti läuft in acht Richtungen"
	root.content_scale_size = viewport_size
	root.size = viewport_size
	DisplayServer.window_set_size(viewport_size)
	Engine.max_fps = FPS
	var background := ColorRect.new()
	background.size = Vector2(viewport_size)
	background.color = Color("fff5e4")
	root.add_child(background)
	if play:
		_play(looks)
	else:
		_compare(looks, args.has("--capture"))


func _compare(looks: Array[WalkLook], capture: bool) -> void:
	_label("Denti läuft in acht Richtungen", Rect2(24, 13, 660, 40), 30)
	var pages := _picker(Rect2(726, 17, 210, 36))
	for page in ceili(float(looks.size()) / ROWS_PER_PAGE):
		var first := page * ROWS_PER_PAGE + 1
		pages.add_item("Klassen %d–%d" % [first, mini(first + ROWS_PER_PAGE - 1, looks.size())])
	pages.select(0)
	var walkers: Array[Walker] = []
	var names: Array[Label] = []
	for heading in HEADING_NAMES.size():
		_label(HEADING_NAMES[heading], Rect2(24 + heading * 116, 63, PANEL.x, 24), 18)
	for row in ROWS_PER_PAGE:
		var y := 93 + row * 137
		names.append(_label("", Rect2(24, y, 918, 24), 20))
		for heading in HEADING_NAMES.size():
			var at := Vector2(24 + heading * 116, y + 25)
			_floor(Rect2(at, PANEL))
			var walker := Walker.new()
			walker.position = at + Vector2(PANEL.x * 0.5, 92)
			root.add_child(walker)
			walkers.append(walker)
	var directory := ProjectSettings.globalize_path("res://.godot/denti_walk_roster_frames")
	if capture and DirAccess.make_dir_recursive_absolute(directory) != OK:
		push_error("Could not create " + directory)
		quit(1)
		return
	var frame := 0
	while true:
		@warning_ignore("integer_division")
		var page := frame / LOOP_FRAMES if capture else pages.selected
		if capture:
			pages.select(page)
		var phase := float(frame % LOOP_FRAMES) / LOOP_FRAMES * TAU * 2.0
		for row in names.size():
			var slot := page * ROWS_PER_PAGE + row
			names[row].text = looks[slot].display_name if slot < looks.size() else ""
		for index in walkers.size():
			@warning_ignore("integer_division")
			var slot := page * ROWS_PER_PAGE + index / HEADING_NAMES.size()
			walkers[index].visible = slot < looks.size()
			if walkers[index].visible:
				walkers[index].pose(looks[slot], index % HEADING_NAMES.size(), phase, 1.0)
		await process_frame
		if capture:
			await RenderingServer.frame_post_draw
			var path := directory.path_join("frame_%03d.png" % frame)
			if root.get_texture().get_image().save_png(path) != OK:
				push_error("Could not save " + path)
				quit(1)
				return
			if frame == LOOP_FRAMES * pages.item_count - 1:
				print("Native animation frames: " + directory)
				quit()
				return
		frame = (frame + 1) % (LOOP_FRAMES * pages.item_count)


func _play(looks: Array[WalkLook]) -> void:
	var classes := _picker(Rect2(24, 16, 255, 36))
	for index in looks.size():
		classes.add_item("%d · %s" % [index + 1, looks[index].display_name])
	classes.select(0)
	_label("WASD / Pfeiltasten · 1–8 Klasse wechseln", Rect2(299, 16, 637, 36), 22)
	var field := Rect2(24, 66, 912, 314)
	_floor(field)
	var walker := Walker.new()
	walker.position = field.get_center() + Vector2(0, BODY_HEIGHT * 0.5)
	root.add_child(walker)
	var bounds := field.grow_individual(-45.0, -BODY_HEIGHT - 10.0, -45.0, -16.0)
	var heading := 4
	var phase := 0.0
	var weight := 0.0
	while true:
		var delta := minf(root.get_process_delta_time(), 0.05)
		for index in classes.item_count:
			if Input.is_physical_key_pressed((KEY_1 + index) as Key):
				classes.select(index)
		var direction := Input.get_vector("move_left", "move_right", "move_up", "move_down")
		if classes.get_popup().visible:
			direction = Vector2.ZERO
		if direction.length_squared() > 0.01:
			heading = posmod(roundi(direction.angle() * 8 / TAU) + 2, 8)
		var previous := walker.position
		walker.position = (walker.position + direction * 200.0 * delta).clamp(bounds.position, bounds.end)
		var distance := walker.position.distance_to(previous)
		phase = fposmod(phase + distance / WALK_CYCLE * TAU, TAU)
		weight = move_toward(weight, 1.0 if distance > 0.01 else 0.0, delta * 9.0)
		walker.pose(looks[classes.selected], heading, phase, weight)
		await process_frame


func _load_look(class_id: StringName) -> WalkLook:
	var original := _load_turnaround(ATLAS_BY_CLASS[class_id], Vector2i(3, 2))
	if original.is_empty():
		return null
	var east: Array[Texture2D] = []
	if EAST_ATLAS_BY_CLASS.has(class_id):
		east = _load_turnaround(EAST_ATLAS_BY_CLASS[class_id], Vector2i(2, 2))
		if east.is_empty():
			return null
	var look := WalkLook.new()
	look.display_name = ClassCatalog.by_id(class_id).display_name
	look.root_start = ROOT_START_BY_CLASS.get(class_id, look.root_start)
	look.mirror_east = east.is_empty()
	var split_by_cell: Array[float] = ROOT_SPLIT_BY_CELL.duplicate()
	split_by_cell[2] = PROFILE_ROOT_SPLIT.get(class_id, split_by_cell[2])
	for heading in HEADING_NAMES.size():
		var cell: int = CELL_BY_HEADING[heading]
		if not look.mirror_east and heading >= 1 and heading <= 3:
			look.textures.append(east[heading - 1])
			look.root_split.append(1.0 - split_by_cell[cell])
		else:
			look.textures.append(original[cell])
			look.root_split.append(split_by_cell[cell])
	return look


func _load_turnaround(path: String, grid: Vector2i) -> Array[Texture2D]:
	# Decode source PNGs so freshly added preview art works before editor import.
	var atlas := Image.new()
	if atlas.load_png_from_buffer(FileAccess.get_file_as_bytes(path)) != OK:
		push_error("Could not load turnaround atlas at " + path)
		return []
	if atlas.get_width() % grid.x != 0 or atlas.get_height() % grid.y != 0:
		push_error("Expected a %d by %d turnaround atlas at %s" % [grid.x, grid.y, path])
		return []
	atlas.convert(Image.FORMAT_RGBA8)
	var cell_size := atlas.get_size() / grid
	var blank := atlas.get_region(Rect2i((grid - Vector2i.ONE) * cell_size, cell_size))
	if _painted_bounds(blank).has_area():
		push_error("Expected a transparent final cell in " + path)
		return []
	var textures: Array[Texture2D] = []
	for index in grid.x * grid.y - 1:
		@warning_ignore("integer_division")
		var origin := Vector2i(index % grid.x, index / grid.x) * cell_size
		var cell := atlas.get_region(Rect2i(origin, cell_size))
		var bounds := _painted_bounds(cell)
		if bounds.has_area() == false:
			push_error("Missing character in cell %d of %s" % [index, path])
			return []
		var padding := ceili(bounds.size.y * 0.10)
		var size := bounds.size + Vector2i.ONE * padding * 2
		var padded := Image.create_empty(size.x, size.y, false, Image.FORMAT_RGBA8)
		padded.blit_rect(cell, bounds, Vector2i.ONE * padding)
		padded.fix_alpha_edges()
		padded.generate_mipmaps()
		textures.append(ImageTexture.create_from_image(padded))
	return textures


func _painted_bounds(cell: Image) -> Rect2i:
	# Ignore faint alpha dust when aligning the five silhouettes on their feet.
	var pixels := cell.get_data()
	var width := cell.get_width()
	var first := cell.get_size()
	var last := Vector2i(-1, -1)
	for y in cell.get_height():
		for x in width:
			if pixels[(y * width + x) * 4 + 3] >= 32:
				first = first.min(Vector2i(x, y))
				last = last.max(Vector2i(x, y))
	return Rect2i(first, (last - first + Vector2i.ONE).max(Vector2i.ZERO))


func _floor(rect: Rect2) -> void:
	var floor := Sprite2D.new()
	floor.position = rect.position
	floor.texture = DentiArena.FLOOR
	floor.region_enabled = true
	floor.region_rect = Rect2((floor.texture.get_size() - rect.size) * 0.5, rect.size)
	floor.centered = false
	root.add_child(floor)


func _picker(rect: Rect2) -> OptionButton:
	var picker := OptionButton.new()
	picker.position = rect.position
	picker.size = rect.size
	picker.theme = DentiUIStyle.make_theme()
	picker.focus_mode = Control.FOCUS_NONE
	root.add_child(picker)
	return picker


func _label(value: String, rect: Rect2, font_size: int) -> Label:
	var label := Label.new()
	label.text = value
	label.position = rect.position
	label.size = rect.size
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_override("font", DentiUIStyle.FONT)
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", INK)
	root.add_child(label)
	return label
