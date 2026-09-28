class_name DentiUIStyle
extends RefCounted

const FONT: FontFile = preload("res://assets/ui/Fredoka.ttf")
const INK := Color(0.25, 0.13, 0.19)
const CREAM := Color(1.0, 0.97, 0.88)
const MUTED := Color(0.47, 0.34, 0.38)
const GOLD := Color(0.98, 0.77, 0.30)
const MINT := Color(0.48, 0.80, 0.67)
const CORAL := Color(0.95, 0.47, 0.42)
const VIOLET := Color(0.52, 0.36, 0.69)
const PANEL := Color(1.0, 0.98, 0.92, 0.96)


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 18
	theme.set_stylebox("panel", "TooltipPanel", _box(PANEL, GOLD, 10, 2))
	theme.set_color("font_color", "TooltipLabel", INK)
	return theme


static func style_hud_text(label: Label, color: Color, size: int, outline: int = 3, outline_color: Color = Color(0.07, 0.04, 0.08)) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_font_size_override("font_size", size)


static func style_dialog(panel: PanelContainer) -> void:
	var style := _box(PANEL, Color(0.62, 0.45, 0.37), 22, 3)
	style.shadow_color = Color(0.11, 0.06, 0.12, 0.42)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 9)
	panel.add_theme_stylebox_override("panel", style)


static func style_hud_panel(panel: Panel) -> void:
	var style := _box(PANEL, Color(0.57, 0.41, 0.43, 0.82), 16, 2)
	style.shadow_color = Color(0.14, 0.09, 0.14, 0.28)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)


static func style_chip(panel: PanelContainer, fill: Color = Color(0.94, 0.88, 0.75)) -> void:
	var style := _box(fill, Color(0.64, 0.48, 0.33), 10, 1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", style)


static func style_button(button: Button, accent: bool = false, left_align: bool = false) -> void:
	var normal_color := GOLD if accent else Color(1.0, 0.99, 0.95)
	var normal := _box(normal_color, Color(0.47, 0.31, 0.36), 12, 2)
	normal.shadow_color = Color(0.18, 0.10, 0.14, 0.18)
	normal.shadow_size = 3
	normal.shadow_offset = Vector2(0, 2)
	button.add_theme_stylebox_override("normal", normal)
	var hover := _box(Color(0.89, 0.97, 0.88) if not accent else Color(1.0, 0.85, 0.48), GOLD, 12, 3)
	hover.shadow_color = Color(0.56, 0.36, 0.11, 0.29)
	hover.shadow_size = 7
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", _box(Color(0.69, 0.85, 0.68) if not accent else Color(0.91, 0.66, 0.20), INK, 12, 3))
	button.add_theme_stylebox_override("disabled", _box(Color(0.87, 0.84, 0.80), Color(0.62, 0.55, 0.54), 12, 2))
	var focus := _box(Color(1.0, 0.80, 0.36, 0.20), GOLD, 12, 3)
	button.add_theme_stylebox_override("focus", focus)
	button.add_theme_color_override("font_color", INK)
	button.add_theme_color_override("font_focus_color", INK)
	button.add_theme_color_override("font_hover_color", INK)
	button.add_theme_color_override("font_hover_pressed_color", INK)
	button.add_theme_color_override("font_pressed_color", INK)
	button.add_theme_color_override("font_disabled_color", INK)
	button.add_theme_font_size_override("font_size", 18)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT if left_align else HORIZONTAL_ALIGNMENT_CENTER


static func style_check_button(button: CheckButton) -> void:
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(state, INK)


static func style_card(button: Button, rare: bool = false) -> void:
	style_button(button)
	var accent := VIOLET if rare else MINT.darkened(0.18)
	var normal := _box(Color(1.0, 0.995, 0.96), accent if rare else Color(0.58, 0.45, 0.45), 16, 2)
	normal.shadow_color = Color(0.18, 0.10, 0.14, 0.22)
	normal.shadow_size = 5
	normal.shadow_offset = Vector2(0, 3)
	button.add_theme_stylebox_override("normal", normal)
	var hover := _box(Color(1.0, 0.98, 0.89), GOLD, 16, 3)
	hover.shadow_color = Color(0.73, 0.49, 0.15, 0.35)
	hover.shadow_size = 10
	hover.shadow_offset = Vector2(0, 5)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", _box(Color(1.0, 0.93, 0.75), accent, 16, 3))
	button.add_theme_stylebox_override("focus", _box(Color(1.0, 0.96, 0.82, 0.20), GOLD, 16, 3))
	button.add_theme_stylebox_override("disabled", _box(Color(0.85, 0.83, 0.80), Color(0.59, 0.55, 0.55), 16, 2))


static func style_progress(bar: ProgressBar, fill_color: Color) -> void:
	var background := _box(Color(0.77, 0.72, 0.70, 0.92), Color(0.43, 0.31, 0.34), 6, 2)
	var fill := _box(fill_color, fill_color.darkened(0.30), 5, 1)
	for style in [background, fill]:
		style.content_margin_left = 0.0
		style.content_margin_right = 0.0
		style.content_margin_top = 0.0
		style.content_margin_bottom = 0.0
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)


static func style_slider(slider: HSlider) -> void:
	var track := _box(Color(0.53, 0.42, 0.44), INK, 6, 1)
	var filled := _box(MINT.darkened(0.12), MINT.darkened(0.44), 6, 1)
	var highlighted := _box(GOLD, GOLD.darkened(0.35), 6, 1)
	for style in [track, filled, highlighted]:
		style.content_margin_left = 0.0
		style.content_margin_right = 0.0
		style.content_margin_top = 5.0
		style.content_margin_bottom = 5.0
	slider.add_theme_stylebox_override("slider", track)
	slider.add_theme_stylebox_override("grabber_area", filled)
	slider.add_theme_stylebox_override("grabber_area_highlight", highlighted)


static func _box(fill: Color, border: Color, radius: int, border_width: int) -> StyleBoxFlat:
	var style := StyleBoxFlat.new()
	style.bg_color = fill
	style.border_color = border
	style.set_border_width_all(border_width)
	style.set_corner_radius_all(radius)
	style.content_margin_left = 14.0
	style.content_margin_right = 14.0
	style.content_margin_top = 8.0
	style.content_margin_bottom = 8.0
	return style
