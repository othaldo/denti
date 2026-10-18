class_name HUDStatusBadge
extends Control

enum Kind { POISON, BLEED, SHIELD }
const ICON_IDS: Array[StringName] = [&"poison", &"bleed", &"shield"]
var kind: Kind
var icon: TextureRect
var label: Label
var amount: float = 0.0
var plate: Panel


func _init(type: Kind = Kind.POISON) -> void:
	kind = type
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	if kind == Kind.SHIELD:
		plate = Panel.new()
		plate.mouse_filter = Control.MOUSE_FILTER_IGNORE
		var style := StyleBoxFlat.new()
		style.bg_color = DentiUIStyle.PANEL
		style.border_color = DentiUIStyle.GOLD
		style.set_border_width_all(1)
		style.set_corner_radius_all(14)
		plate.add_theme_stylebox_override("panel", style)
		add_child(plate)
	icon = TextureRect.new()
	icon.name = "PaintedIcon"
	icon.texture = HUDStatusIcons.texture(ICON_IDS[kind])
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(icon)
	label = Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	DentiUIStyle.style_hud_text(label, DentiUIStyle.INK, 12, 3, DentiUIStyle.BACKGROUND)
	if kind == Kind.SHIELD:
		label.add_theme_font_size_override("font_size", 13)
	add_child(label)
	resized.connect(_layout)


func show_amount(number: float) -> void:
	amount = number
	visible = number > 0
	label.text = str(ceili(number)) if kind == Kind.SHIELD else ("%.1f s" % number).replace(".", ",")


func _layout() -> void:
	if kind == Kind.SHIELD:
		plate.size = size
		icon.position = Vector2(2, (size.y - 24) * 0.5)
		icon.size = Vector2(24, 24)
		label.position = Vector2(28, 0)
		label.size = Vector2(size.x - 30, size.y)
		return
	icon.position = Vector2((size.x - 24) * 0.5, 0)
	icon.size = Vector2(24, 24)
	label.position = Vector2(0, 25)
	label.size = Vector2(size.x, 18)
