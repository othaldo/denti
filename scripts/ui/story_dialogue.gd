class_name StoryDialogue
extends CanvasLayer

signal advance_requested
const DENTI: Texture2D = preload("res://assets/denti/denti_unarmed.png")
const FAIRY: Texture2D = preload("res://assets/story/tooth_fairy.png")

var root_control: Control
var panel: PanelContainer
var portrait: TextureRect
var location_label: Label
var speaker_label: Label
var body_label: Label
var counter: Label
var next_button: Button
var speech: StorySpeech
var revealing: bool = false
var cursor: int = 0
var letter_timer: float = 0.0
var completed_action: String = "Weiter"

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 25
	visible = false
	speech = StorySpeech.new()
	add_child(speech)
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.theme = DentiUIStyle.make_theme()
	add_child(root_control)
	var dim := ColorRect.new()
	dim.color = Color(0.06, 0.04, 0.09, 0.63)
	dim.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(dim)
	panel = PanelContainer.new()
	panel.minimum_size_changed.connect(func() -> void: call_deferred("_layout"))
	DentiUIStyle.style_dialog(panel)
	root_control.add_child(panel)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 10)
	panel.add_child(margin)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	margin.add_child(rows)
	location_label = ShopDetails._label(rows, "", 14)
	location_label.add_theme_color_override("font_color", DentiUIStyle.GOLD)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	rows.add_child(header)
	portrait = TextureRect.new()
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(portrait)
	speaker_label = ShopDetails._label(header, "", 25)
	speaker_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	speaker_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	speaker_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	body_label = ShopDetails._label(rows, "", 21)
	body_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	body_label.visible_characters_behavior = TextServer.VC_CHARS_AFTER_SHAPING
	body_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	body_label.mouse_filter = Control.MOUSE_FILTER_STOP
	body_label.gui_input.connect(func(event: InputEvent) -> void:
		if revealing and event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			finish_reveal()
			body_label.accept_event()
	)
	var actions := HBoxContainer.new()
	rows.add_child(actions)
	counter = ShopDetails._label(actions, "", 14)
	counter.autowrap_mode = TextServer.AUTOWRAP_OFF
	counter.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	counter.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	counter.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	next_button = Button.new()
	next_button.custom_minimum_size = Vector2(124, 44)
	DentiUIStyle.style_button(next_button, true)
	DentiUIMotion.bind_action(next_button)
	next_button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
	actions.add_child(next_button)
	next_button.pressed.connect(request_advance)
	get_viewport().size_changed.connect(_layout)

func show_line(line: Dictionary, chapter: StoryChapter, index: int, total: int) -> void:
	location_label.text = chapter.title
	speaker_label.text = str(line.get("speaker", "Denti"))
	portrait.texture = FAIRY if speaker_label.text == "Zahnfee" else DENTI
	var boss_portrait := StoryCatalog.boss_portrait(speaker_label.text)
	if boss_portrait != null:
		portrait.texture = boss_portrait
	body_label.text = str(line.get("text", ""))
	counter.text = "%d / %d" % [index + 1, total]
	completed_action = "Weiter" if index + 1 < total else str(line.get("action", "Los geht’s"))
	speech.begin_line()
	cursor = 0
	letter_timer = StorySpeech.character_interval(speaker_label.text)
	revealing = not body_label.text.is_empty() and DentiUIMotion.enabled(root_control)
	body_label.visible_characters = 0 if revealing else -1
	next_button.text = "Anzeigen" if revealing else completed_action
	next_button.tooltip_text = "Satz vollständig anzeigen" if revealing else ""
	visible = true
	DentiUIMotion.reveal(body_label)
	_layout()
	call_deferred("_layout")
	next_button.grab_focus()

func _process(delta: float) -> void:
	if not visible:
		speech.stop()
		revealing = false
		return
	if not revealing:
		return
	if not DentiUIMotion.enabled(root_control):
		finish_reveal()
		return
	# Discard long inactive-tab gaps instead of dumping a burst of letters/sounds.
	letter_timer -= minf(delta, 0.1)
	while letter_timer <= 0 and revealing:
		var glyph := body_label.text.substr(cursor, 1)
		cursor += 1
		body_label.visible_characters = cursor
		speech.syllable(speaker_label.text, glyph)
		letter_timer += StorySpeech.character_interval(speaker_label.text)
		if glyph in [".", "!", "?", "…"]:
			letter_timer += 0.18
		elif glyph in [",", ":", ";", "—"]:
			letter_timer += 0.08
		if cursor >= body_label.text.length():
			finish_reveal()

func finish_reveal() -> void:
	revealing = false
	cursor = body_label.text.length()
	body_label.visible_characters = -1
	DentiUIMotion.reset(body_label)
	next_button.text = completed_action
	next_button.tooltip_text = ""
	speech.stop()

func request_advance() -> void:
	if not visible:
		return
	if revealing:
		finish_reveal()
		return
	speech.stop()
	advance_requested.emit()

func _layout() -> void:
	if panel == null or not is_inside_tree():
		return
	var extent := get_viewport().get_visible_rect().size
	var small := extent.x < 700 or extent.y < 420
	portrait.custom_minimum_size = Vector2.ONE * (44 if extent.y < 420 else (56 if small else 72))
	body_label.add_theme_font_size_override("font_size", 17 if small else 21)
	speaker_label.add_theme_font_size_override("font_size", 18 if extent.x < 400 and speaker_label.text.length() > 12 else (22 if small else 25))
	panel.size.x = minf(650, extent.x - 32)
	panel.size.y = panel.get_combined_minimum_size().y
	panel.position = (extent - panel.size) / 2
