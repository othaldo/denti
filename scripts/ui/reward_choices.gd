class_name RewardChoices
extends Control

var cards: GridContainer
var buttons: Array[UpgradeCard] = []
var kind: StringName = &"upgrade"
var available := Vector2.ZERO
var layout_queued := false

func _ready() -> void:
	cards = GridContainer.new()
	cards.add_theme_constant_override("h_separation", 16)
	cards.add_theme_constant_override("v_separation", 8)
	add_child(cards)
	for index in ChoicePanel.UPGRADE_COUNT:
		var button := RewardCard.new()
		cards.add_child(button)
		buttons.append(button)
	cards.minimum_size_changed.connect(_schedule_layout)
	resized.connect(_schedule_layout)

func _schedule_layout() -> void:
	if layout_queued: return
	layout_queued = true
	call_deferred("_relayout")

func _relayout() -> void:
	layout_queued = false
	if available != Vector2.ZERO: layout_in(available)

func layout_in(extent: Vector2) -> void:
	if cards == null: return
	available = extent
	var count := 0
	for button in buttons:
		if button.visible and button.get_parent() == cards: count += 1
	if count == 0: return
	var columns := 1
	if kind == &"upgrade":
		columns = 4 if extent.x >= 1000 else (2 if extent.x >= 500 else 1)
	elif kind == &"relic":
		columns = 3 if extent.x >= 850 else (2 if extent.x >= 600 else 1)
	cards.columns = mini(columns, count)
	var tall := kind != &"chest" and ((extent.x >= 850 and extent.y >= 320) or (extent.x >= 600 and extent.y >= 650))
	var width := minf(extent.x, 760) if kind == &"chest" else extent.x
	var compact := not tall if kind != &"chest" else extent.x < 600 or extent.y < 260
	var gap := 12.0 if tall else 8.0
	cards.add_theme_constant_override("h_separation", int(gap))
	var cell_width := (width - gap * (cards.columns - 1)) / cards.columns
	var row_heights: Array[float] = []
	var index := 0
	for button in buttons:
		if not button.visible or button.get_parent() != cards: continue
		(button as RewardCard).configure_layout(cell_width, compact, tall)
		var row := index / cards.columns
		if row_heights.size() <= row: row_heights.append(0)
		row_heights[row] = maxf(row_heights[row], button.custom_minimum_size.y)
		index += 1
	var height := 8.0 * maxi(row_heights.size() - 1, 0)
	for row_height in row_heights: height += row_height
	custom_minimum_size.y = height
	cards.position = Vector2((extent.x - width) * 0.5, maxf(0, (extent.y - height) * 0.5))
	cards.size = Vector2(width, height)
