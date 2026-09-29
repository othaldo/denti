class_name ShopPanel
extends CanvasLayer

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")

signal buy_requested(index: int)
signal sell_requested(index: int)
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
@onready var rows: VBoxContainer = $Root/Center/Panel/Margin/Rows

var inventory_label: Label
var inventory_row: HBoxContainer
var items_label: Label
var armed_sell_index: int = -1


func _ready() -> void:
	visible = false
	$Root.theme = DentiUIStyle.make_theme()
	rows.add_theme_constant_override("separation", 6)
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
	$Root/Center/Panel/Margin/Rows/Portrait.custom_minimum_size.y = 28.0
	$Root/Center/Panel.custom_minimum_size.y = 665.0
	for button in offer_buttons:
		button.custom_minimum_size.y = 100.0
	_build_inventory()
	DentiUIStyle.style_button(reroll_button)
	DentiUIStyle.style_button(continue_button, true)
	reroll_button.pressed.connect(func() -> void: reroll_requested.emit())
	continue_button.pressed.connect(func() -> void: continue_requested.emit())


func show_shop(wave_number: int, coins: int, reroll_cost: int, offers: Array[ShopOfferData], preview: String = "", equipment: Array[Dictionary] = [], used_slots: int = 0, capacity: int = 6, buyable: Array[bool] = [], luck: float = 0.0, owned_items: Array[Dictionary] = [], counts: Dictionary = {}) -> void:
	var first_open := not visible
	armed_sell_index = -1
	title_label.text = "Zahnklinik · Nach Welle %d" % wave_number
	coins_label.text = "%d Münzen · %d Glück" % [coins, roundi(luck)]
	$Root/Center/Panel/Margin/Rows/Wallet.tooltip_text = "Glück erhöht die Chance auf seltene Angebote und Levelaufstiege."
	preview_label.text = preview
	for index in offer_buttons.size():
		var button := offer_buttons[index]
		var owned_count := int(counts.get(str(offers[index].id), 0)) if offers[index] != null and offers[index].weapon_data == null else 0
		button.call("show_offer", offers[index], coins, buyable.is_empty() or buyable[index], owned_count)
	_show_items(owned_items)
	_show_inventory(equipment, used_slots, capacity)
	reroll_button.text = "Neu würfeln · %d Münzen" % reroll_cost
	reroll_button.disabled = coins < reroll_cost
	continue_button.text = "Welle %d starten" % (wave_number + 1)
	continue_button.disabled = equipment.is_empty()
	visible = true
	if first_open:
		continue_button.grab_focus()


func _on_offer_pressed(index: int) -> void:
	buy_requested.emit(index)


func _build_inventory() -> void:
	items_label = Label.new()
	items_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	items_label.add_theme_font_size_override("font_size", 15)
	items_label.clip_text = true
	rows.add_child(items_label)
	rows.move_child(items_label, $Root/Center/Panel/Margin/Rows/Actions.get_index())
	inventory_label = Label.new()
	inventory_label.add_theme_color_override("font_color", DentiUIStyle.INK)
	inventory_label.add_theme_font_size_override("font_size", 17)
	rows.add_child(inventory_label)
	rows.move_child(inventory_label, $Root/Center/Panel/Margin/Rows/Actions.get_index())
	inventory_row = HBoxContainer.new()
	inventory_row.add_theme_constant_override("separation", 6)
	rows.add_child(inventory_row)
	rows.move_child(inventory_row, $Root/Center/Panel/Margin/Rows/Actions.get_index())


func _show_items(equipment: Array[Dictionary]) -> void:
	var names: Array[String] = []
	var details: Array[String] = []
	var total := 0
	for entry in equipment:
		var copies := int(entry["count"])
		total += copies
		names.append("%s ×%d" % [entry["name"], copies])
		details.append("%s ×%d — %s" % [entry["name"], copies, entry["description"]])
	items_label.text = "Items %d · %s" % [total, ", ".join(names.slice(0, 3)) + (" · +%d weitere" % (names.size() - 3) if names.size() > 3 else "") if not names.is_empty() else "noch keine"]
	items_label.tooltip_text = "\n".join(details)


func _show_inventory(equipment: Array[Dictionary], used_slots: int, capacity: int) -> void:
	inventory_label.text = "Ausrüstung · %d/%d Plätze · 2 gleiche Stufen verschmelzen automatisch" % [used_slots, capacity]
	for child in inventory_row.get_children():
		inventory_row.remove_child(child)
		child.queue_free()
	if equipment.is_empty():
		var empty := Label.new()
		empty.text = "Noch keine Waffe"
		empty.add_theme_color_override("font_color", DentiUIStyle.MUTED)
		inventory_row.add_child(empty)
		return
	for index in equipment.size():
		var entry := equipment[index]
		var button := Button.new()
		button.custom_minimum_size = Vector2(112, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 13)
		button.text = "%s Mk %s\nVerkaufen +%d" % [entry["name"], ["I", "II", "III", "IV"][int(entry["tier"]) - 1], entry["refund"]]
		button.tooltip_text = "%s\nZum Verkaufen zweimal klicken" % str(entry.get("stats", ""))
		DentiUIStyle.style_button(button)
		button.pressed.connect(_on_inventory_pressed.bind(index, button))
		inventory_row.add_child(button)


func _on_inventory_pressed(index: int, button: Button) -> void:
	if armed_sell_index == index:
		sell_requested.emit(index)
	else:
		armed_sell_index = index
		button.text = "Erneut klicken\nzum Verkaufen"
