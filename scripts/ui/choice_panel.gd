class_name ChoicePanel
extends CanvasLayer

signal upgrade_chosen(upgrade: UpgradeData)
signal level_reroll_requested
signal chest_resolved(keep: bool)
signal relic_chosen(id: StringName)
signal starter_chosen(weapon: WeaponData)
signal starter_preview_changed
signal restart_requested
signal main_menu_requested
signal endless_requested
const UPGRADE_COUNT := 4

var title_label: Label
var subtitle_label: Label
var dialog_panel: Control
var cards: GridContainer
var level_actions: HBoxContainer
var level_coins: Label
var reroll_button: Button
var buttons: Array[UpgradeCard] = []
var stage: RewardStage
var reward_view: RewardChoices
var starter_selection: StarterSelection
var current_upgrades: Array[UpgradeData] = []
var starter_options: Array[WeaponData] = []
var mode: StringName = &"upgrade"
var end_won := false
var end_coins := 0
var chest_item: ShopOfferData
var relic_options: Array[RelicData] = []
var end_recap: Dictionary = {}

@onready var legacy_panel: PanelContainer = $Root/Center/Panel
@onready var legacy_cards: GridContainer = $Root/Center/Panel/Margin/Rows/Cards
@onready var legacy_title: Label = $Root/Center/Panel/Margin/Rows/Title
@onready var legacy_subtitle: Label = $Root/Center/Panel/Margin/Rows/Subtitle
var legacy_buttons: Array[UpgradeCard] = []

func _ready() -> void:
	visible = false
	$Root.theme = DentiUIStyle.make_theme()
	$Root/Dim.color = Color(0.12, 0.06, 0.13, 0.78)
	DentiUIStyle.style_dialog(legacy_panel)
	$Root/Center/Panel/Margin/Rows/LevelActions.hide()
	for index in UPGRADE_COUNT:
		legacy_buttons.append(legacy_cards.get_child(index))
		legacy_buttons[index].pressed.connect(_on_choice_pressed.bind(index))
	stage = RewardStage.new()
	$Root.add_child(stage)
	reward_view = RewardChoices.new()
	stage.present("Aufstieg", reward_view)
	for index in reward_view.buttons.size():
		reward_view.buttons[index].pressed.connect(_on_choice_pressed.bind(index))
	level_actions = HBoxContainer.new()
	level_actions.add_theme_constant_override("separation", 8)
	level_actions.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	stage.footer.add_child(level_actions)
	level_coins = Label.new()
	level_coins.add_theme_font_size_override("font_size", 16)
	level_coins.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	level_actions.add_child(level_coins)
	var coin := TextureRect.new()
	coin.texture = DentiUIIcons.hud(2)
	coin.custom_minimum_size = Vector2(24, 24)
	coin.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	coin.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	level_actions.add_child(coin)
	var spacer := Control.new()
	spacer.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	level_actions.add_child(spacer)
	reroll_button = Button.new()
	MenuStyle.action(reroll_button)
	reroll_button.icon = preload("res://assets/ui/reload_light.svg")
	reroll_button.add_theme_constant_override("icon_max_width", 20)
	reroll_button.custom_minimum_size = Vector2(96, 48)
	level_actions.add_child(reroll_button)
	reroll_button.pressed.connect(func() -> void: level_reroll_requested.emit())
	starter_selection = StarterSelection.new()
	$Root.add_child(starter_selection)
	starter_selection.hide()
	starter_selection.chosen.connect(func(weapon: WeaponData) -> void:
		visible = false
		starter_chosen.emit(weapon))
	starter_selection.selection_changed.connect(func() -> void: starter_preview_changed.emit())
	_use_legacy(&"upgrade")
	get_viewport().size_changed.connect(_update_layout)

func _use_rewards(next: StringName) -> void:
	mode = next
	$Root/Center.hide()
	starter_selection.hide()
	buttons = reward_view.buttons
	cards = reward_view.cards
	dialog_panel = stage.panel
	title_label = stage.title_label
	subtitle_label = stage.progress_label
	reward_view.kind = mode
	for index in buttons.size():
		var button := buttons[index]
		if button.get_parent() != cards: button.reparent(cards)
		cards.move_child(button, index)
		button.hide()
	level_actions.visible = mode == &"upgrade"
	stage.show()
	stage.body_scroll.scroll_vertical = 0

func _use_legacy(next: StringName) -> void:
	mode = next
	stage.hide()
	level_actions.hide()
	starter_selection.visible = mode == &"starter"
	$Root/Center.visible = mode != &"starter"
	buttons = legacy_buttons
	cards = legacy_cards
	dialog_panel = legacy_panel
	title_label = legacy_title
	subtitle_label = legacy_subtitle

func _update_layout() -> void:
	if mode in [&"upgrade", &"chest", &"relic"] and stage.visible:
		stage.relayout()
		stage.refresh_focus()
		return
	if mode == &"starter": return
	var extent: Vector2 = $Root.size
	var compact := extent.x < 600 or extent.y < 600
	legacy_panel.custom_minimum_size = Vector2(minf(extent.x - 24, 900), 0)
	var portrait := $Root/Center/Panel/Margin/Rows/Portrait
	portrait.visible = extent.y >= 600
	portrait.custom_minimum_size.y = 64
	title_label.add_theme_font_size_override("font_size", 22 if compact else 30)
	subtitle_label.visible = true
	subtitle_label.custom_minimum_size.y = 0
	subtitle_label.add_theme_font_size_override("font_size", 14 if compact else 17)
	for edge in ["left", "right", "top", "bottom"]:
		$Root/Center/Panel/Margin.add_theme_constant_override("margin_" + edge, 8 if compact else 14)
	cards.columns = 2 if mode == &"end" else 1
	cards.add_theme_constant_override("h_separation", 8 if compact else 12)
	cards.add_theme_constant_override("v_separation", 8 if compact else 12)
	if mode == &"end":
		subtitle_label.text = _end_summary(end_won, end_coins, end_recap)
		var labels := ["Neuer Run", "Credits", "Hauptmenü", "Endlos"] if compact else ["Noch einmal spielen", "Credits", "Hauptmenü", "Endlos weiterspielen"]
		for index in buttons.size():
			buttons[index].custom_minimum_size = Vector2(0, 40 if compact else 48)
			buttons[index].add_theme_font_size_override("font_size", 14 if compact else 18)
			buttons[index].text = labels[index]

func set_progress(current: int, total: int) -> void:
	stage.set_progress(current, total)

func update_level_reroll(coins: int, cost: int, earned_level: int = 0) -> void:
	level_coins.text = ("Level %d · " % earned_level if earned_level > 0 else "") + str(coins)
	reroll_button.text = str(cost)
	reroll_button.disabled = coins < cost
	reroll_button.tooltip_text = "Neu würfeln · %d Münzen" % cost

func show_upgrades(options: Array[UpgradeData]) -> void:
	_use_rewards(&"upgrade")
	current_upgrades = options
	title_label.text = "Aufstieg"
	for index in buttons.size():
		buttons[index].visible = index < options.size()
		if index < options.size(): buttons[index].show_upgrade(options[index])
	_finish_reward()

func show_starters(options: Array[WeaponData], selected_id: StringName = &"") -> void:
	_use_legacy(&"starter")
	starter_options = options
	for button in buttons: button.hide()
	starter_selection.show_options(options, selected_id)
	visible = true

func show_chest(item: ShopOfferData, scrap_coins: int) -> void:
	_use_rewards(&"chest")
	chest_item = item
	title_label.text = "Fund"
	buttons[0].show_item(item)
	buttons[0].show()
	buttons[1].show_action("Zerlegen · %d Münzen" % scrap_coins)
	MenuStyle.action(buttons[1], false, true)
	buttons[1].reparent(stage.footer)
	buttons[1].show()
	_finish_reward()

func show_relics(options: Array[RelicData]) -> void:
	_use_rewards(&"relic")
	relic_options = options
	title_label.text = "Relikt"
	for index in buttons.size():
		buttons[index].visible = index < options.size()
		if index < options.size(): buttons[index].show_relic(options[index])
	_finish_reward()

func _finish_reward() -> void:
	visible = true
	_update_layout()
	if not buttons.is_empty() and buttons[0].visible: buttons[0].grab_focus()
	DentiUIMotion.reveal(reward_view)

func show_end(won: bool, coins: int, recap: Dictionary = {}) -> void:
	_use_legacy(&"end")
	end_won = won
	end_coins = coins
	end_recap = recap.duplicate(true)
	current_upgrades.clear()
	title_label.text = "Endlos beendet!" if not won and bool(recap.get("endless_enabled", false)) else ("Alle huldigen Denti!" if won else "Denti ist ausgefallen!")
	buttons[0].show_action("Noch einmal spielen", true)
	buttons[1].show_action("Credits")
	buttons[2].show_action("Hauptmenü")
	buttons[3].show_action("Endlos weiterspielen", true)
	for index in 3: buttons[index].show()
	buttons[3].visible = won and not bool(recap.get("endless_enabled", false)) and int(recap.get("wave_reached", 0)) == WaveController.MAX_WAVES
	buttons[3].tooltip_text = "Mit diesem Build in Welle 21 weiterspielen. Dein Sieg bleibt erhalten."
	_update_layout()
	visible = true
	buttons[0].grab_focus()

func _on_choice_pressed(index: int) -> void:
	match mode:
		&"starter": starter_selection.select_weapon(index)
		&"upgrade":
			if index >= current_upgrades.size(): return
			visible = false
			upgrade_chosen.emit(current_upgrades[index])
		&"chest":
			if index > 1: return
			visible = false
			chest_resolved.emit(index == 0)
		&"relic":
			if index >= relic_options.size(): return
			visible = false
			relic_chosen.emit(relic_options[index].id)
		&"end":
			if index == 0:
				visible = false
				restart_requested.emit()
			elif index == 1: _show_credits()
			elif index == 2: main_menu_requested.emit()
			elif index == 3 and buttons[3].visible: endless_requested.emit()
		&"credits": show_end(end_won, end_coins, end_recap)


func _end_summary(won: bool, coins: int, recap: Dictionary) -> String:
	var run: Dictionary = recap.get("telemetry", {})
	if run.is_empty():
		return "Run beendet · %d Münzen übrig" % coins
	var elapsed := maxi(roundi(float(run.get("elapsed", 0.0))), 0)
	var minutes := floori(float(elapsed) / 60.0)
	var seconds := elapsed % 60
	var outcome := "Sieg" if won or bool(recap.get("base_victory", false)) else "Niederlage"
	var compact: bool = $Root.size.x < 600.0 or $Root.size.y < 600.0
	if compact:
		return "%s · %s\nWelle %d · Level %d · %02d:%02d\n%d Kills · %d Münzen übrig%s" % [outcome, DifficultyCatalog.by_id(StringName(str(recap.get("difficulty_id", "normal")))).display_name, int(recap.get("wave_reached", 0)), int(recap.get("final_level", 1)), minutes, seconds, int(run.get("kills", 0)), coins, "\nSieg in Welle 20 bleibt erhalten." if bool(recap.get("endless_enabled", false)) else ""]
	var lines: PackedStringArray = [
		"%s auf %s · Welle %d · Level %d · %02d:%02d Minuten" % [outcome, DifficultyCatalog.by_id(StringName(str(recap.get("difficulty_id", "normal")))).display_name, int(recap.get("wave_reached", 0)), int(recap.get("final_level", 1)), minutes, seconds],
		"%s Gegner besiegt · %s Bosse · %s Gesamtschaden" % [
			_format_number(int(run.get("kills", 0))), _format_number(int(run.get("bosses_defeated", 0))), _format_number(roundi(float(run.get("total_damage", 0.0))))],
		"%s Schaden erlitten · %s XP · %s Münzen gesammelt (%s übrig)" % [
			_format_number(roundi(float(run.get("damage_taken", 0.0)))), _format_number(int(run.get("xp_collected", 0))),
			_format_number(int(run.get("coins_collected", 0))), _format_number(coins)],
		"Upgrade-Kapseln: %d gefunden · %d behalten · %d zerlegt" % [
			int(run.get("chests_found", 0)), int(run.get("chests_kept", 0)), int(run.get("chests_scrapped", 0))],
	]
	if bool(recap.get("hell_unlocked_now", false)):
		lines.append("Hell freigeschaltet!")
	var weapon_damage: Dictionary = run.get("weapon_damage", {})
	var weapon_total := 0.0
	for amount in weapon_damage.values():
		weapon_total += float(amount)
	var weapon_ids: Array = weapon_damage.keys()
	weapon_ids.sort_custom(func(a: Variant, b: Variant) -> bool: return float(weapon_damage[a]) > float(weapon_damage[b]))
	if not weapon_ids.is_empty():
		lines.append("Waffenschaden")
		for id in weapon_ids.slice(0, mini(3, weapon_ids.size())):
			var weapon := WeaponCatalog.by_id(StringName(str(id)))
			var weapon_name := weapon.display_name if weapon != null else str(id).replace("_", " ").capitalize()
			var amount := float(weapon_damage[id])
			var share := roundi(amount * 100.0 / maxf(weapon_total, 1.0))
			lines.append("%s · %s Schaden · %d%%" % [weapon_name, _format_number(roundi(amount)), share])
	var proc_damage: Dictionary = run.get("proc_damage", {})
	var proc_ids: Array = proc_damage.keys()
	proc_ids.sort_custom(func(a: Variant, b: Variant) -> bool: return float(proc_damage[a]) > float(proc_damage[b]))
	if not proc_ids.is_empty():
		var proc_lines := PackedStringArray()
		for id in proc_ids.slice(0, mini(2, proc_ids.size())):
			proc_lines.append("%s %s" % [_proc_name(StringName(str(id))), _format_number(roundi(float(proc_damage[id])))])
		lines.append("Synergien · " + " · ".join(proc_lines))
	return "\n".join(lines)


func _proc_name(id: StringName) -> String:
	var labels := {
		"affix_fire": "Feuer", "affix_ice": "Eis", "affix_poison": "Gift", "affix_bleed": "Blutungsverzauberung", "affix_electric": "Elektro",
		"affix_electric_chain": "Elektro-Kette", "affix_ice_shatter": "Eissplitter", "affix_holy": "Lichtstoß",
		"bleed": "Blutung", "chain": "Kettenblitz", "water_puddle": "Spülpfützen",
		"splash": "Spritzer", "crit_burst": "Krit-Blitz", "crit_beam": "Glanzstrahl",
		"thorns": "Keramiksplitter", "shield_shards": "Schildsplitter", "kill_burst": "Zahnblitz",
		"blood_moon_tooth": "Blutmond", "tidal_seal": "Gezeitenwelle", "sun_mark": "Sonnenmal",
		"pilgrim_compass": "Kompasssprung",
	}
	return str(labels.get(str(id), str(id).replace("_", " ").capitalize()))


func _format_number(value: int) -> String:
	var digits := str(absi(value))
	var grouped := ""
	for index in digits.length():
		if index > 0 and (digits.length() - index) % 3 == 0:
			grouped += "."
		grouped += digits.substr(index, 1)
	return "-" + grouped if value < 0 else grouped


func _show_credits() -> void:
	mode = &"credits"
	dialog_panel.custom_minimum_size = Vector2(800, 420)
	_update_layout()
	title_label.text = "Credits"
	subtitle_label.text = "Schrift: Fredoka · The Fredoka Project Authors\nSIL Open Font License 1.1\n\nDenti-, Waffen-, Gegner-, Arena- und Icon-Grafiken: OpenAI ImageGen\nMusik: othaldo · erstellt mit Suno\nSoundeffekte: eigens synthetisiert\nUI-Elemente: eigenes Godot-Design"
	subtitle_label.custom_minimum_size.y = 120.0
	buttons[0].show_action("Zurück", true)
	buttons[1].visible = false
	buttons[2].visible = false
	buttons[3].visible = false
	buttons[0].grab_focus()
