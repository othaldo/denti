class_name HUDRetinue
extends Control
## A compact, named health display for the Emperor's unique lieutenants.

const SHADOW := Color("38244f")
const HIGHLIGHT := Color("9166b8")
const ROW_HEIGHT := 20.0
const GAP := 4.0
var rows: Array[Control] = []
var frames: Array[HUDPaintedFrame] = []
var labels: Array[Label] = []
var members: Array[Enemy] = []

func _ready() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	resized.connect(_layout)

func show_members(enemies: Array[Enemy]) -> void:
	members = enemies
	while rows.size() < members.size(): _add_row()
	visible = not members.is_empty()
	for index in rows.size():
		rows[index].visible = index < members.size()
		if index >= members.size(): continue
		var enemy := members[index]
		rows[index].modulate = Color(1, 1, 1, 0.5) if not enemy.is_targetable() else Color.WHITE
		labels[index].text = enemy.data.display_name
		labels[index].tooltip_text = "%s · %d / %d" % [enemy.data.display_name, ceili(enemy.health), ceili(enemy.max_health)]
		frames[index].show_health(enemy.health / maxf(enemy.max_health, 1))
	_layout()

func _add_row() -> void:
	var row := Control.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(row)
	rows.append(row)
	var frame := HUDPaintedFrame.new(GameHUD.BOSS_ART)
	row.add_child(frame)
	frame.set_health_colors(SHADOW, HIGHLIGHT)
	frames.append(frame)
	var label := Label.new()
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.clip_text = true
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	DentiUIStyle.style_hud_text(label, DentiUIStyle.INK, 13, 2, Color("25192f"))
	row.add_child(label)
	labels.append(label)

func _layout() -> void:
	var columns := 3 if size.x >= 420 else 1
	var width := (size.x - (columns - 1) * GAP) / columns
	for index in members.size():
		var column := index % columns
		var line := index / columns
		var line_count := mini(columns, members.size() - line * columns)
		var left := (size.x - line_count * width - (line_count - 1) * GAP) * 0.5
		rows[index].position = Vector2(left + column * (width + GAP), line * (ROW_HEIGHT + GAP))
		rows[index].size = Vector2(width, ROW_HEIGHT)
		frames[index].size = rows[index].size
		var inset := frames[index].cap_width() + 2
		labels[index].position = Vector2(inset, 3)
		labels[index].size = Vector2(maxf(width - inset * 2, 0), 18)
	var height := ceili(float(members.size()) / columns) * (ROW_HEIGHT + GAP) - GAP if not members.is_empty() else 0.0
	if size.y != height: size.y = height
