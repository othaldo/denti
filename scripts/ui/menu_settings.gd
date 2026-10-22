class_name MenuSettings
extends VBoxContainer

## The menu stage owns the heading, safe area, scrolling and UI scale.
## This form only presents settings and forwards changes to GameSession.

const TWO_COLUMN_WIDTH := 740.0
const ROW_HEIGHT := 48.0
const LABEL_SIZE := 18

var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var fullscreen_toggle: CheckButton
var fps_toggle: CheckButton
var graphics_option: OptionButton
var ui_sound_toggle: CheckButton
var motion_toggle: CheckButton

var session: Node
var columns: GridContainer
var audio_section: VBoxContainer
var other_sections: VBoxContainer
var _built := false


class SettingToggle extends CheckButton:

	func _draw() -> void:
		var track_rect := Rect2(Vector2(size.x - 44.0, (size.y - 24.0) * 0.5), Vector2(44, 24))
		var fill := DentiUIStyle.GOLD if button_pressed else DentiUIStyle.RAISED.lightened(0.10)
		var track := StyleBoxFlat.new()
		track.bg_color = fill
		track.set_corner_radius_all(12)
		draw_style_box(track, track_rect)
		var knob_x := track_rect.end.x - 12.0 if button_pressed else track_rect.position.x + 12.0
		var knob_color := DentiUIStyle.GOLD_INK if button_pressed else DentiUIStyle.MUTED
		draw_circle(Vector2(knob_x, size.y * 0.5), 8.0, knob_color)


func configure(value: Node) -> void:
	assert(value != null, "MenuSettings needs a GameSession instance.")
	session = value
	if not _built:
		_build()
	_sync_values()


func _ready() -> void:
	resized.connect(_update_columns)
	if get_window() != null:
		get_window().size_changed.connect(_sync_fullscreen)
	_update_columns()


func _build() -> void:
	_built = true
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	add_theme_constant_override("separation", 0)
	columns = GridContainer.new()
	columns.name = "SettingsColumns"
	columns.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	columns.add_theme_constant_override("h_separation", 64)
	columns.add_theme_constant_override("v_separation", 26)
	add_child(columns)
	audio_section = _section("Audio", columns)
	master_slider = _audio_row(audio_section, "Gesamt", "set_master_volume")
	music_slider = _audio_row(audio_section, "Musik", "set_music_volume")
	sfx_slider = _audio_row(audio_section, "SFX", "set_sfx_volume")
	other_sections = VBoxContainer.new()
	other_sections.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	other_sections.add_theme_constant_override("separation", 26)
	columns.add_child(other_sections)
	var display := _section("Darstellung", other_sections)
	fullscreen_toggle = _toggle(display, "Vollbild", "set_fullscreen")
	fps_toggle = _toggle(display, "FPS anzeigen", "set_show_fps")
	_graphics_row(display)
	var controls := _section("Bedienung", other_sections)
	ui_sound_toggle = _toggle(controls, "UI-Klänge", "set_ui_sounds")
	motion_toggle = _toggle(controls, "Reduzierte Bewegung", "set_reduced_ui_motion")
	_update_columns()


func _section(title: String, parent: Node) -> VBoxContainer:
	var section := VBoxContainer.new()
	section.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	section.add_theme_constant_override("separation", 8)
	parent.add_child(section)
	var heading := Label.new()
	heading.text = title
	heading.add_theme_font_size_override("font_size", 22)
	heading.add_theme_color_override("font_color", DentiUIStyle.INK)
	section.add_child(heading)
	var spacer := Control.new()
	spacer.custom_minimum_size.y = 2.0
	spacer.mouse_filter = Control.MOUSE_FILTER_IGNORE
	section.add_child(spacer)
	return section


func _audio_row(parent: VBoxContainer, title: String, method: StringName) -> HSlider:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = ROW_HEIGHT
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label := _label(title)
	label.custom_minimum_size.x = 64.0
	row.add_child(label)
	var slider := HSlider.new()
	slider.name = "%sVolume" % title
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.custom_minimum_size.y = ROW_HEIGHT
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.tooltip_text = "%s-Lautstärke" % title
	DentiUIStyle.style_slider(slider)
	var focus := _focus_box()
	slider.add_theme_stylebox_override("focus", focus)
	row.add_child(slider)
	var value_label := _label("100 %")
	value_label.custom_minimum_size.x = 56.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", DentiUIStyle.GOLD)
	row.add_child(value_label)
	slider.value_changed.connect(func(amount: float) -> void:
		var percent := roundi(amount)
		value_label.text = "%d %%" % percent
		session.call(method, percent)
	)
	slider.set_meta("value_label", value_label)
	return slider


func _toggle(parent: VBoxContainer, title: String, method: StringName) -> CheckButton:
	var toggle := SettingToggle.new()
	toggle.text = title
	toggle.custom_minimum_size.y = ROW_HEIGHT
	toggle.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	toggle.add_theme_font_size_override("font_size", LABEL_SIZE)
	DentiUIStyle.style_check_button(toggle)
	# Keep the native CheckButton semantics, input and focus. The quiet switch is
	# painted independently so the OS/default-theme check graphic cannot leak in.
	var image := Image.create(1, 1, false, Image.FORMAT_RGBA8)
	image.fill(Color.TRANSPARENT)
	var blank := ImageTexture.create_from_image(image)
	for icon in ["checked", "unchecked", "checked_disabled", "unchecked_disabled", "checked_mirrored", "unchecked_mirrored", "checked_disabled_mirrored", "unchecked_disabled_mirrored"]:
		toggle.add_theme_icon_override(icon, blank)
	for state in ["normal", "hover", "pressed", "hover_pressed", "disabled"]:
		var surface := StyleBoxEmpty.new()
		surface.content_margin_left = 0.0
		surface.content_margin_right = 60.0
		toggle.add_theme_stylebox_override(state, surface)
	toggle.add_theme_stylebox_override("focus", _focus_box())
	parent.add_child(toggle)
	DentiUIMotion.bind_button(toggle)
	toggle.toggled.connect(func(enabled: bool) -> void:
		session.call(method, enabled)
		toggle.queue_redraw()
		if method == &"set_fullscreen":
			_sync_fullscreen.call_deferred()
	)
	return toggle


func _graphics_row(parent: VBoxContainer) -> void:
	var row := HBoxContainer.new()
	row.custom_minimum_size.y = ROW_HEIGHT
	row.add_theme_constant_override("separation", 12)
	parent.add_child(row)
	var label := _label("Grafik")
	label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	row.add_child(label)
	graphics_option = OptionButton.new()
	graphics_option.custom_minimum_size.y = ROW_HEIGHT
	graphics_option.add_item("Automatisch", 0)
	graphics_option.add_item("Sparsam", 1)
	graphics_option.add_item("Voll", 2)
	DentiUIStyle.style_button(graphics_option)
	var surface := DentiUIStyle._box(DentiUIStyle.PANEL, Color.TRANSPARENT, 10, 0)
	graphics_option.add_theme_stylebox_override("normal", surface)
	graphics_option.add_theme_stylebox_override("focus", _focus_box())
	graphics_option.add_theme_font_size_override("font_size", LABEL_SIZE)
	var popup := graphics_option.get_popup()
	popup.add_theme_font_size_override("font_size", LABEL_SIZE)
	popup.add_theme_constant_override("v_separation", 28)
	row.add_child(graphics_option)
	graphics_option.item_selected.connect(func(index: int) -> void:
		session.call(&"set_graphics_mode", graphics_option.get_item_id(index))
	)


func _label(value: String) -> Label:
	var label := Label.new()
	label.text = value
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.add_theme_font_size_override("font_size", LABEL_SIZE)
	label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	return label


func _focus_box() -> StyleBoxFlat:
	var focus := DentiUIStyle._box(Color.TRANSPARENT, DentiUIStyle.INK, 10, 2)
	focus.draw_center = false
	focus.content_margin_left = 0.0
	focus.content_margin_right = 0.0
	focus.content_margin_top = 0.0
	focus.content_margin_bottom = 0.0
	return focus


func _sync_values() -> void:
	var sliders: Array[HSlider] = [master_slider, music_slider, sfx_slider]
	var values: Array[int] = [int(session.get("master_volume_percent")), int(session.get("music_volume_percent")), int(session.get("sfx_volume_percent"))]
	for index in sliders.size():
		var slider := sliders[index]
		slider.set_value_no_signal(values[index])
		var value_label := slider.get_meta("value_label") as Label
		value_label.text = "%d %%" % values[index]
	_sync_fullscreen()
	fps_toggle.set_pressed_no_signal(bool(session.get("show_fps")))
	ui_sound_toggle.set_pressed_no_signal(bool(session.get("ui_sounds")))
	motion_toggle.set_pressed_no_signal(bool(session.get("reduced_ui_motion")))
	graphics_option.select(clampi(int(session.get("graphics_mode")), 0, 2))
	for toggle: CheckButton in [fullscreen_toggle, fps_toggle, ui_sound_toggle, motion_toggle]:
		toggle.queue_redraw()


func _sync_fullscreen() -> void:
	if session == null or not is_instance_valid(fullscreen_toggle):
		return
	fullscreen_toggle.set_pressed_no_signal(bool(session.call(&"is_fullscreen")))
	fullscreen_toggle.queue_redraw()


func _update_columns() -> void:
	if not is_instance_valid(columns):
		return
	columns.columns = 2 if size.x >= TWO_COLUMN_WIDTH else 1
