class_name StoryTravel
extends CanvasLayer

signal arrived(chapter_index: int)
signal reveal_finished
signal finished
const DURATION := 2.6
const ARRIVAL_POINT := 0.60
const TITLE: Texture2D = preload("res://assets/story/title.png")
const DENTI: Texture2D = preload("res://assets/denti/denti_unarmed.png")

var root_control: Control
var logo: TextureRect
var heading: Label
var cards: Array[StoryTravelCard] = []
var route: Control
var denti: TextureRect
var next_button: Button
var progress: StoryProgress
var arrival_sent: bool = false
var last_revealed: int = -1
var card_positions: Array[Vector2] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 26
	visible = false
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.theme = DentiUIStyle.make_theme()
	add_child(root_control)
	var background := ColorRect.new()
	background.color = DentiUIStyle.BACKGROUND
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(background)
	logo = TextureRect.new()
	logo.texture = TITLE
	logo.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	logo.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	logo.mouse_filter = Control.MOUSE_FILTER_IGNORE
	root_control.add_child(logo)
	heading = Label.new()
	heading.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	heading.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	heading.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	heading.add_theme_color_override("font_color", DentiUIStyle.GOLD)
	root_control.add_child(heading)
	for index in 4:
		var card := StoryTravelCard.new()
		root_control.add_child(card)
		cards.append(card)
		card_positions.append(Vector2.ZERO)
	route = Control.new()
	root_control.add_child(route)
	route.draw.connect(_draw_route)
	denti = TextureRect.new()
	denti.texture = DENTI
	denti.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	denti.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	denti.mouse_filter = Control.MOUSE_FILTER_IGNORE
	route.add_child(denti)
	next_button = Button.new()
	next_button.custom_minimum_size = Vector2(144, 44)
	DentiUIStyle.style_button(next_button, true)
	DentiUIMotion.bind_action(next_button)
	next_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	next_button.pressed.connect(advance)
	root_control.add_child(next_button)
	get_viewport().size_changed.connect(_layout)

func present(state: StoryProgress) -> void:
	progress = state
	arrival_sent = state.chapter_index >= state.travel_target
	last_revealed = -1
	for card in cards:
		card.scale = Vector2.ONE
		card.modulate.a = 1
	visible = true
	if not DentiUIMotion.enabled(root_control):
		progress.travel_progress = 1
	_layout()
	_render()
	if progress.travel_progress >= 1:
		reveal_finished.emit()
	next_button.grab_focus()

func _process(delta: float) -> void:
	if not visible or progress == null or progress.travel_progress >= 1:
		return
	progress.travel_progress = minf(1, progress.travel_progress + delta / DURATION) if DentiUIMotion.enabled(root_control) else 1.0
	_render()
	if progress.travel_progress >= 1:
		reveal_finished.emit()

func advance() -> void:
	if not visible:
		return
	if progress.travel_progress < 1:
		progress.travel_progress = 1
		_render()
		reveal_finished.emit()
		return
	finished.emit()

func _render() -> void:
	if progress == null or progress.travel_target < 0:
		return
	var amount := progress.travel_progress
	if amount >= ARRIVAL_POINT and not arrival_sent:
		arrival_sent = true
		arrived.emit(progress.travel_target)
	if last_revealed != progress.revealed_chapters:
		last_revealed = progress.revealed_chapters
		for index in 4:
			var known := index < progress.revealed_chapters
			cards[index].set_world(StoryCatalog.chapter_art(index) if known else null,
				("%s · %s" % [["I", "II", "III", "IV"][index], StoryCatalog.chapter(index).title]) if known else "Unentdeckt",
				index == progress.travel_target and known)
	heading.text = "Kapitel %s · %s" % [["I", "II", "III", "IV"][progress.chapter_index], StoryCatalog.chapter(progress.chapter_index).title]
	if arrival_sent:
		var reveal := clampf((amount - ARRIVAL_POINT) / (1 - ARRIVAL_POINT), 0, 1)
		reveal = 1.0 - pow(1.0 - reveal, 3)
		var card := cards[progress.travel_target]
		card.scale = Vector2(lerpf(0.05, 1, reveal), lerpf(0.92, 1, reveal))
		card.modulate.a = lerpf(0.15, 1, reveal)
		card.position = card_positions[progress.travel_target] + Vector2(0, (1 - reveal) * 22)
	var travel := smoothstep(0.0, ARRIVAL_POINT, amount)
	var start := _node_position(progress.travel_target - 1)
	var destination := _node_position(progress.travel_target)
	var at := start.lerp(destination, travel)
	var bounce := sin(amount * TAU * 5) * 3 if amount < ARRIVAL_POINT and DentiUIMotion.enabled(root_control) else 0.0
	denti.position = at - Vector2(19, 48 + bounce)
	denti.size = Vector2(38, 38)
	next_button.text = "Weiter" if amount >= 1 else "Ankommen"
	route.queue_redraw()

func _layout() -> void:
	if not is_inside_tree() or progress == null:
		return
	var extent := get_viewport().get_visible_rect().size
	var short := extent.y < 480
	var narrow := extent.x < 700
	var margin := 16.0 if narrow else 28.0
	var logo_height := 46.0 if short else 76.0
	logo.position = Vector2((extent.x - minf(440, extent.x - 48)) / 2, 8)
	logo.size = Vector2(minf(440, extent.x - 48), logo_height)
	heading.position = Vector2(margin, logo_height + 14)
	heading.size = Vector2(extent.x - margin * 2, 40 if narrow and not short else 30)
	heading.add_theme_font_size_override("font_size", 17 if narrow else 24)
	var top := heading.position.y + heading.size.y + 8
	var bottom := extent.y - 120
	var count := 2 if narrow else 4
	var gap := 10.0
	var width := (extent.x - margin * 2 - gap * (count - 1)) / count
	if not narrow and not short:
		var art_aspect := StoryCatalog.CARDS.get_width() / (4.0 * StoryCatalog.CARDS.get_height())
		var fitted_width := (bottom - top - 34 - StoryTravelCard.BORDER * 2) * art_aspect + StoryTravelCard.BORDER * 2
		if fitted_width < 220:
			fitted_width = (bottom - top - 44 - StoryTravelCard.BORDER * 2) * art_aspect + StoryTravelCard.BORDER * 2
		width = minf(width, maxf(160, fitted_width))
	var left := (extent.x - width * count - gap * (count - 1)) / 2
	var slot := 0
	for index in 4:
		var shown := not narrow or index in [progress.travel_target - 1, progress.travel_target]
		cards[index].visible = shown
		if shown:
			card_positions[index] = Vector2(left + slot * (width + gap), top)
			cards[index].position = card_positions[index]
			cards[index].size = Vector2(width, maxf(80, bottom - top))
			slot += 1
	route.position = Vector2(margin + 8, extent.y - 104)
	route.size = Vector2(extent.x - margin * 2 - 16, 54)
	next_button.position = Vector2(extent.x - margin - 144, extent.y - 54)
	if not narrow and not short:
		route.position.x = left + width / 2 - 12
		route.size.x = (width + gap) * 3 + 24
		next_button.position.x = left + width * 4 + gap * 3 - 144
	next_button.size = Vector2(144, 44)
	_render()

func _node_position(index: int) -> Vector2:
	return Vector2(12 + (route.size.x - 24) * clampi(index, 0, 3) / 3.0, 18)

func _draw_route() -> void:
	if progress == null:
		return
	var gold := DentiUIStyle.GOLD
	route.draw_line(_node_position(0), _node_position(3), DentiUIStyle.LINE, 3, true)
	var travel := smoothstep(0.0, ARRIVAL_POINT, progress.travel_progress)
	var marker := _node_position(progress.travel_target - 1).lerp(_node_position(progress.travel_target), travel)
	route.draw_line(_node_position(0), marker, gold, 3, true)
	for index in 4:
		var pos := _node_position(index)
		var visited := index < progress.revealed_chapters
		route.draw_circle(pos, 9, gold if visited else DentiUIStyle.LINE)
		route.draw_arc(pos, 12, 0, TAU, 32, gold if index == progress.travel_target else DentiUIStyle.LINE, 1, true)
		route.draw_string(DentiUIStyle.FONT, pos + Vector2(-16, 29), ["I", "II", "III", "IV"][index], HORIZONTAL_ALIGNMENT_CENTER, 32, 12, DentiUIStyle.MUTED)
		if index < 3:
			for step in range(1, 5):
				var dot := pos.lerp(_node_position(index + 1), step / 5.0)
				route.draw_circle(dot, 3, gold if dot.x <= marker.x else DentiUIStyle.LINE)
