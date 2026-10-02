class_name ChoicePanel
extends CanvasLayer

signal upgrade_chosen(upgrade: UpgradeData)
signal level_reroll_requested
signal chest_resolved(keep: bool)
signal relic_chosen(id: StringName)
signal starter_chosen(weapon: WeaponData)
signal restart_requested
signal main_menu_requested
signal endless_requested
const UPGRADE_COUNT := 4

@onready var title_label: Label = $Root/Center/Panel/Margin/Rows/Title
@onready var subtitle_label: Label = $Root/Center/Panel/Margin/Rows/Subtitle
@onready var dialog_panel: PanelContainer = $Root/Center/Panel
@onready var cards: GridContainer = $Root/Center/Panel/Margin/Rows/Cards
@onready var level_actions: HBoxContainer = $Root/Center/Panel/Margin/Rows/LevelActions
@onready var level_coins: Label = $Root/Center/Panel/Margin/Rows/LevelActions/Coins
@onready var reroll_button: Button = $Root/Center/Panel/Margin/Rows/LevelActions/Reroll
@onready var buttons: Array[Button] = [
	$Root/Center/Panel/Margin/Rows/Cards/Choice1,
	$Root/Center/Panel/Margin/Rows/Cards/Choice2,
	$Root/Center/Panel/Margin/Rows/Cards/Choice3,
	$Root/Center/Panel/Margin/Rows/Cards/Choice4,
]

var current_upgrades: Array[UpgradeData] = []
var starter_options: Array[WeaponData] = []
var mode: StringName = &"upgrade"
var end_won: bool = false
var end_coins: int = 0
var chest_item: ShopOfferData
var relic_options: Array[RelicData] = []
var end_recap: Dictionary = {}


func _ready() -> void:
	visible = false
	$Root.theme = DentiUIStyle.make_theme()
	$Root/Dim.color = Color(0.12, 0.06, 0.13, 0.78)
	DentiUIStyle.style_dialog(dialog_panel)
	title_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	title_label.add_theme_font_size_override("font_size", 32)
	subtitle_label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	level_coins.add_theme_color_override("font_color", DentiUIStyle.INK)
	DentiUIStyle.style_button(reroll_button)
	reroll_button.icon = preload("res://assets/ui/reload_light.svg")
	reroll_button.add_theme_constant_override("icon_max_width", 18)
	reroll_button.pressed.connect(func() -> void: level_reroll_requested.emit())
	for index in buttons.size():
		buttons[index].pressed.connect(_on_choice_pressed.bind(index))
	get_viewport().size_changed.connect(_update_layout)
	_update_layout()


func _update_layout() -> void:
	var viewport_size: Vector2 = $Root.size
	var portrait := viewport_size.y > viewport_size.x and viewport_size.x < 800.0
	level_actions.visible = mode == &"upgrade"
	if mode == &"end":
		_layout_end(viewport_size)
		return
	if mode == &"upgrade":
		var narrow := viewport_size.x < 600.0 or viewport_size.y < 480.0
		reroll_button.custom_minimum_size = Vector2(80, 32 if narrow else 40)
		reroll_button.add_theme_font_size_override("font_size", 14 if narrow else 17)
		level_coins.add_theme_font_size_override("font_size", 14 if narrow else 17)
		cards.columns = 1 if portrait and viewport_size.y >= 1000.0 else (4 if (viewport_size.x >= 1150.0 and viewport_size.y >= 650.0) or viewport_size.y < 480.0 else 2)
		$Root/Center/Panel/Margin/Rows/Portrait.visible = viewport_size.y >= 480.0
		subtitle_label.visible = viewport_size.y >= 600.0
		dialog_panel.custom_minimum_size = Vector2(minf(viewport_size.x - 24.0, 1120.0), 0)
		$Root/Center/Panel/Margin/Rows/Portrait.custom_minimum_size.y = 48.0 if viewport_size.y >= 650.0 else 24.0
		title_label.add_theme_font_size_override("font_size", 24 if narrow else 30)
		subtitle_label.add_theme_font_size_override("font_size", 14 if narrow else 17)
		subtitle_label.custom_minimum_size.y = 32.0
		for edge in ["left", "right", "top", "bottom"]:
			$Root/Center/Panel/Margin.add_theme_constant_override("margin_" + edge, 8 if narrow else 14)
		cards.add_theme_constant_override("h_separation", 8 if narrow else 12)
		cards.add_theme_constant_override("v_separation", 8 if narrow else 12)
		for button in buttons:
			(button as UpgradeCard).set_upgrade_layout(narrow, cards.columns != 4 or narrow)
		return
	$Root/Center/Panel/Margin/Rows/Portrait.visible = true
	subtitle_label.visible = true
	$Root/Center/Panel/Margin/Rows/Portrait.custom_minimum_size.y = 80.0 if mode == &"end" else 108.0
	title_label.add_theme_font_size_override("font_size", 32)
	for edge in ["left", "right"]:
		$Root/Center/Panel/Margin.add_theme_constant_override("margin_" + edge, 28)
	$Root/Center/Panel/Margin.add_theme_constant_override("margin_top", 18)
	$Root/Center/Panel/Margin.add_theme_constant_override("margin_bottom", 24)
	cards.columns = 1 if portrait else 3
	var desktop_width := 760.0 if mode == &"chest" else (800.0 if mode == &"credits" else 900.0)
	dialog_panel.custom_minimum_size.x = 660.0 if portrait else desktop_width
	for button in buttons:
		(button as UpgradeCard).reset_card_layout()
		(button as UpgradeCard).set_mobile_text(portrait or viewport_size.y <= 620.0)
		if mode == &"starter":
			button.custom_minimum_size.y = 285.0 if portrait or viewport_size.y <= 620.0 else 250.0


func _layout_end(viewport_size: Vector2) -> void:
	var compact := viewport_size.x < 600.0 or viewport_size.y < 600.0
	dialog_panel.custom_minimum_size = Vector2(minf(viewport_size.x - 24.0, 900.0), 0)
	$Root/Center/Panel/Margin/Rows/Portrait.visible = viewport_size.y >= 600.0
	$Root/Center/Panel/Margin/Rows/Portrait.custom_minimum_size.y = 64.0
	title_label.add_theme_font_size_override("font_size", 22 if compact else 30)
	subtitle_label.visible = true
	subtitle_label.custom_minimum_size.y = 0
	subtitle_label.add_theme_font_size_override("font_size", 14 if compact else 17)
	subtitle_label.text = _end_summary(end_won, end_coins, end_recap)
	for edge in ["left", "right", "top", "bottom"]:
		$Root/Center/Panel/Margin.add_theme_constant_override("margin_" + edge, 8 if compact else 14)
	cards.columns = 2
	cards.add_theme_constant_override("h_separation", 8 if compact else 12)
	cards.add_theme_constant_override("v_separation", 8 if compact else 12)
	var labels := ["Neuer Run", "Credits", "Hauptmenü", "Endlos"] if compact else ["Noch einmal spielen", "Credits", "Hauptmenü", "Endlos weiterspielen"]
	for index in buttons.size():
		buttons[index].custom_minimum_size = Vector2(0, 40 if compact else 48)
		buttons[index].add_theme_font_size_override("font_size", 14 if compact else 18)
		buttons[index].text = labels[index]


func update_level_reroll(coins: int, cost: int, earned_level: int = 0) -> void:
	level_coins.text = ("Level %d · " % earned_level if earned_level > 0 else "") + "%d Münzen" % coins
	reroll_button.text = str(cost)
	reroll_button.disabled = coins < cost
	reroll_button.tooltip_text = "Level-up neu würfeln · %d Münzen\nVier neue Angebote für dieses Level. Nächster Reroll: +1 Münze." % cost


func show_upgrades(options: Array[UpgradeData]) -> void:
	mode = &"upgrade"
	current_upgrades = options
	dialog_panel.custom_minimum_size = Vector2(900, 440)
	_update_layout()
	title_label.text = "Denti steigt auf!"
	subtitle_label.text = "Wähle einen Bonus"
	subtitle_label.custom_minimum_size.y = 40.0
	for index in buttons.size():
		buttons[index].visible = index < options.size()
		if index < options.size():
			buttons[index].call("show_upgrade", options[index])
	_update_layout()
	visible = true
	buttons[0].grab_focus()


func show_starters(options: Array[WeaponData]) -> void:
	mode = &"starter"
	starter_options = options
	dialog_panel.custom_minimum_size = Vector2(900, 440)
	_update_layout()
	title_label.text = "Dentis erste Waffe"
	subtitle_label.text = "Wähle eine Waffe. Weitere findest du später in der Zahnklinik."
	subtitle_label.custom_minimum_size.y = 40.0
	for index in buttons.size():
		buttons[index].visible = index < options.size()
		if index < options.size():
			buttons[index].call("show_weapon", options[index])
	_update_layout()
	visible = true
	buttons[0].grab_focus()


func show_chest(item: ShopOfferData, scrap_coins: int) -> void:
	mode = &"chest"
	chest_item = item
	dialog_panel.custom_minimum_size = Vector2(760, 420)
	_update_layout()
	title_label.text = "Zahnfee-Kiste!"
	subtitle_label.text = item.limit_text()
	subtitle_label.custom_minimum_size.y = 40.0
	buttons[0].call("show_item", item)
	buttons[0].visible = true
	buttons[1].call("show_action", "Für %d Münzen zerlegen" % scrap_coins)
	buttons[1].visible = true
	buttons[2].visible = false
	buttons[3].visible = false
	visible = true
	buttons[0].grab_focus()


func show_relics(options: Array[RelicData]) -> void:
	mode = &"relic"
	relic_options = options
	dialog_panel.custom_minimum_size = Vector2(900, 465)
	_update_layout()
	title_label.text = "Göttliche Zahnreliquie!"
	subtitle_label.text = "Der Boss ist besiegt. Wähle ein Relikt für diesen Lauf."
	subtitle_label.custom_minimum_size.y = 40.0
	for index in buttons.size():
		buttons[index].visible = index < options.size()
		if index < options.size():
			buttons[index].call("show_relic", options[index])
	visible = true
	buttons[0].grab_focus()


func show_end(won: bool, coins: int, recap: Dictionary = {}) -> void:
	mode = &"end"
	end_won = won
	end_coins = coins
	end_recap = recap.duplicate(true)
	current_upgrades.clear()
	dialog_panel.custom_minimum_size = Vector2(900, 560)
	_update_layout()
	$Root/Center/Panel/Margin/Rows/Portrait.custom_minimum_size.y = 80.0
	title_label.text = "Endlos beendet!" if not won and bool(recap.get("endless_enabled", false)) else ("Alle huldigen Denti!" if won else "Denti ist ausgefallen!")
	subtitle_label.add_theme_font_size_override("font_size", 17)
	subtitle_label.text = _end_summary(won, coins, end_recap)
	subtitle_label.custom_minimum_size.y = 270.0
	buttons[0].call("show_action", "Noch einmal spielen", true)
	buttons[0].visible = true
	buttons[1].call("show_action", "Credits")
	buttons[1].visible = true
	buttons[2].call("show_action", "Hauptmenü")
	buttons[2].visible = true
	buttons[3].visible = won and not bool(recap.get("endless_enabled", false)) and int(recap.get("wave_reached", 0)) == WaveController.MAX_WAVES
	buttons[3].call("show_action", "Endlos weiterspielen", true)
	buttons[3].tooltip_text = "Mit diesem Build in Welle 21 weiterspielen. Dein Sieg bleibt erhalten."
	_update_layout()
	visible = true
	buttons[0].grab_focus()


func _on_choice_pressed(index: int) -> void:
	match mode:
		&"starter":
			visible = false
			starter_chosen.emit(starter_options[index])
		&"upgrade":
			if index >= current_upgrades.size():
				return
			visible = false
			upgrade_chosen.emit(current_upgrades[index])
		&"chest":
			if index > 1:
				return
			visible = false
			chest_resolved.emit(index == 0)
		&"relic":
			if index >= relic_options.size():
				return
			visible = false
			relic_chosen.emit(relic_options[index].id)
		&"end":
			if index == 0:
				visible = false
				restart_requested.emit()
			elif index == 1:
				_show_credits()
			elif index == 2:
				main_menu_requested.emit()
			elif index == 3 and buttons[3].visible:
				endless_requested.emit()
		&"credits":
			show_end(end_won, end_coins, end_recap)


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
		"Kisten: %d gefunden · %d behalten · %d zerlegt" % [
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
	buttons[0].call("show_action", "Zurück", true)
	buttons[1].visible = false
	buttons[2].visible = false
	buttons[3].visible = false
	buttons[0].grab_focus()
