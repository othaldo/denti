class_name DifficultySelection
extends Control

signal selected(id: StringName)
signal locked_requested(id: StringName)

const MOTIFS := {
	&"easy": preload("res://assets/ui/run_setup/easy.png"),
	&"normal": preload("res://assets/ui/run_setup/normal.png"),
	&"hard": preload("res://assets/ui/run_setup/hard.png"),
	&"hell": preload("res://assets/ui/run_setup/hell.png"),
}
var buttons: Dictionary = {}
var selected_id: StringName = &"normal"
var keyboard_focus := false

func _ready() -> void:
	for data in DifficultyCatalog.ALL:
		var card := RunSetupChoice.new()
		card.name = str(data.id)
		card.custom_minimum_size = Vector2(48, 48)
		card.tooltip_text = data.display_name
		add_child(card)
		buttons[data.id] = card
		var art := TextureRect.new()
		art.name = "Art"
		art.texture = MOTIFS[data.id]
		art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		art.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(art)
		var title := Label.new()
		title.name = "Title"
		title.text = data.display_name
		title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		title.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(title)
		var requirement := Label.new()
		requirement.name = "Requirement"
		requirement.text = "Sieg auf Hard"
		requirement.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		requirement.add_theme_color_override("font_color", DentiUIStyle.MUTED)
		requirement.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(requirement)
		var lock := TextureRect.new()
		lock.name = "Lock"
		lock.texture = preload("res://assets/ui/setup_lock.svg")
		lock.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		lock.mouse_filter = Control.MOUSE_FILTER_IGNORE
		card.add_child(lock)
		card.pressed.connect(_choose.bind(data.id))
	resized.connect(_layout)

func show_selection(id: StringName, eligible: Callable) -> void:
	selected_id = id
	for key in buttons:
		var card: RunSetupChoice = buttons[key]
		var locked := not bool(eligible.call(key))
		card.set_meta("locked", locked)
		card.get_node("Art").modulate = Color(0.6, 0.53, 0.64, 0.36) if locked else Color.WHITE
		card.get_node("Requirement").visible = locked
		card.get_node("Lock").visible = locked
	refresh()
	_layout()

func refresh() -> void:
	for key in buttons:
		var card: RunSetupChoice = buttons[key]
		card.selected = key == selected_id
		card.keyboard_focus = keyboard_focus
		card.refresh()

func _choose(id: StringName) -> void:
	if bool(buttons[id].get_meta("locked", false)):
		locked_requested.emit(id)
		return
	selected_id = id
	refresh()
	selected.emit(id)

func _layout() -> void:
	if buttons.is_empty(): return
	var cells := RunSetupLayout.difficulty_cells(size)
	for index in DifficultyCatalog.ALL.size():
		var card: Button = buttons[DifficultyCatalog.ALL[index].id]
		card.position = cells[index].position
		card.size = cells[index].size
		var compact := card.size.y < 210 or card.size.x < 170
		var title_height := 26.0 if compact else 38.0
		var base := card.size.y - (54.0 if compact else 74.0)
		var art: TextureRect = card.get_node("Art")
		art.position = Vector2(8, 8 if compact else 16)
		art.size = Vector2(card.size.x - 16, maxf(32, base - (12 if compact else 24)))
		var title: Label = card.get_node("Title")
		title.add_theme_font_size_override("font_size", 20 if compact else 28)
		title.position = Vector2(0, base)
		title.size = Vector2(card.size.x, title_height)
		var requirement: Label = card.get_node("Requirement")
		requirement.add_theme_font_size_override("font_size", 12 if compact else 14)
		requirement.position = Vector2(6, card.size.y - (24 if compact else 30))
		requirement.size = Vector2(card.size.x - 12, 18 if compact else 20)
		var lock: TextureRect = card.get_node("Lock")
		lock.position = Vector2(12, 12)
		lock.size = Vector2(18, 18)
