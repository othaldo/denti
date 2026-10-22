class_name MenuStyle
extends RefCounted

static var _font: FontVariation

static func make_theme() -> Theme:
	var result := DentiUIStyle.make_theme()
	if _font == null:
		_font = result.default_font.duplicate() as FontVariation
		var source := DentiUIStyle.FONT.duplicate() as FontFile
		source.multichannel_signed_distance_field = true
		_font.base_font = source
	result.default_font = _font
	return result

static func backdrop(parent: Control, overlay: bool = false) -> void:
	var background := ColorRect.new()
	background.color = Color(DentiUIStyle.BACKGROUND, 0.94) if overlay else DentiUIStyle.BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	parent.add_child(background)
	if overlay: return
	var glow := TextureRect.new()
	var texture := GradientTexture2D.new()
	texture.width = 128
	texture.height = 128
	texture.fill = GradientTexture2D.FILL_RADIAL
	texture.fill_from = Vector2(0.5, 0.35)
	texture.fill_to = Vector2(1, 0.7)
	texture.gradient = Gradient.new()
	texture.gradient.colors = PackedColorArray([Color("322435"), DentiUIStyle.BACKGROUND])
	glow.texture = texture
	glow.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	glow.mouse_filter = Control.MOUSE_FILTER_IGNORE
	parent.add_child(glow)

static func focus(control: Control, keyboard: bool, radius: int = 12) -> void:
	if not keyboard:
		control.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		return
	var outline := box(Color.TRANSPARENT, DentiUIStyle.INK, radius, 2)
	outline.draw_center = false
	outline.set_expand_margin_all(-4)
	control.add_theme_stylebox_override("focus", outline)

static func action(button: Button, primary: bool = false, quiet_action: bool = false) -> void:
	DentiUIStyle.style_button(button, primary)
	button.custom_minimum_size.y = 48
	button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	if quiet_action: quiet(button)
	elif not primary:
		button.add_theme_stylebox_override("normal", box(DentiUIStyle.PANEL, Color.TRANSPARENT, 12, 0))
	focus(button, false)

static func quiet(button: Button) -> void:
	DentiUIStyle.style_button(button)
	button.add_theme_stylebox_override("normal", box(Color.TRANSPARENT, Color.TRANSPARENT, 10, 0))
	button.add_theme_stylebox_override("disabled", StyleBoxEmpty.new())
	button.add_theme_color_override("font_disabled_color", Color(DentiUIStyle.MUTED, 0.35))

static func box(fill: Color, edge: Color, radius: int, width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = edge
	style.set_border_width_all(width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 0
	style.content_margin_right = 0
	style.content_margin_top = 0
	style.content_margin_bottom = 0
	return style
