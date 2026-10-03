class_name DentiUIStyle
extends RefCounted

const FONT: FontFile = preload("res://assets/ui/Fredoka.ttf")
static var _ui_font: FontVariation
const BACKGROUND := Color("19151f")
const PANEL := Color("25212d")
const RAISED := Color("322c3b")
const LINE := Color("4a4053")
const INK := Color("fff4df")
const CREAM := INK
const TEXT := Color("eee7f1")
const MUTED := Color("dbd0e1")
const GOLD := Color("f4c56b")
const GOLD_INK := Color("2b202b")
const MINT := Color("9adfc7")
const CORAL := Color("ff968e")
const VIOLET := Color(0.52, 0.36, 0.69)


static func make_theme() -> Theme:
	var theme := Theme.new()
	if _ui_font == null:
		_ui_font = FontVariation.new()
		_ui_font.base_font = FONT
		var weight_tag := TextServerManager.get_primary_interface().name_to_tag("weight")
		_ui_font.variation_opentype = {weight_tag: 450.0}
	theme.default_font = _ui_font
	theme.default_font_size = 18
	for type in ["Label", "RichTextLabel", "OptionButton", "CheckButton"]:
		theme.set_color("font_color" if type != "RichTextLabel" else "default_color", type, INK)
	theme.set_stylebox("panel", "TooltipPanel", _box(BACKGROUND, LINE, 12, 1))
	theme.set_color("font_color", "TooltipLabel", INK)
	theme.set_font_size("font_size", "TooltipLabel", 16)
	theme.set_constant("separation", "TooltipLabel", 6)
	var option := Button.new()
	style_button(option)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		theme.set_stylebox(state, "OptionButton", option.get_theme_stylebox(state))
	option.free()
	theme.set_stylebox("panel", "PopupMenu", _box(PANEL, LINE, 12, 1))
	theme.set_stylebox("hover", "PopupMenu", _box(RAISED, GOLD, 8, 1))
	theme.set_color("font_color", "PopupMenu", INK)
	theme.set_color("font_hover_color", "PopupMenu", INK)
	theme.set_color("font_disabled_color", "PopupMenu", MUTED)
	theme.set_color("font_disabled_color", "OptionButton", MUTED)
	return theme


static func style_hud_text(label: Label, color: Color, size: int, outline: int = 3, outline_color: Color = Color(0.07, 0.04, 0.08)) -> void:
	label.add_theme_color_override("font_color", color)
	label.add_theme_color_override("font_outline_color", outline_color)
	label.add_theme_constant_override("outline_size", outline)
	label.add_theme_font_size_override("font_size", size)


static func style_dialog(panel: PanelContainer) -> void:
	var style := _box(BACKGROUND, LINE, 22, 1)
	style.shadow_color = Color(0.11, 0.06, 0.12, 0.42)
	style.shadow_size = 16
	style.shadow_offset = Vector2(0, 9)
	panel.add_theme_stylebox_override("panel", style)


static func style_hud_panel(panel: Panel) -> void:
	var style := _box(PANEL, LINE, 16, 1)
	style.shadow_color = Color(0.14, 0.09, 0.14, 0.28)
	style.shadow_size = 7
	style.shadow_offset = Vector2(0, 3)
	panel.add_theme_stylebox_override("panel", style)


static func style_chip(panel: PanelContainer, _fill: Color = RAISED) -> void:
	var style := _box(PANEL, LINE, 12, 1)
	style.content_margin_left = 8
	style.content_margin_right = 8
	style.content_margin_top = 3
	style.content_margin_bottom = 3
	panel.add_theme_stylebox_override("panel", style)


static func style_button(button: Button, accent: bool = false, left_align: bool = false) -> void:
	var normal_color := GOLD if accent else RAISED
	var normal := _box(normal_color, GOLD if accent else LINE, 12, 1)
	button.add_theme_stylebox_override("normal", normal)
	var hover := _box(RAISED.lightened(0.08) if not accent else GOLD.lightened(0.10), GOLD, 12, 1)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", _box(RAISED.darkened(0.15) if not accent else GOLD.darkened(0.12), GOLD, 12, 1))
	button.add_theme_stylebox_override("disabled", _box(PANEL, LINE, 12, 1))
	var focus := _box(Color.TRANSPARENT, GOLD, 12, 3)
	focus.draw_center = false
	button.add_theme_stylebox_override("focus", focus)
	var text_color := GOLD_INK if accent else INK
	for state in ["font_color", "font_focus_color", "font_hover_color", "font_hover_pressed_color", "font_pressed_color"]:
		button.add_theme_color_override(state, text_color)
	button.add_theme_color_override("font_disabled_color", MUTED)
	for state in ["icon_normal_color", "icon_hover_color", "icon_pressed_color", "icon_focus_color"]:
		button.add_theme_color_override(state, GOLD_INK if accent else INK)
	button.add_theme_font_size_override("font_size", 18)
	button.alignment = HORIZONTAL_ALIGNMENT_LEFT if left_align else HORIZONTAL_ALIGNMENT_CENTER
	DentiUIMotion.bind_button(button)


static func style_check_button(button: CheckButton) -> void:
	for state in ["font_color", "font_hover_color", "font_pressed_color", "font_hover_pressed_color", "font_focus_color", "font_disabled_color"]:
		button.add_theme_color_override(state, INK)


static func style_rarity_label(label: Label, tier: int) -> void:
	var rarity_color := DentiRarity.color_for(tier).lightened(0.65)
	var badge := _box(Color.TRANSPARENT, Color.TRANSPARENT, 4, 0)
	badge.content_margin_left = 0.0
	badge.content_margin_right = 0.0
	badge.content_margin_top = 0.0
	badge.content_margin_bottom = 0.0
	label.add_theme_stylebox_override("normal", badge)
	label.add_theme_color_override("font_color", rarity_color)
	label.add_theme_font_size_override("font_size", 13)


static func style_card(button: Button, tier: int = 1) -> void:
	style_button(button)
	var accent := DentiRarity.color_for(tier)
	var fill := PANEL.lerp(accent, 0.16)
	var normal := rarity_surface(tier)
	button.add_theme_stylebox_override("normal", normal)
	var hover := _box(fill.lightened(0.035), accent.lightened(0.35), 14, 2)
	button.add_theme_stylebox_override("hover", hover)
	button.add_theme_stylebox_override("pressed", _box(fill.darkened(0.06), accent, 14, 2))
	# Focus is an inset cream outline; the rarity border and fill stay visible.
	button.add_theme_stylebox_override("focus", _rarity_marker(INK))
	button.add_theme_stylebox_override("disabled", _box(fill.darkened(0.08), accent.darkened(0.15), 14, 2))


static func rarity_surface(tier: int) -> StyleBoxFlat:
	var accent := DentiRarity.color_for(tier)
	var style := _box(PANEL.lerp(accent, 0.16), accent.lightened(0.20), 14, 2)
	return style


static func style_rarity_panel(panel: PanelContainer, tier: int) -> void:
	panel.add_theme_stylebox_override("panel", rarity_surface(tier))
	mark_card(panel)


static func mark_card(control: Control, color: Color = Color.TRANSPARENT) -> void:
	# Selection/fusion markers overlay the surface instead of replacing rarity.
	control.set_meta("denti_rarity_marker", color)
	if not control.has_meta("denti_rarity_marker_bound"):
		control.set_meta("denti_rarity_marker_bound", true)
		control.draw.connect(func() -> void:
			var marker: Color = control.get_meta("denti_rarity_marker", Color.TRANSPARENT)
			if not control is BaseButton and control.has_focus():
				marker = INK
			if marker.a > 0:
				control.draw_style_box(_rarity_marker(marker), Rect2(Vector2.ZERO, control.size))
		)
		control.focus_entered.connect(control.queue_redraw)
		control.focus_exited.connect(control.queue_redraw)
	control.queue_redraw()


static func _rarity_marker(color: Color) -> StyleBoxFlat:
	var style := _box(Color.TRANSPARENT, color, 9, 2)
	style.draw_center = false
	style.set_expand_margin_all(-5.0)
	return style


static func style_progress(bar: ProgressBar, fill_color: Color) -> void:
	var background := _box(RAISED, RAISED, 6, 0)
	var fill := _box(fill_color, fill_color, 5, 0)
	for style in [background, fill]:
		style.content_margin_left = 0.0
		style.content_margin_right = 0.0
		style.content_margin_top = 0.0
		style.content_margin_bottom = 0.0
	bar.add_theme_stylebox_override("background", background)
	bar.add_theme_stylebox_override("fill", fill)


static func style_slider(slider: HSlider) -> void:
	var track := _box(RAISED.lightened(0.12), LINE, 6, 0)
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


static func rounded_image_surface(radius: int) -> Panel:
	var surface := Panel.new()
	surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	# Rectangular Control.clip_contents does not follow the rounded frame.
	# A separate, shadow-free alpha mask clips the actual image and overlays.
	surface.clip_children = CanvasItem.CLIP_CHILDREN_ONLY
	surface.add_theme_stylebox_override("panel", _box(Color.WHITE, Color.TRANSPARENT, radius, 0))
	return surface


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
