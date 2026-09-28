class_name GameMenu
extends CanvasLayer

@export var overlay: bool = false

var page: StringName = &"home"
var root_control: Control
var rows: VBoxContainer
var game: Node2D
var fullscreen_button: Button
var volume_button: Button
@onready var session: Node = get_node("/root/GameSession")


func _ready() -> void:
	game = get_parent() as Node2D if overlay else null
	_build_ui()
	visible = not overlay
	if not overlay:
		_show_home()


func open_pause() -> void:
	if not overlay or game == null or game.ended:
		return
	game._save_run()
	get_tree().paused = true
	visible = true
	_show_home()


func close_pause() -> void:
	visible = false
	get_tree().paused = false


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if overlay and page == &"home":
		close_pause()
	else:
		_show_home()


func _build_ui() -> void:
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.theme = DentiUIStyle.make_theme()
	add_child(root_control)
	var background := ColorRect.new()
	background.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	background.color = Color(0.10, 0.06, 0.12, 0.84) if overlay else Color(0.99, 0.96, 0.86)
	root_control.add_child(background)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(center)
	var panel := PanelContainer.new()
	panel.custom_minimum_size = Vector2(520, 0)
	DentiUIStyle.style_dialog(panel)
	center.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	margin.add_child(rows)


func _clear_rows() -> void:
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	fullscreen_button = null
	volume_button = null


func _title(text_value: String) -> void:
	var portrait := TextureRect.new()
	portrait.texture = preload("res://assets/denti/denti_gameplay.png")
	portrait.custom_minimum_size = Vector2(0, 80)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	rows.add_child(portrait)
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", DentiUIStyle.INK)
	label.add_theme_font_size_override("font_size", 34)
	rows.add_child(label)


func _text(text_value: String) -> void:
	var label := Label.new()
	label.text = text_value
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	rows.add_child(label)


func _button(text_value: String, callback: Callable, accent: bool = false, disabled: bool = false) -> Button:
	var button := Button.new()
	button.text = text_value
	button.custom_minimum_size = Vector2(0, 48)
	button.disabled = disabled
	DentiUIStyle.style_button(button, accent)
	button.pressed.connect(callback)
	rows.add_child(button)
	if rows.get_child_count() == 4 and not disabled:
		button.grab_focus()
	return button


func _show_home() -> void:
	page = &"home"
	_clear_rows()
	_title("Denti: Divine Dentistry" if not overlay else "Zahnpause")
	if overlay:
		_text("Welle %d · Level %d" % [game.wave.current_wave, game.level])
		_button("Fortsetzen", close_pause, true)
		_button("Stats", _show_stats)
		_button("Optionen", _show_options)
		_button("Hauptmenü", _to_main_menu)
	else:
		_text("Ein göttlicher Zahn gegen die Karies.")
		_button("Neues Spiel", _new_game, true)
		_button("Fortsetzen", _continue_game, false, not session.has_run())
		_button("Optionen", _show_options)
		_button("Credits", _show_credits)
		_button("Beenden", func() -> void: get_tree().quit())


func _show_stats() -> void:
	page = &"stats"
	_clear_rows()
	_title("Dentis Stats")
	var stats: PlayerStats = game.player.stats
	_text("Leben  %.0f / %.0f     Level  %d     XP  %d / %d\nMünzen  %d     Welle  %d / %d" % [stats.health, stats.max_health, game.level, game.xp, game.xp_goal, game.coins, game.wave.current_wave, WaveController.MAX_WAVES])
	_text("Bisskraft  %.0f     Härte  %.0f\nPutzeifer  %.2f Angriffe/s     Glanz  %.0f%%\nSpeichel  %.1f Leben/s     Bewegung  %.0f" % [stats.damage, stats.armor, 1.0 / stats.attack_interval, stats.crit_chance * 100.0, stats.regen, stats.move_speed])
	var weapons: Array[String] = ["Zahnbürste"]
	for weapon in game.owned_weapons:
		weapons.append("Zahnseide" if weapon == &"floss" else "Bohrer")
	_text("Waffen: " + ", ".join(weapons))
	_button("Zurück", _show_home, true)


func _show_options() -> void:
	page = &"options"
	_clear_rows()
	_title("Optionen")
	_text("Anzeige und Lautstärke")
	fullscreen_button = _button("", _toggle_fullscreen)
	volume_button = _button("", _cycle_volume)
	_refresh_option_buttons()
	_button("Zurück", _show_home, true)


func _refresh_option_buttons() -> void:
	fullscreen_button.text = "Vollbild: %s" % ("An" if session.is_fullscreen() else "Aus")
	volume_button.text = "Lautstärke: %d%%" % session.volume_percent


func _show_credits() -> void:
	page = &"credits"
	_clear_rows()
	_title("Credits")
	_text("Denti basiert auf der Projektvorlage.\nGegner-Sprites: OpenAI ImageGen\nSchrift: Fredoka · SIL Open Font License 1.1\nUI: eigenes Godot-Design")
	_button("Zurück", _show_home, true)


func _toggle_fullscreen() -> void:
	session.set_fullscreen(not session.is_fullscreen())
	_refresh_option_buttons()


func _cycle_volume() -> void:
	session.set_volume((session.volume_percent - 25 + 125) % 125)
	_refresh_option_buttons()


func _new_game() -> void:
	session.clear_run()
	session.resume_requested = false
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _continue_game() -> void:
	if not session.has_run():
		return
	session.resume_requested = true
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/game/game.tscn")


func _to_main_menu() -> void:
	game._save_run()
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/game_menu.tscn")
