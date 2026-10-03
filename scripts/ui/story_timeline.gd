class_name StoryTimeline
extends VBoxContainer

var progress: StoryProgress
var completed_wave: int = 0
var heading: Label
var previews: HBoxContainer
var preview_images: Array[TextureRect] = []
var preview_labels: Array[Label] = []
var preview_panels: Array[PanelContainer] = []
var route: Control

func _ready() -> void:
	add_theme_constant_override("separation", 4)
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	heading = ShopDetails._label(self, "", 14)
	heading.add_theme_color_override("font_color", DentiUIStyle.GOLD)
	previews = HBoxContainer.new()
	previews.add_theme_constant_override("separation", 6)
	add_child(previews)
	for index in 4:
		var tile := PanelContainer.new()
		tile.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		previews.add_child(tile)
		preview_panels.append(tile)
		var surface := DentiUIStyle.rounded_image_surface(4)
		surface.custom_minimum_size.y = 40
		tile.add_child(surface)
		var image := TextureRect.new()
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_COVERED
		image.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		image.modulate = Color(0.65, 0.65, 0.65)
		surface.add_child(image)
		preview_images.append(image)
		var shade := ColorRect.new()
		shade.color = Color(0.06, 0.04, 0.09, 0.4)
		shade.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		shade.mouse_filter = Control.MOUSE_FILTER_IGNORE
		surface.add_child(shade)
		var label := Label.new()
		label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		label.add_theme_font_size_override("font_size", 12)
		label.add_theme_constant_override("outline_size", 2)
		label.add_theme_color_override("font_outline_color", DentiUIStyle.BACKGROUND)
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		surface.add_child(label)
		preview_labels.append(label)
	route = Control.new()
	route.custom_minimum_size.y = 33
	route.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(route)
	route.draw.connect(_draw_route)
	resized.connect(_refresh_size)

func show_progress(state: StoryProgress, wave: int) -> void:
	progress = state
	completed_wave = mini(wave, 20)
	visible = state.enabled
	if not visible:
		return
	heading.text = "Kapitel %d · %s" % [state.chapter_index + 1, StoryCatalog.chapter(state.chapter_index).title]
	heading.tooltip_text = StoryCatalog.chapter(state.chapter_index).objective
	for index in 4:
		var known := index < state.revealed_chapters
		# Never attach a future texture, name or tooltip to a locked tile.
		preview_images[index].texture = StoryCatalog.chapter_art(index) if known else null
		preview_labels[index].text = StoryCatalog.chapter(index).title if known else "Unentdeckt"
		preview_panels[index].tooltip_text = StoryCatalog.chapter(index).title if known else ""
		var border := DentiUIStyle.GOLD if index == state.chapter_index else DentiUIStyle.LINE
		var surface := DentiUIStyle._box(DentiUIStyle.PANEL, border, 8, 1)
		surface.content_margin_left = 4
		surface.content_margin_right = 4
		surface.content_margin_top = 3
		surface.content_margin_bottom = 3
		preview_panels[index].add_theme_stylebox_override("panel", surface)
	_refresh_size()
	route.queue_redraw()

func _refresh_size() -> void:
	var small := size.x < 650
	# Short landscape screens retain the complete route but omit thumbnails.
	previews.visible = get_viewport().get_visible_rect().size.y >= 480
	for index in preview_panels.size():
		preview_panels[index].get_child(0).custom_minimum_size.y = 28 if small else 40
		preview_labels[index].add_theme_font_size_override("font_size", 10 if small else 12)
	route.queue_redraw()

func _draw_route() -> void:
	if progress == null or not progress.enabled:
		return
	var left := 10.0
	var stride := maxf((route.size.x - 20.0) / 19.0, 1)
	var y := 11.0
	route.draw_line(Vector2(left, y), Vector2(left + stride * 19, y), DentiUIStyle.LINE, 2)
	if completed_wave > 0:
		route.draw_line(Vector2(left, y), Vector2(left + stride * (completed_wave - 1), y), DentiUIStyle.GOLD, 2)
	for wave in range(1, 21):
		var pos := Vector2(left + stride * (wave - 1), y)
		var boss_node := wave % 5 == 0
		var radius := 8.0 if boss_node else 3.0
		var done := wave <= completed_wave
		var color := DentiUIStyle.GOLD if done else DentiUIStyle.LINE
		route.draw_circle(pos, radius, color)
		if wave == completed_wave + 1:
			route.draw_arc(pos, radius + 3, 0, TAU, 32, DentiUIStyle.INK, 1.5, true)
		if boss_node:
			if done:
				route.draw_line(pos + Vector2(-3, 0), pos + Vector2(-1, 3), DentiUIStyle.GOLD_INK, 1.5, true)
				route.draw_line(pos + Vector2(-1, 3), pos + Vector2(4, -3), DentiUIStyle.GOLD_INK, 1.5, true)
			else:
				route.draw_circle(pos, 3, DentiUIStyle.MUTED, false, 1)
			route.draw_string(DentiUIStyle.FONT, pos + Vector2(-8, 21), str(wave), HORIZONTAL_ALIGNMENT_CENTER, 16, 11, DentiUIStyle.MUTED)
