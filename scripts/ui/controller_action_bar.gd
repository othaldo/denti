class_name ControllerActionBar
extends CanvasLayer

const HEIGHT := 48.0
const GLYPH_SIZE := 24.0
const FONT_SIZE := 16
const ICON_GAP := 8.0
const ACTION_GAP := 22.0
const ROW_STEP := 40.0
const ORDER: Array[StringName] = [&"ui_accept", &"ui_cancel", &"ui_reroll", &"ui_confirm", &"ui_pin", &"ui_undo", &"ui_details", &"ui_previous", &"ui_next", &"pause"]

var strip: Control
var panel: Panel
var entries: Array[Dictionary] = []
var glyph_rects: Array[Rect2] = []
var text_rects: Array[Rect2] = []
var input: Node
var font: Font
var render_font_size := FONT_SIZE
var signature := ""
var reserved_height := HEIGHT
var visible_height := HEIGHT
var context_key := ""

static func reserve(control: Control) -> float:
	if not is_instance_valid(control) or not control.is_inside_tree() or control.is_queued_for_deletion(): return 0.0
	var source := control.get_node_or_null("/root/GameInput")
	return source.action_bar.reserved_height * MenuLayout.ui_scale(control.get_viewport()) if source != null and source.using_controller else 0.0

static func content_rect(control: Control, bounds: Rect2) -> Rect2:
	bounds.size.y = maxf(1, bounds.size.y - reserve(control))
	return bounds

func _ready() -> void:
	layer = 80
	process_mode = Node.PROCESS_MODE_ALWAYS
	input = get_parent()
	panel = Panel.new()
	panel.name = "ControllerActionPanel"
	panel.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var surface := StyleBoxFlat.new()
	surface.bg_color = DentiUIStyle.BACKGROUND
	surface.border_color = DentiUIStyle.LINE
	surface.border_width_top = 1
	panel.add_theme_stylebox_override("panel", surface)
	add_child(panel)
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
	var width := maxf(1, safe.size.x / factor - margin * 2)
	var owner: Node = scope
	var parent: Node = scope
	while parent != null:
		if parent.has_meta("controller_bar_context"): owner = parent
		parent = parent.get_parent()
	var context := str(owner.get_instance_id()) + ":" + str(width)
	var state: String = str(entries) + input.family() + context + str(factor)
	if state != signature:
		signature = state
		var previous_height := reserved_height
		var same_context := context == context_key
		context_key = context
		strip.size.x = width
		_layout_entries(same_context)
		if not is_equal_approx(previous_height, reserved_height): input.changed.emit()
		strip.queue_redraw()
	strip.position = Vector2(safe.position.x + margin * factor, safe.end.y - visible_height * factor)
	strip.size = Vector2(width, visible_height)
	# The background fills the safe width; the margins belong to its contents.
	# Keep them separate so the action panel cannot appear cut off at either side.
	panel.scale = strip.scale
	panel.position = Vector2(safe.position.x, strip.position.y)
	panel.size = Vector2(safe.size.x / factor, visible_height)

func _actions(scope: Control) -> Array[Dictionary]:
	if input.navigation.popup_open():
		var popup_actions: Array[Dictionary] = [{"action": &"ui_cancel", "label": "Schließen"}]
		if input.pause_available() and not input.pause_menu.get_ref().visible: popup_actions.append({"action": &"pause", "label": "Pause"})
		return popup_actions
	var shortcuts: Dictionary = {}
	var focus := get_viewport().gui_get_focus_owner()
	for prompt: ControllerPrompt in get_tree().get_nodes_in_group("controller_prompts"):
		if prompt.focused_only or not ControllerFocus.available(prompt.target) or not ControllerFocus.contains(scope, prompt.target): continue
		var action := prompt.action
		if action == &"ui_accept" or action == &"dash": continue
		shortcuts[action] = _shortcut_label(prompt)
	if scope.has_meta("controller_shortcuts"):
		var provider: Callable = scope.get_meta("controller_shortcuts")
		shortcuts.merge(provider.call(), true)
	if input.pause_available() and not input.pause_menu.get_ref().visible: shortcuts[&"pause"] = "Pause"
	var back := str(scope.get_meta("controller_back", ""))
	# A parent screen can provide its Back action to its nested layout stage.
	var parent := scope.get_parent()
	while back.is_empty() and parent != null:
		back = str(parent.get_meta("controller_back", ""))
		parent = parent.get_parent()
	if not back.is_empty() and not shortcuts.has(&"ui_cancel"):
		shortcuts[&"ui_cancel"] = back
	var focused_shortcut := focus.get_node_or_null("ControllerPrompt") as ControllerPrompt if focus != null else null
	if focus != null and ControllerFocus.contains(scope, focus) and focus.has_meta("controller_details"): shortcuts[&"ui_details"] = "Details"
	var redundant := focused_shortcut != null and not focused_shortcut.focused_only and shortcuts.has(focused_shortcut.action)
	if focused_shortcut != null and focused_shortcut.action == &"ui_confirm":
		shortcuts.erase(&"ui_confirm")
		redundant = false
	if ControllerFocus.contains(scope, focus) and ControllerFocus.available(focus) and not focus is Range and not focus is LineEdit and not redundant and not bool(focus.get_meta("controller_info_only", false)):
		if focus.has_method("controller_actions"):
			shortcuts.merge(focus.controller_actions(), true)
		else:
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
		&"ui_confirm", &"ui_undo": return prompt.target.text
	var label: String = prompt.target.text if prompt.target is Button else ""
	return label if label in ["Zurück", "Schließen", "Abbrechen", "Fertig"] else "Zurück"

func _selection_label(control: Control) -> String:
	if control.has_meta("controller_action_label"): return str(control.get_meta("controller_action_label"))
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

func _layout_entries(keep_height: bool = false) -> void:
	glyph_rects.clear()
	text_rects.clear()
	var compact := strip.size.x < 600
	var gap := 10.0 if compact else ACTION_GAP
	var icon_gap := 6.0 if compact else ICON_GAP
	var x := 0.0
	var row := 0
	render_font_size = FONT_SIZE
	for entry in entries:
		var width := font.get_string_size(entry.label, HORIZONTAL_ALIGNMENT_LEFT, -1, render_font_size).x
		var span := GLYPH_SIZE + icon_gap + width
		if x > 0 and x + span > strip.size.x:
			row += 1
			x = 0
		var y := row * ROW_STEP
		var glyph := Rect2(x, y + (HEIGHT - GLYPH_SIZE) * 0.5, GLYPH_SIZE, GLYPH_SIZE)
		glyph_rects.append(glyph)
		x += GLYPH_SIZE + icon_gap
		text_rects.append(Rect2(x, y + (HEIGHT - font.get_height(render_font_size)) * 0.5, width, font.get_height(render_font_size)))
		x += width + gap
	var height := HEIGHT + row * ROW_STEP
	visible_height = height
	# Retain the shop's space while inspecting or moving onto its other actions.
	# Background offers must not jump when a modal has fewer available shortcuts.
	reserved_height = maxf(reserved_height, height) if keep_height else height

func _draw_strip() -> void:
	for index in mini(entries.size(), glyph_rects.size()):
		var entry := entries[index]
		strip.draw_texture_rect(ControllerGlyphs.texture(entry.action, input.family()), glyph_rects[index], false)
		var baseline := text_rects[index].position + Vector2(0, font.get_ascent(render_font_size))
		strip.draw_string(font, baseline, entry.label, HORIZONTAL_ALIGNMENT_LEFT, -1, render_font_size, DentiUIStyle.INK)
