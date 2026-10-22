class_name GameMenu
extends CanvasLayer

@export var overlay: bool = false

var setup: RunSetup
var setup_selector: RunSetupScreen
var difficulty_buttons: Dictionary = {}
var launching_run := false
var stage: MenuStage
var home: MenuHome
var settings_view: MenuSettings
var updates_view: MenuUpdates
var actions: Dictionary = {}
var home_return_focus: StringName = &""

var page: StringName = &"home"
var root_control: Control
var rows: VBoxContainer
var game: Node2D
var build_panel: PanelContainer
var build_scroll: ScrollContainer
var build_grid: GridContainer
var item_details: ShopDetails
var menu_music: MusicController
var fullscreen_toggle: CheckButton
var fps_toggle: CheckButton
var graphics_option: OptionButton
var master_slider: HSlider
var music_slider: HSlider
var sfx_slider: HSlider
var ui_sound_toggle: CheckButton
var motion_toggle: CheckButton
var menu_stage: HBoxContainer
var dentipedia: Dentipedia
var code_input: LineEdit
var code_error: Label
@onready var session: Node = get_node("/root/GameSession")


func _ready() -> void:
	game = get_parent() as Node2D if overlay else null
	_build_ui()
	visible = not overlay
	if not overlay:
		get_node("/root/SceneTransitions").present(&"menu")
		session.end_test_run()
		session.settings_visit_streak = 0
		menu_music = MusicController.new()
		add_child(menu_music)
		menu_music.play_menu()
		setup = RunSetup.load_from(_draft_path())
		setup_selector = preload("res://scenes/ui/run_setup_screen.tscn").instantiate()
		root_control.add_child(setup_selector)
		setup_selector.visible = false
		setup_selector.back_button.visible = true
		setup_selector.back_requested.connect(_setup_back)
		setup_selector.selection_changed.connect(_save_weapon_preview)
		setup_selector.chosen.connect(_launch_prepared_run)
		setup_selector.difficulty_chosen.connect(_select_setup_difficulty)
		setup_selector.next_requested.connect(_advance_setup)
		setup_selector.step_requested.connect(_visit_setup_step)
		_show_home()
		get_node("/root/GameUpdates").confirm_startup()
		get_node("/root/GameUpdates").check_for_updates.call_deferred()
		if session.setup_requested:
			session.setup_requested = false
			_choose_new_run()


func open_pause() -> void:
	if not overlay or game == null or game.ended:
		return
	game._save_run()
	get_tree().paused = true
	visible = true
	_show_home()


func close_pause() -> void:
	visible = false
	get_tree().paused = game != null and game.run_flow.requires_pause()


func _unhandled_input(event: InputEvent) -> void:
	if not visible or not event.is_action_pressed("ui_cancel"):
		return
	get_viewport().set_input_as_handled()
	if page == &"updates" and get_node("/root/GameUpdates").state == GameUpdateService.State.INSTALLING: return
	if not overlay and page in RunSetup.STEPS:
		_setup_back()
	elif overlay and page == &"home":
		close_pause()
	else:
		_return_home()


func _build_ui() -> void:
	root_control = Control.new()
	root_control.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.theme = DentiUIStyle.make_theme()
	add_child(root_control)
	MenuStyle.backdrop(root_control, overlay)
	var center := CenterContainer.new()
	center.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	root_control.add_child(center)
	var panel := PanelContainer.new()
	build_panel = panel
	panel.custom_minimum_size = Vector2(520, 0)
	DentiUIStyle.style_dialog(panel)
	menu_stage = HBoxContainer.new()
	menu_stage.add_theme_constant_override("separation", 40)
	center.add_child(menu_stage)
	menu_stage.add_child(panel)
	var margin := MarginContainer.new()
	margin.add_theme_constant_override("margin_left", 32)
	margin.add_theme_constant_override("margin_right", 32)
	margin.add_theme_constant_override("margin_top", 22)
	margin.add_theme_constant_override("margin_bottom", 24)
	panel.add_child(margin)
	rows = VBoxContainer.new()
	rows.add_theme_constant_override("separation", 10)
	margin.add_child(rows)
	get_viewport().size_changed.connect(_update_build_layout)
	stage = MenuStage.new()
	root_control.add_child(stage)
	stage.visible = false
	stage.back_requested.connect(_return_home)


func _clear_rows() -> void:
	stage.visible = false
	actions.clear()
	home = null
	settings_view = null
	updates_view = null
	menu_stage.visible = true
	for edge in ["left", "right"]:
		rows.get_parent().add_theme_constant_override("margin_" + edge, 32)
	rows.get_parent().add_theme_constant_override("margin_top", 22)
	rows.get_parent().add_theme_constant_override("margin_bottom", 24)
	if setup_selector != null: setup_selector.visible = false
	if not overlay and page not in [&"home", &"options"] and not session.code_entry_unlocked:
		session.settings_visit_streak = 0
	for child in rows.get_children():
		rows.remove_child(child)
		child.queue_free()
	build_scroll = null
	build_grid = null
	item_details = null
	dentipedia = null
	code_input = null
	code_error = null
	build_panel.custom_minimum_size = Vector2(520, 0)
	rows.add_theme_constant_override("separation", 10)
	fullscreen_toggle = null
	fps_toggle = null
	graphics_option = null
	master_slider = null
	music_slider = null
	sfx_slider = null
	ui_sound_toggle = null
	motion_toggle = null
	call_deferred("_update_build_layout")


func _title(text_value: String) -> void:
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
	menu_stage.visible = false
	home = MenuHome.new()
	var version := "v%s · %s" % [ProjectSettings.get_setting("application/config/version", "0.0.0"), ProjectSettings.get_setting("denti/build", "dev")]
	stage.present("", home, "" if overlay else version)
	var can_continue: bool = overlay or session.has_run() or FileAccess.file_exists(_draft_path())
	var context := ""
	if overlay:
		context = "Welle %d · Level %d · %s" % [game.wave.current_wave, game.level, DifficultyCatalog.by_id(game.wave.difficulty_id).display_name]
	elif session.has_run():
		var saved: Dictionary = session.load_run()
		if bool(saved.get("starter_pending", false)):
			context = "Run vorbereiten"
		else:
			context = "Welle %d · Level %d · %s" % [int(saved.get("wave", 1)), int(saved.get("level", 1)), DifficultyCatalog.by_id(StringName(str(saved.get("difficulty_id", "normal")))).display_name]
	elif can_continue:
		context = "Run vorbereiten"
	home.configure(overlay, can_continue, context, session.code_entry_unlocked, session.test_scenario_id != &"")
	home.action_requested.connect(_home_action)
	actions = home.actions
	var updates: GameUpdateService = get_node("/root/GameUpdates")
	if not overlay and updates.can_update():
		home._action(&"updates", "Updates", home.utilities, false, true)
		if not updates.changed.is_connected(_update_home_update): updates.changed.connect(_update_home_update)
		_update_home_update()
	stage._layout_content()
	stage._refresh_focus()
	if actions.has(home_return_focus):
		(actions[home_return_focus] as Button).grab_focus()
	else:
		home.primary_button.grab_focus()


func _home_action(id: StringName) -> void:
	home_return_focus = id
	match id:
		&"continue":
			if overlay: close_pause()
			else: _continue_game()
		&"new_run": _new_game()
		&"story": _new_story_game()
		&"settings": _show_options()
		&"build": _show_stats()
		&"dentipedia": _show_dentipedia()
		&"credits": _show_credits()
		&"updates": _show_updates()
		&"code": _show_code_entry()
		&"quit": get_tree().quit()
		&"main_menu": _to_main_menu()
		&"test_restart": game._restart()


func _return_home() -> void:
	if page == &"updates":
		var updates: GameUpdateService = get_node("/root/GameUpdates")
		if updates.state == GameUpdateService.State.INSTALLING: return
		if updates.state in [GameUpdateService.State.DOWNLOADING, GameUpdateService.State.VERIFYING]: updates.cancel_download()
		home_return_focus = &"updates"
	if page == &"options": home_return_focus = &"settings"
	_show_home()


func _update_home_update() -> void:
	if home == null or not is_instance_valid(home) or not home.actions.has(&"updates"): return
	var updates: GameUpdateService = get_node("/root/GameUpdates")
	var ready: bool = updates.state in [GameUpdateService.State.AVAILABLE, GameUpdateService.State.READY]
	(home.actions[&"updates"] as Button).text = "Update zurückgesetzt" if updates.restored_update else ("Update verfügbar" if ready else "Updates")


func _show_updates() -> void:
	var updates: GameUpdateService = get_node("/root/GameUpdates")
	if overlay or not updates.can_update(): return
	page = &"updates"
	_clear_rows()
	menu_stage.visible = false
	updates_view = MenuUpdates.new()
	stage.present("Updates", updates_view, "", 680)
	updates_view.configure(updates)
	if not updates.changed.is_connected(_update_install_navigation): updates.changed.connect(_update_install_navigation)
	_update_install_navigation()
	updates.check_for_updates()


func _update_install_navigation() -> void:
	if page != &"updates": return
	stage.back_button.disabled = get_node("/root/GameUpdates").state == GameUpdateService.State.INSTALLING


func _compact_title(title: String) -> void:
	DentiUIComponents.label(rows, title, 24)
	rows.add_theme_constant_override("separation", 6)


func _show_dentipedia() -> void:
	page = &"dentipedia"
	_clear_rows()
	_compact_title("Dentipedia")
	dentipedia = Dentipedia.new()
	rows.add_child(dentipedia)
	_button("Zurück", _show_home)
	_update_build_layout()


func _update_build_layout() -> void:
	if build_panel == null:
		return
	# Shrink back after a taller page; the centered HBox can retain its old size.
	menu_stage.reset_size()
	(menu_stage.get_parent() as Container).queue_sort()
	var extent := root_control.size
	if page == &"dentipedia":
		build_panel.custom_minimum_size.x = minf(960, extent.x - 24)
		if dentipedia != null:
			dentipedia.custom_minimum_size.y = maxf(80, minf(570, extent.y - 180))
		return
	if page == &"boss_details" and build_scroll != null:
		build_scroll.custom_minimum_size.y = maxf(60, minf(200, extent.y - 180))
	if page not in [&"stats", &"items"]:
		build_panel.custom_minimum_size.x = minf(480, extent.x - 32)
	if page not in [&"stats", &"items"]:
		return
	build_panel.custom_minimum_size.x = minf(620, extent.x - 24)
	if build_grid != null:
		build_grid.columns = maxi(floori((build_panel.custom_minimum_size.x - 90) / 70), 3)
		var lines := ceili(float(build_grid.get_child_count()) / build_grid.columns)
		build_scroll.custom_minimum_size.y = minf(lines * 65.0, minf(200, extent.y * 0.28))


func _show_stats() -> void:
	page = &"stats"
	_clear_rows()
	_build_navigation(&"stats")
	var stats: PlayerStats = game.player.stats
	var wave_text := "Endlos · Welle %d" % game.wave.current_wave if game.wave.endless_enabled else "Welle %d / %d" % [game.wave.current_wave, WaveController.MAX_WAVES]
	DentiUIComponents.label(rows, "Leben %.0f / %.0f · Schild %d · Level %d\nXP %d / %d · %s\nOffene Aufstiege: %d" % [stats.health, stats.max_health, stats.shield_charges, game.level, game.xp, game.xp_goal, wave_text, game.rewards.pending_levels], 16)
	var wallet := HBoxContainer.new()
	rows.add_child(wallet)
	DentiUIComponents.label(wallet, str(game.coins), 18).autowrap_mode = TextServer.AUTOWRAP_OFF
	var coin := TextureRect.new()
	coin.texture = DentiUIIcons.hud(2)
	coin.custom_minimum_size = Vector2(24, 24)
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	wallet.add_child(coin)
	if not BossEncounter.remaining(game.get_node("Enemies")).is_empty():
		var boss_details := LinkButton.new()
		boss_details.text = "Bossdetails"
		boss_details.add_theme_color_override("font_color", DentiUIStyle.GOLD)
		boss_details.pressed.connect(_show_boss_details)
		wallet.add_child(boss_details)
	var grid := GridContainer.new()
	grid.columns = 3
	grid.add_theme_constant_override("h_separation", 14)
	grid.add_theme_constant_override("v_separation", 5)
	rows.add_child(grid)
	for type in DentiAttributes.ACTIVE:
		var chip := Button.new()
		chip.icon = DentiUIIcons.stat(DentiAttributes.ICONS[type])
		chip.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		chip.expand_icon = true
		chip.add_theme_constant_override("icon_max_width", 26)
		chip.text = DentiAttributes.compact_value_text(stats, type)
		chip.tooltip_text = "%s · %s\n%s" % [DentiAttributes.name_for(type), DentiAttributes.value_text(stats, type), DentiAttributes.meaning_for(type)]
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		DentiUIStyle.style_button(chip, false, true)
		chip.add_theme_font_size_override("font_size", 14)
		grid.add_child(chip)
		chip.pressed.connect(func() -> void: DentiDentikon.open_attribute(chip, type))
	DentiUIComponents.label(rows, "Wurzeln · %d/%d" % [game.player.loadout.used_slots(), game.player.loadout.capacity], 16)
	var weapon_scroll := ScrollContainer.new()
	weapon_scroll.name = "WeaponScroll"
	weapon_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	weapon_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	weapon_scroll.custom_minimum_size.y = 68
	rows.add_child(weapon_scroll)
	var weapons := HBoxContainer.new()
	weapons.add_theme_constant_override("separation", 4)
	weapons.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	weapon_scroll.add_child(weapons)
	for weapon in game.player.loadout.equipped():
		var chip := Button.new()
		chip.text = WeaponPresentation.tier_text(weapon.data, weapon.tier)
		chip.icon = weapon.data.sprite
		chip.expand_icon = true
		chip.add_theme_constant_override("icon_max_width", 32)
		chip.custom_minimum_size = Vector2(76, 52)
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.size_flags_stretch_ratio = float(weapon.data.hands)
		chip.tooltip_text = "%s\n%s\n%s" % [WeaponPresentation.weapon_name(weapon), weapon.data.stats_text(weapon.tier), weapon.data.combat_text() + "\n" + AffixPresentation.summary(weapon, game.player.stats, game.items)]
		DentiUIStyle.style_card(chip, weapon.tier, WeaponPresentation.special_color(weapon.data))
		weapons.add_child(chip)
		chip.pressed.connect(_show_weapon_details.bind(weapon.data, weapon.tier, weapon))
	_button("Zurück", _show_home, true)
	_update_build_layout()


func _show_boss_details() -> void:
	page = &"boss_details"
	_clear_rows()
	_compact_title("Bossdetails")
	build_scroll = ScrollContainer.new()
	build_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows.add_child(build_scroll)
	var content := VBoxContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.add_theme_constant_override("separation", 12)
	build_scroll.add_child(content)
	for boss: Enemy in BossEncounter.remaining(game.get_node("Enemies")):
		DentiUIComponents.label(content, "%s\nLeben %.0f / %.0f" % [boss.data.display_name, boss.health, boss.max_health], 16)
	_button("Zurück", _show_stats, true)
	_update_build_layout()


func _show_weapon_details(data: WeaponData, tier: int, weapon: WeaponInstance = null) -> void:
	page = &"stats"
	_clear_rows()
	item_details = ShopDetails.new()
	rows.add_child(item_details)
	item_details.show_weapon(data, tier, game.player, true, [])
	if weapon != null:
		item_details.show_affixes(weapon, game.player.stats, game.items)
	_button("Zurück", _show_stats, true)
	_update_build_layout()


func _show_items() -> void:
	page = &"items"
	_clear_rows()
	_build_navigation(&"items")
	var owned := BuildPresentation.collected_entries(game.items, game.relics)
	if owned.is_empty():
		DentiUIComponents.label(rows, "Keine Items oder Relikte", 16)
	else:
		build_scroll = ScrollContainer.new()
		build_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
		rows.add_child(build_scroll)
		build_grid = GridContainer.new()
		build_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		build_grid.add_theme_constant_override("h_separation", 5)
		build_grid.add_theme_constant_override("v_separation", 5)
		build_scroll.add_child(build_grid)
		item_details = ShopDetails.new()
		rows.add_child(item_details)
		for entry in owned:
			var chip := Button.new()
			chip.custom_minimum_size = Vector2(64, 60)
			chip.tooltip_text = "%s ×%d\n%s" % [entry.name, entry.count, entry.description]
			DentiUIStyle.style_button(chip)
			build_grid.add_child(chip)
			var icon := TextureRect.new()
			icon.texture = entry.icon
			icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
			icon.offset_left = 6
			icon.offset_right = -6
			icon.offset_top = 4
			icon.offset_bottom = -8
			icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chip.add_child(icon)
			var count := Label.new()
			count.text = "×%d" % int(entry.count)
			count.add_theme_font_size_override("font_size", 14)
			count.add_theme_color_override("font_color", DentiUIStyle.INK)
			count.add_theme_color_override("font_outline_color", DentiUIStyle.PANEL)
			count.add_theme_constant_override("outline_size", 4)
			count.mouse_filter = Control.MOUSE_FILTER_IGNORE
			chip.add_child(count)
			count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
			count.offset_right = -4
			count.offset_bottom = -2
			chip.pressed.connect(item_details.show_item.bind(entry, true))
		item_details.show_item(owned[0], true)
	_button("Zurück", _show_home, true)
	_update_build_layout()


func _show_options() -> void:
	if not overlay and page == &"home":
		session.visit_settings_for_code_entry()
	page = &"options"
	_clear_rows()
	menu_stage.visible = false
	settings_view = MenuSettings.new()
	stage.present("Einstellungen", settings_view, "", 1100)
	settings_view.configure(session)
	fullscreen_toggle = settings_view.fullscreen_toggle
	fps_toggle = settings_view.fps_toggle
	graphics_option = settings_view.graphics_option
	master_slider = settings_view.master_slider
	music_slider = settings_view.music_slider
	sfx_slider = settings_view.sfx_slider
	ui_sound_toggle = settings_view.ui_sound_toggle
	motion_toggle = settings_view.motion_toggle
	actions[&"back"] = stage.back_button
	stage._refresh_focus()
	stage.back_button.grab_focus()


func _build_navigation(active: StringName) -> void:
	rows.add_theme_constant_override("separation", 6)
	var tabs := HBoxContainer.new()
	tabs.add_theme_constant_override("separation", 8)
	rows.add_child(tabs)
	for id in [&"stats", &"items"]:
		var button := Button.new()
		button.text = "Werte" if id == &"stats" else "Items & Relikte"
		MenuStyle.action(button, false, true)
		RunSetupStyle.choice(button, id == active, false)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		tabs.add_child(button)
		button.pressed.connect(_show_stats if id == &"stats" else _show_items)
		actions[id] = button


func _show_code_entry() -> void:
	if overlay or not session.code_entry_unlocked:
		return
	page = &"code_entry"
	_clear_rows()
	_title("Code eingeben")
	_text("Code für eine Testarena eingeben.")
	code_input = LineEdit.new()
	code_input.name = "TestCode"
	code_input.placeholder_text = "Code"
	code_input.max_length = 48
	code_input.clear_button_enabled = true
	code_input.custom_minimum_size = Vector2(0, 52)
	code_input.add_theme_stylebox_override("normal", DentiUIStyle._box(DentiUIStyle.RAISED, DentiUIStyle.LINE, 12, 1))
	code_input.add_theme_stylebox_override("focus", DentiUIStyle._box(Color.TRANSPARENT, DentiUIStyle.GOLD, 12, 2))
	code_input.add_theme_color_override("font_color", DentiUIStyle.INK)
	code_input.add_theme_color_override("caret_color", DentiUIStyle.INK)
	rows.add_child(code_input)
	code_input.text_submitted.connect(_activate_test_code)
	code_error = Label.new()
	code_error.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	code_error.add_theme_color_override("font_color", DentiUIStyle.CORAL)
	rows.add_child(code_error)
	_button("Test starten", func() -> void: _activate_test_code(code_input.text), true)
	_button("Zurück", _show_home)
	code_input.grab_focus()


func _activate_test_code(code: String) -> void:
	if overlay or not session.code_entry_unlocked or code_input == null:
		return
	var scenario := TestArenaCatalog.by_code(code)
	if scenario == null or not session.begin_test_run(scenario.id):
		code_error.text = "Code nicht erkannt."
		return
	code_input.release_focus()
	get_tree().paused = false
	get_node("/root/SceneTransitions").change_scene("res://scenes/game/game.tscn")


func _show_credits() -> void:
	page = &"credits"
	_clear_rows()
	_title("Credits")
	_text("Denti basiert auf der Projektvorlage.\nGrafiken und Icons: OpenAI ImageGen\nMusik: othaldo · erstellt mit Suno\nSoundeffekte: eigens synthetisiert\nSchrift: Fredoka · SIL Open Font License 1.1\nUI: eigenes Godot-Design")
	_button("Zurück", _show_home, true)


func _new_game() -> void:
	session.selected_story_mode = false
	_choose_new_run()


func _new_story_game() -> void:
	session.selected_story_mode = true
	_choose_new_run()


func _choose_new_run() -> void:
	if setup == null or setup.story_mode != session.selected_story_mode:
		setup = RunSetup.new()
		setup.story_mode = session.selected_story_mode
		setup.difficulty_id = session.selected_difficulty_id
	setup.resume_pending = false
	setup.root_capacity = PlayerStats.DEFAULT_ROOT_CAPACITY
	if session.has_run():
		_show_new_game_confirmation()
		return
	_show_difficulty()


func _show_new_game_confirmation() -> void:
	page = &"confirm_new_game"
	_clear_rows()
	menu_stage.visible = false
	var content := VBoxContainer.new()
	content.alignment = BoxContainer.ALIGNMENT_CENTER
	content.add_theme_constant_override("separation", 24)
	stage.present("Neuer Run?", content, "", 640)
	var consequence := Label.new()
	consequence.text = "Dein aktueller Run wird erst ersetzt, wenn du den neuen Run startest."
	consequence.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	consequence.add_theme_font_size_override("font_size", 18)
	content.add_child(consequence)
	var choices := VBoxContainer.new()
	choices.add_theme_constant_override("separation", 12)
	content.add_child(choices)
	for id in [&"confirm_new_run", &"cancel"]:
		var button := Button.new()
		button.text = "Run vorbereiten" if id == &"confirm_new_run" else "Abbrechen"
		MenuStyle.action(button, id == &"confirm_new_run", id == &"cancel")
		choices.add_child(button)
		button.pressed.connect(_show_difficulty if id == &"confirm_new_run" else _return_home)
		actions[id] = button
	stage._refresh_focus()
	stage.back_button.grab_focus()


func _draft_path() -> String:
	return session.save_path + ".setup.json"


func _show_difficulty() -> void:
	if setup == null:
		setup = RunSetup.new()
		setup.story_mode = session.selected_story_mode
	if not session.can_select_difficulty(setup.difficulty_id): setup.difficulty_id = &"normal"
	setup.step = &"difficulty"
	page = setup.step
	_clear_rows()
	menu_stage.visible = false
	setup_selector.visible = true
	setup_selector.show_difficulty(setup, Callable(session, "can_select_difficulty"))
	difficulty_buttons = setup_selector.difficulty_view.buttons
	setup.save_to(_draft_path())


func _select_setup_difficulty(id: StringName) -> void:
	if setup == null or not session.can_select_difficulty(id): return
	setup.difficulty_id = id
	setup_selector.current_difficulty = id
	setup_selector.difficulty_view.selected_id = id
	setup_selector.difficulty_view.refresh()
	setup.save_to(_draft_path())


func _visit_setup_step(id: StringName) -> void:
	if setup == null or not setup.can_visit(id) or setup_selector.details.visible: return
	setup.step = id
	_show_setup_step()


func _advance_setup() -> void:
	if setup == null or not session.can_select_difficulty(setup.difficulty_id): return
	setup.next_step()
	_show_setup_step()


func _setup_back() -> void:
	if setup != null and setup.previous_step():
		_show_setup_step()
	else:
		_show_home()


func _show_setup_step() -> void:
	match setup.step:
		&"difficulty": _show_difficulty()
		&"weapon": _show_setup_weapons()


func _show_setup_weapons() -> void:
	page = &"weapon"
	setup.step = page
	_clear_rows()
	menu_stage.visible = false
	setup_selector.visible = true
	var options: Array[WeaponData] = []
	for weapon in WeaponCatalog.ALL:
		if weapon.hands <= setup.root_capacity: options.append(weapon)
	setup.mark_reached(page)
	setup_selector.show_preparation(setup, options)
	setup.weapon_id = setup_selector.selected_id
	setup.save_to(_draft_path())


func _save_weapon_preview() -> void:
	if setup == null or page != &"weapon": return
	setup.weapon_id = setup_selector.selected_id
	setup.save_to(_draft_path())


# Kept for preview/timing tools: selecting difficulty only advances preparation.
func _start_new_game(difficulty_id: StringName) -> void:
	if setup == null: setup = RunSetup.new()
	_select_setup_difficulty(difficulty_id)
	_advance_setup()


func _launch_prepared_run(weapon: WeaponData) -> void:
	if launching_run or setup == null or weapon not in WeaponCatalog.ALL or weapon.hands > setup.root_capacity:
		return
	if not session.select_difficulty(setup.difficulty_id):
		_show_difficulty()
		return
	launching_run = true
	session.selected_story_mode = setup.story_mode
	session.pending_start_weapon_id = weapon.id
	var saved: Dictionary = session.load_run() if setup.resume_pending else {}
	if not saved.is_empty() and bool(saved.get("starter_pending", false)):
		saved["difficulty_id"] = str(setup.difficulty_id)
		session.save_run(saved)
		session.resume_requested = true
	else:
		session.clear_run()
		session.resume_requested = false
	RunStore.clear(_draft_path())
	get_tree().paused = false
	get_node("/root/SceneTransitions").change_scene("res://scenes/game/game.tscn")


func _continue_game() -> void:
	var saved: Dictionary = session.load_run()
	if not saved.is_empty() and bool(saved.get("starter_pending", false)):
		var draft := RunSetup.load_from(_draft_path())
		if draft != null and draft.resume_pending:
			setup = draft
			_show_setup_step()
			return
		# Migrate old pre-wave saves into the menu without loading the arena.
		setup = RunSetup.new()
		setup.step = &"weapon"
		setup.difficulty_id = DifficultyCatalog.by_id(StringName(str(saved.get("difficulty_id", "normal")))).id
		setup.weapon_id = StringName(str(saved.get("starter_preview", "")))
		setup.story_mode = bool(saved.get("story", {}).get("enabled", false))
		setup.root_capacity = int(saved.get("player", {}).get("stats", {}).get("root_capacity", PlayerStats.DEFAULT_ROOT_CAPACITY))
		setup.resume_pending = true
		_show_setup_step()
		return
	if saved.is_empty():
		setup = RunSetup.load_from(_draft_path())
		if setup != null:
			if not session.can_select_difficulty(setup.difficulty_id):
				setup.difficulty_id = &"normal"
				setup.step = &"difficulty"
			_show_setup_step()
		return
	session.pending_start_weapon_id = &""
	session.resume_requested = true
	get_tree().paused = false
	get_node("/root/SceneTransitions").change_scene("res://scenes/game/game.tscn")


func _to_main_menu() -> void:
	game._save_run()
	get_tree().paused = false
	get_node("/root/SceneTransitions").change_scene("res://scenes/ui/game_menu.tscn")
