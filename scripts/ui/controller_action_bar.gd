class_name ControllerActionBar
extends CanvasLayer

const HEIGHT := 48.0
const GLYPH_SIZE := 24.0
const FONT_SIZE := 16
const ICON_GAP := 8.0
const ACTION_GAP := 22.0
const ORDER: Array[StringName] = [&"ui_accept", &"ui_cancel", &"ui_reroll", &"ui_details", &"pause"]

var strip: Control
var entries: Array[Dictionary] = []
var glyph_rects: Array[Rect2] = []
var text_rects: Array[Rect2] = []
var input: Node
var font: Font
var render_font_size := FONT_SIZE
var signature := ""

static func reserve(control: Control) -> float:
	if not is_instance_valid(control) or not control.is_inside_tree() or control.is_queued_for_deletion(): return 0.0
	var source := control.get_node_or_null("/root/GameInput")
	return HEIGHT * MenuLayout.ui_scale(control.get_viewport()) if source != null and source.using_controller else 0.0

static func content_rect(control: Control, bounds: Rect2) -> Rect2:
	bounds.size.y = maxf(1, bounds.size.y - reserve(control))
	return bounds

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	input = get_parent()
	strip = Control.new()
	strip.name = "ControllerActions"
	strip.mouse_filter = Control.MOUSE_FILTER_IGNORE
	strip.theme = DentiUIStyle.make_theme()
	add_child(strip)
	font = strip.get_theme_font("font", "Label")
	strip.draw.connect(_draw_strip)
	visible = false

func _process(_delta: float) -> void:
	if not input.using_controller:
		visible = false
		return
	var current: Dictionary = input.navigation.top_scope()
	visible = input.using_controller and not current.is_empty()
	if not visible: return
	var scope: Control = current.scope.get_ref()
	entries = _actions(scope)
	visible = not entries.is_empty()
	if not visible: return
	var extent := get_viewport().get_visible_rect().size
	var factor := MenuLayout.ui_scale(get_viewport())
	var safe := HUDLayout.safe_rect(extent)
	var margin := 12.0 if safe.size.x / factor < 600 else 48.0
	strip.scale = Vector2.ONE * factor
	strip.position = Vector2(safe.position.x + margin * factor, safe.end.y - HEIGHT * factor)
	strip.size = Vector2(maxf(1, safe.size.x / factor - margin * 2), HEIGHT)
	var state: String = str(entries) + input.family() + str(strip.size) + str(factor)
	if state != signature:
		signature = state
		_layout_entries()
		strip.queue_redraw()

func _actions(scope: Control) -> Array[Dictionary]:
	if input.navigation.popup_open(): return [{"action": &"ui_cancel", "label": "Schließen"}]
	var shortcuts: Dictionary = {}
	var focus := get_viewport().gui_get_focus_owner()
	for prompt: ControllerPrompt in get_tree().get_nodes_in_group("controller_prompts"):
		if prompt.focused_only or not ControllerFocus.available(prompt.target) or not ControllerFocus.contains(scope, prompt.target): continue
		var action := prompt.action
		if action == &"ui_accept" or action == &"dash": continue
		shortcuts[action] = _shortcut_label(prompt)
	var back := str(scope.get_meta("controller_back", ""))
	# A parent screen can provide its Back action to its nested layout stage.
	var parent := scope.get_parent()
	while back.is_empty() and parent != null:
		back = str(parent.get_meta("controller_back", ""))
		parent = parent.get_parent()
	if not back.is_empty() and not shortcuts.has(&"ui_cancel") and not shortcuts.has(&"pause"):
		shortcuts[&"ui_cancel"] = back
	var focused_shortcut := focus.get_node_or_null("ControllerPrompt") as ControllerPrompt if focus != null else null
	var redundant := focused_shortcut != null and not focused_shortcut.focused_only and shortcuts.has(focused_shortcut.action)
	if ControllerFocus.contains(scope, focus) and ControllerFocus.available(focus) and not focus is Range and not focus is LineEdit and not redundant:
		shortcuts[&"ui_accept"] = _selection_label(focus)
	var result: Array[Dictionary] = []
	for action in ORDER:
		if shortcuts.has(action): result.append({"action": action, "label": shortcuts[action]})
	return result

func _shortcut_label(prompt: ControllerPrompt) -> String:
	match prompt.action:
		&"ui_reroll": return "Würfeln"
		&"ui_details": return "Details"
		&"pause": return "Fortsetzen"
	var label: String = prompt.target.text if prompt.target is Button else ""
	return label if label in ["Zurück", "Schließen", "Abbrechen", "Fertig"] else "Zurück"

func _selection_label(control: Control) -> String:
	if control is OfferCard or control is PanelContainer: return "Details"
	if control is OptionButton: return "Öffnen"
	if control is CheckButton: return "Ändern"
	if control is Button:
		var label: String = control.text
		if label.contains("starten"): return "Starten"
		for action in ["Kaufen", "Verkaufen", "Fusionieren", "Verzaubern", "Rückgängig", "Zerlegen", "Fertig", "Anzeigen", "Weiter", "Fortsetzen"]:
			if label.begins_with(action): return action
		if control.tooltip_text.begins_with("Kaufen"): return "Kaufen"
	return "Wählen"

func _layout_entries() -> void:
	glyph_rects.clear()
	text_rects.clear()
	var gap := 14.0 if strip.size.x < 600 else ACTION_GAP
	var total := 0.0
	for entry in entries:
		total += GLYPH_SIZE + ICON_GAP + font.get_string_size(entry.label, HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x
	total += gap * maxi(0, entries.size() - 1)
	var factor := minf(1, strip.size.x / maxf(total, 1))
	var x := 0.0
	var side := GLYPH_SIZE * factor
	render_font_size = maxi(14, floori(FONT_SIZE * factor))
	for entry in entries:
		var glyph := Rect2(x, (HEIGHT - side) * 0.5, side, side)
		glyph_rects.append(glyph)
		x += side + ICON_GAP * factor
		var width := font.get_string_size(entry.label, HORIZONTAL_ALIGNMENT_LEFT, -1, render_font_size).x
		text_rects.append(Rect2(x, (HEIGHT - font.get_height(render_font_size)) * 0.5, width, font.get_height(render_font_size)))
		x += width + gap * factor

func _draw_strip() -> void:
	strip.draw_rect(Rect2(Vector2.ZERO, strip.size), DentiUIStyle.BACKGROUND)
	strip.draw_line(Vector2.ZERO, Vector2(strip.size.x, 0), DentiUIStyle.LINE, 1, true)
	for index in mini(entries.size(), glyph_rects.size()):
		var entry := entries[index]
		strip.draw_texture_rect(ControllerGlyphs.texture(entry.action, input.family()), glyph_rects[index], false)
		var baseline := text_rects[index].position + Vector2(0, font.get_ascent(render_font_size))
		strip.draw_string(font, baseline, entry.label, HORIZONTAL_ALIGNMENT_LEFT, -1, render_font_size, DentiUIStyle.INK)
