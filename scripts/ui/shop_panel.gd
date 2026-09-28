class_name ShopPanel
extends CanvasLayer

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")

signal buy_requested(index: int)
signal reroll_requested
signal continue_requested

@onready var title_label: Label = $Root/Center/Panel/Margin/Rows/Title
@onready var coins_label: Label = $Root/Center/Panel/Margin/Rows/Wallet/WalletRow/Coins
@onready var preview_label: Label = $Root/Center/Panel/Margin/Rows/Preview
@onready var offer_buttons: Array[Button] = [
	$Root/Center/Panel/Margin/Rows/Offer1,
	$Root/Center/Panel/Margin/Rows/Offer2,
	$Root/Center/Panel/Margin/Rows/Offer3,
]
@onready var reroll_button: Button = $Root/Center/Panel/Margin/Rows/Actions/Reroll
@onready var continue_button: Button = $Root/Center/Panel/Margin/Rows/Actions/Continue


func _ready() -> void:
	visible = false
	$Root.theme = DentiUIStyle.make_theme()
	$Root/Dim.color = Color(0.12, 0.06, 0.13, 0.78)
	DentiUIStyle.style_dialog($Root/Center/Panel)
	title_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	title_label.add_theme_font_size_override("font_size", 31)
	coins_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	coins_label.add_theme_font_size_override("font_size", 19)
	preview_label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	preview_label.add_theme_font_size_override("font_size", 16)
	DentiUIStyle.style_chip($Root/Center/Panel/Margin/Rows/Wallet)
	$Root/Center/Panel/Margin/Rows/Wallet/WalletRow/CoinIcon.texture = ICONS.hud(2)
	for index in offer_buttons.size():
		offer_buttons[index].pressed.connect(_on_offer_pressed.bind(index))
	DentiUIStyle.style_button(reroll_button)
	DentiUIStyle.style_button(continue_button, true)
	reroll_button.pressed.connect(func() -> void: reroll_requested.emit())
	continue_button.pressed.connect(func() -> void: continue_requested.emit())


func show_shop(wave_number: int, coins: int, reroll_cost: int, offers: Array[ShopOfferData], preview: String = "") -> void:
	var first_open := not visible
	title_label.text = "Zahnklinik · Nach Welle %d" % wave_number
	coins_label.text = "%d Münzen" % coins
	preview_label.text = preview
	for index in offer_buttons.size():
		var button := offer_buttons[index]
		button.call("show_offer", offers[index], coins)
	reroll_button.text = "Neu würfeln · %d Münzen" % reroll_cost
	reroll_button.disabled = coins < reroll_cost
	continue_button.text = "Welle %d starten" % (wave_number + 1)
	visible = true
	if first_open:
		continue_button.grab_focus()


func _on_offer_pressed(index: int) -> void:
	buy_requested.emit(index)
