class_name ChoicePanel
extends CanvasLayer

signal upgrade_chosen(upgrade: UpgradeData)
signal restart_requested
signal main_menu_requested

@onready var title_label: Label = $Root/Center/Panel/Margin/Rows/Title
@onready var subtitle_label: Label = $Root/Center/Panel/Margin/Rows/Subtitle
@onready var dialog_panel: PanelContainer = $Root/Center/Panel
@onready var buttons: Array[Button] = [
	$Root/Center/Panel/Margin/Rows/Cards/Choice1,
	$Root/Center/Panel/Margin/Rows/Cards/Choice2,
	$Root/Center/Panel/Margin/Rows/Cards/Choice3,
]

var current_upgrades: Array[UpgradeData] = []
var mode: StringName = &"upgrade"
var end_won: bool = false
var end_coins: int = 0


func _ready() -> void:
	visible = false
	$Root.theme = DentiUIStyle.make_theme()
	$Root/Dim.color = Color(0.12, 0.06, 0.13, 0.78)
	DentiUIStyle.style_dialog(dialog_panel)
	title_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	title_label.add_theme_font_size_override("font_size", 32)
	subtitle_label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	for index in buttons.size():
		buttons[index].pressed.connect(_on_choice_pressed.bind(index))


func show_upgrades(options: Array[UpgradeData]) -> void:
	mode = &"upgrade"
	current_upgrades = options
	dialog_panel.custom_minimum_size = Vector2(900, 440)
	title_label.text = "Denti steigt auf!"
	subtitle_label.text = "Ein göttlicher Segen wurde gewährt. Wähle einen für Denti."
	subtitle_label.custom_minimum_size.y = 40.0
	for index in buttons.size():
		buttons[index].visible = true
		buttons[index].call("show_upgrade", options[index])
	visible = true
	buttons[0].grab_focus()


func show_end(won: bool, coins: int) -> void:
	mode = &"end"
	end_won = won
	end_coins = coins
	current_upgrades.clear()
	dialog_panel.custom_minimum_size = Vector2(800, 330)
	title_label.text = "Alle huldigen Denti!" if won else "Denti ist ausgefallen!"
	subtitle_label.text = "Gesammelte Münzen: %d" % coins
	subtitle_label.custom_minimum_size.y = 45.0
	buttons[0].call("show_action", "Noch einmal spielen", true)
	buttons[0].visible = true
	buttons[1].call("show_action", "Credits")
	buttons[1].visible = true
	buttons[2].call("show_action", "Hauptmenü")
	buttons[2].visible = true
	visible = true
	buttons[0].grab_focus()


func _on_choice_pressed(index: int) -> void:
	match mode:
		&"upgrade":
			visible = false
			upgrade_chosen.emit(current_upgrades[index])
		&"end":
			if index == 0:
				visible = false
				restart_requested.emit()
			elif index == 1:
				_show_credits()
			elif index == 2:
				main_menu_requested.emit()
		&"credits":
			show_end(end_won, end_coins)


func _show_credits() -> void:
	mode = &"credits"
	dialog_panel.custom_minimum_size = Vector2(800, 420)
	title_label.text = "Credits"
	subtitle_label.text = "Schrift: Fredoka · The Fredoka Project Authors\nSIL Open Font License 1.1\n\nDenti-, Gegner-, Arena- und Icon-Grafiken: OpenAI ImageGen\nMusik: othaldo · erstellt mit Suno\nSoundeffekte: eigens synthetisiert\nUI-Elemente: eigenes Godot-Design"
	subtitle_label.custom_minimum_size.y = 120.0
	buttons[0].call("show_action", "Zurück", true)
	buttons[1].visible = false
	buttons[2].visible = false
	buttons[0].grab_focus()
