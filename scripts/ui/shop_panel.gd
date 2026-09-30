class_name ShopPanel
extends CanvasLayer

const ICONS: Script = preload("res://scripts/ui/denti_ui_icons.gd")

signal buy_requested(index: int)
signal sell_requested(index: int)
signal merge_requested(index: int)
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
var items_scroll: ScrollContainer
var items_row: HBoxContainer
var armed_sell_index: int = -1


func _ready() -> void:
	visible = false
	$Root.theme = DentiUIStyle.make_theme()
	rows.add_theme_constant_override("separation", 5)
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


func show_shop(wave_number: int, coins: int, reroll_cost: int, offers: Array[ShopOfferData], preview: String = "", equipment: Array[Dictionary] = [], used_slots: int = 0, capacity: int = 6, buyable: Array[bool] = [], luck: float = 0.0, owned_items: Array[Dictionary] = [], counts: Dictionary = {}, offer_dps: Array[float] = []) -> void:
	var first_open := not visible
	armed_sell_index = -1
	title_label.text = "Zahnklinik · Nach Welle %d" % wave_number
	coins_label.text = "%d Münzen · %d Glück" % [coins, roundi(luck)]
	$Root/Center/Panel/Margin/Rows/Wallet.tooltip_text = "Glück erhöht die Chance auf seltene Angebote und Levelaufstiege."
	preview_label.text = preview
	for index in offer_buttons.size():
		var button := offer_buttons[index]
		var owned_count := int(counts.get(str(offers[index].id), 0)) if offers[index] != null and offers[index].weapon_data == null else 0
		button.call("show_offer", offers[index], coins, buyable.is_empty() or buyable[index], owned_count, offer_dps[index] if index < offer_dps.size() else 0.0)
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
	items_scroll = ScrollContainer.new()
	items_scroll.custom_minimum_size.y = 46.0
	items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	items_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	rows.add_child(items_scroll)
	rows.move_child(items_scroll, $Root/Center/Panel/Margin/Rows/Actions.get_index())
	items_row = HBoxContainer.new()
	items_row.add_theme_constant_override("separation", 5)
	items_scroll.add_child(items_row)
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
	var total := 0
	for child in items_row.get_children():
		items_row.remove_child(child)
		child.queue_free()
	for entry in equipment:
		var copies := int(entry["count"])
		total += copies
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(47, 43)
		chip.tooltip_text = "%s ×%d\n%s" % [entry["name"], copies, entry["description"]]
		DentiUIStyle.style_chip(chip, Color(0.91, 0.84, 0.97) if bool(entry.get("relic", false)) else Color(0.96, 0.91, 0.78))
		items_row.add_child(chip)
		var holder := Control.new()
		holder.custom_minimum_size = Vector2(34, 34)
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(holder)
		var icon := TextureRect.new()
		icon.texture = entry["icon"]
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(icon)
		if copies > 1:
			var count_label := Label.new()
			count_label.text = "×%d" % copies
			count_label.add_theme_color_override("font_color", DentiUIStyle.INK)
			count_label.add_theme_font_size_override("font_size", 12)
			count_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
			holder.add_child(count_label)
			count_label.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	items_label.text = "Items & Relikte · %d" % total if total > 0 else "Items & Relikte · noch keine"
	items_scroll.visible = total > 0


func _show_inventory(equipment: Array[Dictionary], used_slots: int, capacity: int) -> void:
	inventory_label.text = "Ausrüstung · %d/%d Plätze · Gleiche Waffen verschmelzen" % [used_slots, capacity]
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
		var slot := HBoxContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.add_theme_constant_override("separation", 2)
		inventory_row.add_child(slot)
		var button := Button.new()
		button.custom_minimum_size = Vector2(72, 54)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.clip_text = true
		button.add_theme_font_size_override("font_size", 13)
		button.text = "%s Mk %s\nVerkaufen +%d" % [entry["name"], ["I", "II", "III", "IV"][int(entry["tier"]) - 1], entry["refund"]]
		button.tooltip_text = "%s\n%s\n%s\n≈ %.1f DPS pro Ziel\n2× klicken: verkaufen%s" % [entry["description"], entry["combat"], entry["stats"], entry["dps"], "\nVerschmelzen mit gleicher Waffe" if entry["mergeable"] else ""]
		DentiUIStyle.style_button(button)
		button.pressed.connect(_on_inventory_pressed.bind(index, button))
		button.gui_input.connect(_on_inventory_input.bind(index))
		slot.add_child(button)
		if entry["mergeable"]:
			var merge_button := Button.new()
			merge_button.text = "Fusion"
			merge_button.tooltip_text = "Mit gleicher Waffe verschmelzen"
			merge_button.custom_minimum_size = Vector2(48, 54)
			merge_button.add_theme_font_size_override("font_size", 12)
			DentiUIStyle.style_button(merge_button)
			merge_button.pressed.connect(func() -> void: merge_requested.emit(index))
			slot.add_child(merge_button)


func _on_inventory_pressed(index: int, button: Button) -> void:
	if armed_sell_index == index:
		sell_requested.emit(index)
	else:
		armed_sell_index = index
		button.text = "Erneut klicken\nzum Verkaufen"


func _on_inventory_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		merge_requested.emit(index)
		get_viewport().set_input_as_handled()
