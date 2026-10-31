class_name WeaponMasteryNotice
extends CanvasLayer
## A brief, noninteractive intermission celebration; never opens a reward choice.

var panel: Panel
var heading: Label
var weapon_label: Label
var icon: TextureRect
var remaining := 0.0
var source_title := ""
var source_weapon := ""


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 40
	panel = Panel.new()
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.theme = DentiUIStyle.make_theme()
	panel.add_theme_stylebox_override("panel", MenuStyle.box(DentiUIStyle.PANEL, DentiUIStyle.GOLD, 16, 2))
	add_child(panel)
	icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(44, 44)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(icon)
	heading = Label.new()
	heading.add_theme_font_size_override("font_size", 17)
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(heading)
	weapon_label = Label.new()
	weapon_label.add_theme_font_size_override("font_size", 14)
	weapon_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	weapon_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	panel.add_child(weapon_label)
	get_viewport().size_changed.connect(_layout)
	visible = false


func present(id: StringName, awards: Array[String]) -> void:
	if awards.is_empty() or not WeaponMasteries.valid_weapon(id): return
	var definition := WeaponMasteries.by_id(StringName(awards[-1]))
	if definition == null: return
	icon.texture = WeaponMasteryIcons.icon(definition.icon_index)
	source_title = "Zahnprüfung bestanden" if definition.id == &"exam" else definition.display_name + " erreicht"
	source_weapon = WeaponCatalog.by_id(id).display_name
	remaining = 4.0
	visible = true
	_layout()
	DentiUIMotion.reveal(panel)


func _process(delta: float) -> void:
	if not visible: return
	remaining -= delta
	if remaining <= 0: visible = false


func _layout() -> void:
	if panel == null: return
	var factor := MenuLayout.ui_scale(get_viewport())
	var safe := HUDLayout.safe_rect(get_viewport().get_visible_rect().size)
	panel.scale = Vector2.ONE * factor
	var width := minf(360, safe.size.x / factor - 24)
	var text_width := width - 86
	var title_height := _wrap(heading, source_title, text_width, 17)
	var weapon_height := _wrap(weapon_label, source_weapon, text_width, 14)
	panel.size = Vector2(width, maxf(72, title_height + weapon_height + 28))
	icon.position = Vector2(14, (panel.size.y - 44) / 2)
	icon.size = Vector2(44, 44)
	heading.position = Vector2(72, 10)
	heading.size = Vector2(text_width, title_height)
	weapon_label.position = Vector2(72, 14 + title_height)
	weapon_label.size = Vector2(text_width, weapon_height)
	panel.position = Vector2(safe.position.x + (safe.size.x - panel.size.x * factor) / 2, safe.position.y + 12 * factor)


func _wrap(label: Label, text: String, width: float, font_size: int) -> float:
	var paragraph := TextParagraph.new()
	paragraph.width = width
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	paragraph.add_string(text, label.get_theme_font("font"), font_size)
	var lines := PackedStringArray()
	for index in paragraph.get_line_count():
		var span := paragraph.get_line_range(index)
		lines.append(text.substr(span.x, span.y - span.x).strip_edges())
	label.text = "\n".join(lines)
	return ceilf(paragraph.get_size().y)
