extends CanvasLayer
## Wall-clock pacing and sparse drawing only; never changes simulation delta.

var speed := 4.0
var held := false
var cancelled := false
var ticks := 0
var capture_path := ""
var captured := false
var captured_phases: Dictionary = {}
var decision_draws := 0
var description := ""
var phase := "Kampf"
var decision_detail := ""
var decision_seconds := 2.0
var decision_remaining := 0.0
var game: Node
var caption: Label
var pause_button: Button
var toolbar: PanelContainer
var speeds: Array[Button] = []
var next_tick_at := 0
var next_draw_at := 0
var started_at := 0
var manual_render := false
var old_render_loop := true
var old_auto_quit := true
var old_min_size := Vector2i.ZERO
var events: Array[Dictionary] = []

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	layer = 120
	started_at = Time.get_ticks_usec()
	manual_render = DisplayServer.get_name() != "headless"
	old_render_loop = RenderingServer.render_loop_enabled
	if manual_render: RenderingServer.render_loop_enabled = false
	var window := get_tree().root
	old_auto_quit = get_tree().auto_accept_quit
	get_tree().auto_accept_quit = false
	old_min_size = window.min_size
	window.close_requested.connect(cancel)
	window.min_size = Vector2i(960, 600)
	var panel := PanelContainer.new()
	toolbar = panel
	panel.theme = DentiUIStyle.make_theme()
	add_child(panel)
	panel.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_WIDE)
	panel.offset_left = 12
	panel.offset_right = -12
	panel.offset_top = -62
	panel.offset_bottom = -12
	var style := StyleBoxFlat.new()
	style.bg_color = DentiUIStyle.PANEL
	style.border_color = DentiUIStyle.LINE
	style.set_border_width_all(1)
	style.set_corner_radius_all(10)
	style.content_margin_left = 12
	style.content_margin_right = 12
	style.content_margin_top = 6
	style.content_margin_bottom = 6
	panel.add_theme_stylebox_override("panel", style)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 8)
	panel.add_child(row)
	caption = Label.new()
	caption.add_theme_font_size_override("font_size", 15)
	caption.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	caption.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	caption.clip_text = true
	row.add_child(caption)
	pause_button = _button(row, "Pause", toggle_pause)
	pause_button.tooltip_text = "Leertaste"
	for value in [1, 4, 8, 16]:
		var button := _button(row, "%d×" % value, set_speed.bind(float(value)))
		speeds.append(button)
	var stop := _button(row, "×", cancel)
	stop.tooltip_text = "Abbrechen · Esc"
	_refresh()

func _button(parent: Control, text: String, action: Callable) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size = Vector2(46, 36)
	button.focus_mode = Control.FOCUS_NONE
	button.pressed.connect(action)
	MenuStyle.action(button)
	parent.add_child(button)
	return button

func _refresh() -> void:
	if pause_button == null: return
	pause_button.text = "Weiter" if held else "Pause"
	for index in speeds.size(): MenuStyle.action(speeds[index], is_equal_approx(speed, [1.0, 4.0, 8.0, 16.0][index]))

func toggle_pause() -> void:
	held = not held
	events.append({"tick": ticks, "pause": held})
	next_tick_at = 0
	_refresh()

func set_speed(value: float) -> void:
	speed = clampf(value, 1, 16)
	events.append({"tick": ticks, "speed": speed})
	next_tick_at = 0
	_refresh()

func cancel() -> void:
	cancelled = true
	held = false
	events.append({"tick": ticks, "cancel": true})

func pace_delay(now: int) -> int:
	if next_tick_at == 0: next_tick_at = now
	var delay := maxi(next_tick_at - now, 0)
	var interval := roundi(1000000.0 / (60.0 * speed))
	next_tick_at = maxi(next_tick_at, now - 250000) + interval
	return delay

func _input(event: InputEvent) -> void:
	# Keep this a spectator: hovering/scrolling may inspect cards, but purchases
	# and reward choices belong to the pilot. Viewer buttons still receive clicks.
	if is_instance_valid(game):
		if event is InputEventMouseButton and event.button_index <= MOUSE_BUTTON_MIDDLE and not toolbar.get_global_rect().has_point(event.position):
			get_viewport().set_input_as_handled()
			return
		if event is InputEventJoypadButton or event is InputEventJoypadMotion:
			get_viewport().set_input_as_handled()
			return
		if event is InputEventKey and event.keycode not in [KEY_SPACE, KEY_ESCAPE]:
			get_viewport().set_input_as_handled()
			return
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_SPACE:
		toggle_pause()
	elif event.keycode == KEY_ESCAPE:
		cancel()
	else:
		return
	get_viewport().set_input_as_handled()

func before_step() -> bool:
	decision_detail = ""
	while held and not cancelled:
		get_tree().paused = true
		await get_tree().process_frame
		OS.delay_msec(8)
	if cancelled: return false
	if manual_render:
		# Catch up after drawing/V-Sync without merging physics ticks. Cap only
		# long stalls (window dragging/shader warmup); pause/speed reset the clock.
		var delay := pace_delay(Time.get_ticks_usec())
		if delay > 0: OS.delay_usec(delay)
	ticks += 1
	return true

func present_decision(phase_name: String, detail: String) -> bool:
	phase = phase_name
	decision_detail = detail
	decision_draws = 0
	events.append({"tick": ticks, "wave": int(game.wave.current_wave) if is_instance_valid(game) else 0,
		"phase": phase_name, "decision": detail})
	get_tree().paused = true
	# The selected speed also advances shop/reward reading time. No gameplay or
	# physics ticks or pilot observations are added while these panels are open.
	decision_remaining = decision_seconds
	var previous := Time.get_ticks_usec()
	while decision_remaining > 0 or held:
		if cancelled: return false
		var was_held := held
		await get_tree().process_frame
		OS.delay_msec(8)
		var now := Time.get_ticks_usec()
		if not was_held: advance_reading_time((now - previous) / 1000000.0)
		previous = now
	next_tick_at = 0
	return not cancelled

func advance_reading_time(seconds: float) -> void:
	if not held: decision_remaining = maxf(0.0, decision_remaining - seconds * speed)

func _process(_delta: float) -> void:
	var elapsed := maxf((Time.get_ticks_usec() - started_at) / 1000000.0, 0.001)
	var wave := int(game.wave.current_wave) if is_instance_valid(game) else 0
	caption.text = "Bot · %s · W%d · %s · %.0f× (%.1f×)" % [description, wave, phase, speed, ticks / 60.0 / elapsed]
	if not decision_detail.is_empty(): caption.text = "Bot · W%d · %s · %s" % [wave, phase, decision_detail]
	if not manual_render or Time.get_ticks_usec() < next_draw_at: return
	RenderingServer.force_draw()
	# Schedule after drawing: a slow draw must not make every simulation tick draw.
	next_draw_at = Time.get_ticks_usec() + 16667
	if not captured and not capture_path.is_empty() and ticks >= 300:
		DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
		get_viewport().get_texture().get_image().save_png(capture_path)
		captured = true
	if not decision_detail.is_empty() and not capture_path.is_empty():
		decision_draws += 1
		var suffix: String = {"Aufstieg": "level", "Verzauberungen": "enchantments", "Shop": "shop", "Truhe": "chest"}.get(phase, "")
		if decision_draws >= 2 and not suffix.is_empty() and not captured_phases.has(suffix):
			DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
			get_viewport().get_texture().get_image().save_png(capture_path.get_basename() + "_" + suffix + ".png")
			captured_phases[suffix] = true

func _exit_tree() -> void:
	if manual_render: RenderingServer.render_loop_enabled = old_render_loop
	get_tree().auto_accept_quit = old_auto_quit
	get_tree().root.min_size = old_min_size
