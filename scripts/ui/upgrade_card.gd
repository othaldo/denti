class_name UpgradeCard
extends Button

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")

var content: VBoxContainer
var icon_rect: TextureRect
var name_label: Label
var effect_label: Label
var hover_tween: Tween


func _ready() -> void:
	custom_minimum_size = Vector2(235, 186)
	size_flags_horizontal = Control.SIZE_EXPAND_FILL
	_build_content()
	DentiUIStyle.style_card(self)
	resized.connect(func() -> void: pivot_offset = size / 2.0)
	mouse_entered.connect(_on_hover.bind(true))
	mouse_exited.connect(_on_hover.bind(false))


func show_upgrade(upgrade: UpgradeData) -> void:
	custom_minimum_size.y = 186.0
	text = ""
	content.visible = true
	icon_rect.texture = ICONS.item(upgrade.icon_index)
	name_label.text = upgrade.display_name.to_upper()
	effect_label.text = upgrade.description
	disabled = false
	DentiUIStyle.style_card(self)


func show_action(action_name: String, accent: bool = false) -> void:
	custom_minimum_size.y = 60.0
	content.visible = false
	text = action_name
	disabled = false
	scale = Vector2.ONE
	DentiUIStyle.style_button(self, accent)


func _build_content() -> void:
	var margin := MarginContainer.new()
	margin.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	margin.add_theme_constant_override("margin_left", 14)
	margin.add_theme_constant_override("margin_right", 14)
	margin.add_theme_constant_override("margin_top", 10)
	margin.add_theme_constant_override("margin_bottom", 10)
	margin.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(margin)
	content = VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 7)
	content.mouse_filter = Control.MOUSE_FILTER_IGNORE
	margin.add_child(content)
	icon_rect = TextureRect.new()
	icon_rect.custom_minimum_size = Vector2(0, 70)
	icon_rect.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon_rect.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(icon_rect)
	name_label = Label.new()
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	name_label.add_theme_font_size_override("font_size", 21)
	name_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(name_label)
	effect_label = Label.new()
	effect_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	effect_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	effect_label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	effect_label.add_theme_font_size_override("font_size", 16)
	effect_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	content.add_child(effect_label)


func _on_hover(hovered: bool) -> void:
	if hover_tween != null:
		hover_tween.kill()
	hover_tween = create_tween()
	hover_tween.tween_property(self, "scale", Vector2.ONE * (1.025 if hovered else 1.0), 0.11)
