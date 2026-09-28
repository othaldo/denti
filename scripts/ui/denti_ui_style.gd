class_name DentiUIStyle
extends RefCounted

const FONT: FontFile = preload("res://assets/ui/Fredoka.ttf")
const INK := Color(0.25, 0.13, 0.19)
const CREAM := Color(1.0, 0.97, 0.88)
const MUTED := Color(0.47, 0.34, 0.38)
const GOLD := Color(0.98, 0.77, 0.30)
const MINT := Color(0.48, 0.80, 0.67)
const CORAL := Color(0.95, 0.47, 0.42)


static func make_theme() -> Theme:
	var theme := Theme.new()
	theme.default_font = FONT
	theme.default_font_size = 18
	return theme


static func style_hud_text(label: Label, color: Color, size: int, outline: int = 3) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", Color(0.07, 0.04, 0.08))
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_font_size_override("font_size", size)


static func style_dialog(panel: PanelContainer) -> void:
	var style := _box(CREAM, INK, 22, 4)
	style.shadow_color = Color(0.11, 0.06, 0.12, 0.42)
	style.shadow_size = 14
	style.shadow_offset = Vector2(0, 8)
	panel.add_theme_stylebox_override("panel", style)


static func style_button(button: Button, accent: bool = false, left_align: bool = false) -> void:
	var normal_color := GOLD if accent else Color(1.0, 0.99, 0.95)
	button.add_theme_stylebox_override("normal", _box(normal_color, INK, 12, 2))
	button.add_theme_stylebox_override("hover", _box(Color(0.83, 0.94, 0.82) if not accent else Color(1.0, 0.85, 0.48), INK, 12, 3))
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


static func style_progress(bar: ProgressBar, fill_color: Color) -> void:
	var background := _box(Color(0.09, 0.07, 0.10, 0.96), Color(0.04, 0.03, 0.05), 5, 2)
	var fill := _box(fill_color, fill_color.darkened(0.35), 4, 1)
	for style in [background, fill]:
		style.content_margin_left = 0.0
		style.content_margin_right = 0.0
		style.content_margin_top = 0.0
		style.content_margin_bottom = 0.0
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)


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
