class_name AchievementsMenu
extends Control

signal inspect_requested(data: WeaponData, flags: int, source: Control)

var masteries: Dictionary = {}
var heading: Label
var total_label: Label
var meter: ProgressBar
var search: LineEdit
var filter: OptionButton
var grid: GridContainer
var empty_label: Label
var cards: Array[WeaponMasteryCard] = []
var available := Vector2.ZERO


func _ready() -> void:
	heading = Label.new()
	heading.text = "Waffenmeisterschaften"
	add_child(heading)
	total_label = Label.new()
	total_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	total_label.add_theme_color_override("font_color", DentiUIStyle.MINT)
	add_child(total_label)
	meter = ProgressBar.new()
	meter.show_percentage = false
	meter.max_value = WeaponCatalog.ALL.size() * WeaponMasteries.ALL.size()
	meter.mouse_filter = Control.MOUSE_FILTER_IGNORE
	meter.add_theme_stylebox_override("background", MenuStyle.box(DentiUIStyle.LINE, Color.TRANSPARENT, 2, 0))
	meter.add_theme_stylebox_override("fill", MenuStyle.box(DentiUIStyle.GOLD, Color.TRANSPARENT, 2, 0))
	add_child(meter)
	search = LineEdit.new()
	search.placeholder_text = "Waffe suchen"
	search.clear_button_enabled = true
	search.add_theme_font_size_override("font_size", 16)
	search.text_changed.connect(func(_value: String) -> void: _rebuild())
	add_child(search)
	filter = OptionButton.new()
	for title in ["Alle", "Offen", "Gemeistert"]: filter.add_item(title)
	filter.fit_to_longest_item = false
	filter.add_theme_font_size_override("font_size", 14)
	filter.item_selected.connect(func(_index: int) -> void: _rebuild())
	add_child(filter)
	grid = GridContainer.new()
	grid.add_theme_constant_override("h_separation", 12)
	grid.add_theme_constant_override("v_separation", 12)
	add_child(grid)
	empty_label = Label.new()
	empty_label.text = "Keine passenden Waffen"
	empty_label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	add_child(empty_label)
	resized.connect(func() -> void: layout_in(size))


func configure(progress: Dictionary) -> void:
	masteries = progress.duplicate()
	var count := 0
	for data in WeaponCatalog.ALL: count += WeaponMasteries.ids_for(_flags(data.id)).size()
	total_label.text = "%d/%d" % [count, int(meter.max_value)]
	meter.value = count
	_rebuild()


func _flags(id: StringName) -> int:
	return int(masteries.get(str(id), 0)) & WeaponMasteries.all_flags()


func _rebuild() -> void:
	for card in cards:
		grid.remove_child(card)
		card.queue_free()
	cards.clear()
	var query := search.text.strip_edges().to_lower()
	for data in WeaponCatalog.ALL:
		var flags := _flags(data.id)
		if not query.is_empty() and not (data.display_name + " " + str(data.id) + (" Garotte" if data.id == &"floss_garrote" else "")).to_lower().contains(query): continue
		if filter.selected == 1 and flags == WeaponMasteries.all_flags(): continue
		if filter.selected == 2 and flags != WeaponMasteries.all_flags(): continue
		var card := WeaponMasteryCard.new()
		card.data = data
		card.flags = flags
		grid.add_child(card)
		card.pressed.connect(func() -> void: inspect_requested.emit(card.data, card.flags, card))
		cards.append(card)
	empty_label.visible = cards.is_empty()
	layout_in(size if size.x > 0 else available)


func layout_in(extent: Vector2) -> void:
	available = extent
	if heading == null or extent.x < 1: return
	var width := extent.x
	heading.add_theme_font_size_override("font_size", 17 if width < 420 else 22)
	total_label.add_theme_font_size_override("font_size", 18 if width < 420 else 22)
	heading.position = Vector2.ZERO
	heading.size = Vector2(width - 72, 34)
	total_label.position = Vector2(width - 68, 0)
	total_label.size = Vector2(68, 34)
	meter.position = Vector2(0, 40)
	meter.size = Vector2(width, 4)
	var filter_width := clampf(width * 0.35, 126, 180)
	search.position = Vector2(0, 58)
	search.size = Vector2(width - filter_width - 8, 48)
	filter.position = Vector2(width - filter_width, 58)
	filter.size = Vector2(filter_width, 48)
	grid.columns = clampi(floori((width + 12) / 262), 1, 4)
	var cell := (width - (grid.columns - 1) * 12) / grid.columns
	for card in cards: card.custom_minimum_size = Vector2(cell, 164)
	grid.position = Vector2(0, 122)
	grid.size.x = width
	empty_label.position = Vector2(0, 132)
	empty_label.size = Vector2(width, 32)
	custom_minimum_size.y = 122 + maxf(48, ceili(float(cards.size()) / grid.columns) * 176 - 12)
