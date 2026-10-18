class_name EquipmentSlots
extends Control

signal selected(index: int)
signal merge_requested(index: int)
const UPGRADE_ICON: Texture2D = preload("res://assets/ui/upgrade_ready.svg")


func show_entries(entries: Array[Dictionary], player: Player, used_slots: int, capacity: int) -> void:
	_clear()
	for index in entries.size():
		var entry := entries[index]
		var slot := HBoxContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		slot.size_flags_stretch_ratio = float(entry.get("hands", 1))
		add_child(slot)
		var data: WeaponData = entry.get("data")
		var tier := WeaponPresentation.tier_text(data, int(entry.tier))
		var color := WeaponPresentation.tier_color(data, int(entry.tier))
		var button := DentiUIComponents.button(slot, "")
		DentiUIStyle.style_card(button, int(entry.tier), WeaponPresentation.special_color(data))
		button.set_meta("hands", int(entry.get("hands", 1)))
		var icon := TextureRect.new()
		icon.name = "WeaponIcon"
		icon.texture = entry.get("icon")
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(icon)
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.offset_left = 6
		icon.offset_top = 6
		icon.offset_right = -6
		icon.offset_bottom = -6
		var tier_label := Label.new()
		tier_label.name = "WeaponTier"
		tier_label.text = tier
		tier_label.add_theme_font_size_override("font_size", 12)
		tier_label.add_theme_color_override("font_color", DentiUIStyle.GOLD_INK if data != null and data.evolution_kind != &"" else DentiUIStyle.INK)
		var tier_badge := StyleBoxFlat.new()
		tier_badge.bg_color = color if data != null and data.evolution_kind != &"" else DentiUIStyle.PANEL.lerp(color, 0.16)
		tier_badge.border_color = color
		tier_badge.set_border_width_all(1)
		tier_badge.set_corner_radius_all(4)
		tier_badge.content_margin_left = 3
		tier_badge.content_margin_right = 3
		tier_label.add_theme_stylebox_override("normal", tier_badge)
		tier_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		tier_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
		tier_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
		button.add_child(tier_label)
		tier_label.set_anchors_preset(Control.PRESET_BOTTOM_RIGHT)
		tier_label.offset_left = -51
		tier_label.offset_top = -27
		tier_label.offset_right = -5
		tier_label.offset_bottom = -3
		button.tooltip_text = "%s · %s\n%s\n%s\n%s\nca. %.1f DPS pro Ziel\nAntippen: Details, verkaufen oder fusionieren" % [entry.name, tier, entry.description, entry.combat, entry.stats, entry.dps]
		button.tooltip_text += "\n" + ("Spezialwaffe" if data != null and data.evolution_kind != &"" else "Seltenheit: " + DentiRarity.name_for(int(entry.tier)))
		var evolution_ready := player != null and not player.loadout.ready_evolutions(index, player.items).is_empty()
		if bool(entry.get("mergeable", false)) or evolution_ready:
			var indicator := PanelContainer.new()
			indicator.name = "UpgradeReady"
			indicator.custom_minimum_size = Vector2(28, 28)
			var badge := DentiUIStyle._box(DentiUIStyle.MINT, DentiUIStyle.MINT, 7, 0)
			badge.content_margin_left = 4
			badge.content_margin_right = 4
			badge.content_margin_top = 4
			badge.content_margin_bottom = 4
			indicator.add_theme_stylebox_override("panel", badge)
			indicator.mouse_filter = Control.MOUSE_FILTER_IGNORE
			button.add_child(indicator)
			indicator.position = Vector2(5, 3)
			var arrow := TextureRect.new()
			arrow.texture = UPGRADE_ICON
			arrow.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
			arrow.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
			arrow.mouse_filter = Control.MOUSE_FILTER_IGNORE
			indicator.add_child(arrow)
			button.tooltip_text += "\n" + ("Waffen-Evolution möglich" if evolution_ready else "Fusion zur nächsten Stufe möglich")
		button.pressed.connect(func() -> void: selected.emit(index))
		button.gui_input.connect(_on_input.bind(index))
	for index in maxi(capacity - used_slots, 0):
		var slot := HBoxContainer.new()
		slot.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		add_child(slot)
		var empty := DentiUIComponents.button(slot, "Freie\nWurzel")
		empty.disabled = true
		empty.add_theme_font_size_override("font_size", 12)
		empty.tooltip_text = "Freie Wurzel"


func layout_slots(width: float, columns: int, slot_height: float) -> float:
	var gap := 5.0
	var unit := floorf((width - gap * (columns - 1)) / columns)
	var occupied: Array[bool] = []
	occupied.resize(WeaponLoadout.CAPACITY)
	occupied.fill(false)
	for slot in get_children():
		var button: Button = slot.get_child(0)
		var roots := int(button.get_meta("hands", 1))
		var position_index := 0
		while position_index < occupied.size():
			if position_index % columns + roots <= columns and not occupied[position_index] and (roots == 1 or not occupied[position_index + 1]):
				break
			position_index += 1
		for offset in roots:
			occupied[position_index + offset] = true
		slot.position = Vector2((position_index % columns) * (unit + gap), (position_index / columns) * (slot_height + gap))
		var desired := Vector2(unit * roots + gap * (roots - 1), slot_height)
		button.custom_minimum_size = desired
		slot.size = desired
	var height := ceili(float(WeaponLoadout.CAPACITY) / columns) * (slot_height + gap) - gap
	custom_minimum_size = Vector2(0, height)
	return height + 4


func highlight(entries: Array[Dictionary], selected_index: int) -> void:
	for index in entries.size():
		var button: Button = get_child(index).get_child(0)
		var partner := false
		if selected_index >= 0 and selected_index < entries.size():
			var a: WeaponData = entries[selected_index].get("data")
			var b: WeaponData = entries[index].get("data")
			partner = a != null and b != null and a.id == b.id and entries[index].tier == entries[selected_index].tier and int(entries[index].tier) < 4
		DentiUIStyle.style_card(button, int(entries[index].tier), WeaponPresentation.special_color(entries[index].get("data")))
		var active := selected_index == index
		DentiUIStyle.mark_card(button, DentiUIStyle.INK if active else (DentiUIStyle.MINT if partner else Color.TRANSPARENT))


func _on_input(event: InputEvent, index: int) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_RIGHT and event.pressed:
		merge_requested.emit(index)
		get_viewport().set_input_as_handled()


func _clear() -> void:
	for child in get_children():
		remove_child(child)
		child.queue_free()
