extends CanvasLayer
## Wall-clock pacing and sparse drawing only; never changes simulation delta.

var speed := 4.0
var held := false
var cancelled := false
var ticks := 0
var capture_path := ""
var captured := false
var description := ""
var phase := "Kampf"
var game: Node
var caption: Label
var pause_button: Button
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
	if not event is InputEventKey or not event.pressed or event.echo: return
	if event.keycode == KEY_SPACE:
		toggle_pause()
	elif event.keycode == KEY_ESCAPE:
		cancel()
	else:
		return
	get_viewport().set_input_as_handled()

func before_step() -> bool:
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

func _process(_delta: float) -> void:
	var elapsed := maxf((Time.get_ticks_usec() - started_at) / 1000000.0, 0.001)
	var wave := int(game.wave.current_wave) if is_instance_valid(game) else 0
	caption.text = "Bot · %s · W%d · %s · %.0f× (%.1f×)" % [description, wave, phase, speed, ticks / 60.0 / elapsed]
	if not manual_render or Time.get_ticks_usec() < next_draw_at: return
	RenderingServer.force_draw()
	# Schedule after drawing: a slow draw must not make every simulation tick draw.
	next_draw_at = Time.get_ticks_usec() + 16667
	if not captured and not capture_path.is_empty() and ticks >= 300:
		DirAccess.make_dir_recursive_absolute(capture_path.get_base_dir())
		get_viewport().get_texture().get_image().save_png(capture_path)
		captured = true

func _exit_tree() -> void:
	if manual_render: RenderingServer.render_loop_enabled = old_render_loop
	get_tree().auto_accept_quit = old_auto_quit
	get_tree().root.min_size = old_min_size
