class_name RunSetupStyle
extends RefCounted

static func make_theme() -> Theme:
	return MenuStyle.make_theme()

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
	MenuStyle.focus(button, keyboard, radius)

static func quiet(button: Button) -> void:
	MenuStyle.quiet(button)

static func box(fill: Color, edge: Color, radius: int, width: int) -> StyleBoxFlat:
	return MenuStyle.box(fill, edge, radius, width)
