class_name RunSetupStyle
extends RefCounted

static var _font: FontVariation

static func make_theme() -> Theme:
	var theme := DentiUIStyle.make_theme()
	if _font == null:
		_font = theme.default_font.duplicate() as FontVariation
		var source := DentiUIStyle.FONT.duplicate() as FontFile
		source.multichannel_signed_distance_field = true
		_font.base_font = source
	theme.default_font = _font
	return theme

# Selection, keyboard focus and the primary action have distinct treatments.
static func choice(button: Button, selected: bool, keyboard: bool, radius: int = 16) -> void:
	var fill := DentiUIStyle.PANEL.lerp(DentiUIStyle.GOLD, 0.06) if selected else DentiUIStyle.PANEL
	var edge := DentiUIStyle.GOLD if selected else DentiUIStyle.LINE
	button.add_theme_stylebox_override("normal", box(fill, edge, radius, 2 if selected else 1))
	button.add_theme_stylebox_override("hover", box(fill.lightened(0.035), edge.lightened(0.15), radius, 2 if selected else 1))
	button.add_theme_stylebox_override("pressed", box(fill.lightened(0.05), DentiUIStyle.GOLD, radius, 2))
	focus(button, keyboard, radius)
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		button.add_theme_color_override(state, Color.WHITE)
	DentiUIMotion.bind_button(button)

static func focus(button: Button, keyboard: bool, radius: int = 12) -> void:
	if not keyboard:
		button.add_theme_stylebox_override("focus", StyleBoxEmpty.new())
		return
	var outline := box(Color.TRANSPARENT, DentiUIStyle.INK, radius, 2)
	outline.draw_center = false
	outline.expand_margin_left = -4
	outline.expand_margin_right = -4
	outline.expand_margin_top = -4
	outline.expand_margin_bottom = -4
	button.add_theme_stylebox_override("focus", outline)

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
