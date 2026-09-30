class_name GameMenu
extends CanvasLayer

@export var overlay: bool = false

var page: StringName = &"home"
var root_control: Control
var rows: VBoxContainer
var game: Node2D
var menu_music: MusicController
var fullscreen_button: Button
var fps_toggle: CheckButton
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
@onready var session: Node = get_node("/root/GameSession")


func _ready() -> void:
	game = get_parent() as Node2D if overlay else null
	_build_ui()
	visible = not overlay
	if not overlay:
		menu_music = MusicController.new()
		add_child(menu_music)
		menu_music.play_menu()
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
	fps_toggle = null
	master_slider = null
	music_slider = null
	sfx_slider = null


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


func _version_info() -> void:
	var version := str(ProjectSettings.get_setting("application/config/version", "0.0.0"))
	var build := str(ProjectSettings.get_setting("denti/build", "dev"))
	var build_text := "dev" if build == "dev" else "build %s" % build
	var label := Label.new()
	label.text = "v%s · %s" % [version, build_text]
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	label.add_theme_font_size_override("font_size", 13)
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


func _volume_slider(title: String, value: int, setter: Callable) -> HSlider:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 50.0
	DentiUIStyle.style_chip(panel, Color(0.96, 0.92, 0.83))
	rows.add_child(panel)
	var row := HBoxContainer.new()
	row.add_theme_constant_override("separation", 12)
	panel.add_child(row)
	var label := Label.new()
	label.text = title
	label.custom_minimum_size.x = 85.0
	label.add_theme_color_override("font_color", DentiUIStyle.INK)
	row.add_child(label)
	var slider := HSlider.new()
	slider.min_value = 0.0
	slider.max_value = 100.0
	slider.step = 1.0
	slider.value = value
	slider.custom_minimum_size = Vector2(160, 32)
	slider.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	slider.tooltip_text = "%s-Lautstärke" % title
	DentiUIStyle.style_slider(slider)
	row.add_child(slider)
	var value_label := Label.new()
	value_label.text = "%d%%" % value
	value_label.custom_minimum_size.x = 54.0
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	value_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	row.add_child(value_label)
	slider.value_changed.connect(func(new_value: float) -> void:
		var percent := roundi(new_value)
		value_label.text = "%d%%" % percent
		setter.call(percent)
	)
	return slider


func _fps_option() -> CheckButton:
	var panel := PanelContainer.new()
	panel.custom_minimum_size.y = 46.0
	DentiUIStyle.style_chip(panel, Color(0.96, 0.92, 0.83))
	rows.add_child(panel)
	var toggle := CheckButton.new()
	toggle.text = "FPS anzeigen"
	toggle.button_pressed = session.show_fps
	DentiUIStyle.style_check_button(toggle)
	panel.add_child(toggle)
	toggle.toggled.connect(Callable(session, "set_show_fps"))
	return toggle


func _show_home() -> void:
	page = &"home"
	_clear_rows()
	_title("Denti: Divine Dentistry" if not overlay else "Zahnpause")
	if overlay:
		_text("Welle %d · Level %d · %s" % [game.wave.current_wave, game.level, DifficultyCatalog.by_id(game.wave.difficulty_id).display_name])
		_button("Fortsetzen", close_pause, true)
		_button("Stats", _show_stats)
		_button("Items", _show_items)
		_button("Optionen", _show_options)
		_button("Hauptmenü", _to_main_menu)
	else:
		_text("Ein göttlicher Zahn gegen die Karies.")
		if session.has_run():
			_button("Fortsetzen", _continue_game, true)
			_button("Neues Spiel", _new_game)
		else:
			_button("Neues Spiel", _new_game, true)
			_button("Fortsetzen", _continue_game, false, true)
		_button("Optionen", _show_options)
		_button("Credits", _show_credits)
		_button("Beenden", func() -> void: get_tree().quit())
		_version_info()


func _show_stats() -> void:
	page = &"stats"
	_clear_rows()
	_title("Dentis Stats")
	var stats: PlayerStats = game.player.stats
	_text("Leben  %.0f / %.0f     Schild  %d     Level  %d     XP  %d / %d\nMünzen  %d     Welle  %d / %d" % [stats.health, stats.max_health, stats.shield_charges, game.level, game.xp, game.xp_goal, game.coins, game.wave.current_wave, WaveController.MAX_WAVES])
	_text("Bisskraft  %.0f     Härte  %.0f\nPutzeifer  %.2f Angriffe/s     Glanz  %.0f%%\nSpeichel  %.1f Leben/s     Bewegung  %.0f     Glück  %.0f" % [stats.damage, stats.armor, 1.0 / stats.attack_interval, stats.crit_chance * 100.0, stats.regen, stats.move_speed, stats.luck])
	var weapons: Array[String] = []
	for weapon in game.player.loadout.equipped():
		weapons.append("%s %s" % [weapon.data.display_name, ["I", "II", "III", "IV"][weapon.tier - 1]])
	_text("Waffen: " + (", ".join(weapons) if not weapons.is_empty() else "noch keine"))
	_button("Zurück", _show_home, true)


func _show_items() -> void:
	page = &"items"
	_clear_rows()
	_title("Dentis Items & Relikte")
	var owned: Array[Dictionary] = game.items.all_items()
	for id in game.relics.owned:
		var relic := RelicCatalog.by_id(StringName(id))
		if relic != null:
			owned.append({"name": "Relikt: " + relic.display_name, "count": 1, "description": relic.description})
	if owned.is_empty():
		_text("Noch keine Items oder Relikte. In der Zahnklinik warten Items auf dich.")
	else:
		var scrolling := ScrollContainer.new()
		scrolling.custom_minimum_size = Vector2(450, 300)
		scrolling.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		rows.add_child(scrolling)
		var list := VBoxContainer.new()
		list.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		list.add_theme_constant_override("separation", 6)
		scrolling.add_child(list)
		for entry in owned:
			var line := Label.new()
			line.text = "%s ×%d\n%s" % [entry["name"], entry["count"], entry["description"]]
			line.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
			line.add_theme_color_override("font_color", DentiUIStyle.INK)
			list.add_child(line)
	_button("Zurück", _show_home, true)


func _show_options() -> void:
	page = &"options"
	_clear_rows()
	_title("Optionen")
	_text("Anzeige und Lautstärke")
	fullscreen_button = _button("", _toggle_fullscreen)
	fps_toggle = _fps_option()
	master_slider = _volume_slider("Gesamt", session.master_volume_percent, Callable(session, "set_master_volume"))
	music_slider = _volume_slider("Musik", session.music_volume_percent, Callable(session, "set_music_volume"))
	sfx_slider = _volume_slider("SFX", session.sfx_volume_percent, Callable(session, "set_sfx_volume"))
	_refresh_option_buttons()
	_button("Zurück", _show_home, true)


func _refresh_option_buttons() -> void:
	fullscreen_button.text = "Vollbild: %s" % ("An" if session.is_fullscreen() else "Aus")


func _show_credits() -> void:
	page = &"credits"
	_clear_rows()
	_title("Credits")
	_text("Denti basiert auf der Projektvorlage.\nGrafiken und Icons: OpenAI ImageGen\nMusik: othaldo · erstellt mit Suno\nSoundeffekte: eigens synthetisiert\nSchrift: Fredoka · SIL Open Font License 1.1\nUI: eigenes Godot-Design")
	_button("Zurück", _show_home, true)


func _toggle_fullscreen() -> void:
	session.set_fullscreen(not session.is_fullscreen())
	_refresh_option_buttons()


func _new_game() -> void:
	if session.has_run():
		_show_new_game_confirmation()
		return
	_show_difficulty()


func _show_new_game_confirmation() -> void:
	page = &"confirm_new_game"
	_clear_rows()
	_title("Neues Spiel?")
	_text("Dein aktueller Spielstand wird gelöscht.")
	_button("Abbrechen", _show_home, true)
	_button("Weiter zur Schwierigkeitswahl", _show_difficulty)


func _show_difficulty() -> void:
	page = &"difficulty"
	_clear_rows()
	_title("Schwierigkeitsgrad")
	_text("Wähle den Gegnerdruck für diesen Run.")
	var default_button: Button
	for difficulty in DifficultyCatalog.ALL:
		var unlocked: bool = session.can_select_difficulty(difficulty.id)
		var label := difficulty.display_name if unlocked else "%s · Nach Sieg auf Hard" % difficulty.display_name
		var button := _button(label, _start_new_game.bind(difficulty.id), difficulty.id == &"normal", not unlocked)
		button.tooltip_text = difficulty.description
		if difficulty.id == &"normal":
			default_button = button
	_button("Zurück", _show_home)
	if default_button != null:
		default_button.grab_focus()


func _start_new_game(difficulty_id: StringName) -> void:
	if not session.select_difficulty(difficulty_id):
		return
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
