class_name CollectedItems
extends HBoxContainer

signal selected(index: int)


func show_entries(entries: Array[Dictionary]) -> Vector2i:
	for child in get_children():
		remove_child(child)
		child.queue_free()
	var total := 0
	var relic_count := 0
	for index in entries.size():
		var entry := entries[index]
		var copies := int(entry.count)
		if bool(entry.get("relic", false)):
			relic_count += copies
		else:
			total += copies
		var chip := PanelContainer.new()
		chip.custom_minimum_size = Vector2(48, 44)
		chip.focus_mode = Control.FOCUS_ALL
		chip.tooltip_text = "%s ×%d\n%s" % [entry.name, copies, entry.description]
		var tier := int(entry.get("tier", 4 if bool(entry.get("relic", false)) else 1))
		chip.tooltip_text += "\nSeltenheit: " + DentiRarity.name_for(tier)
		DentiUIStyle.style_rarity_panel(chip, tier)
		var chip_style := chip.get_theme_stylebox("panel")
		chip_style.content_margin_left = 6
		chip_style.content_margin_right = 6
		chip_style.content_margin_top = 3
		chip_style.content_margin_bottom = 3
		add_child(chip)
		chip.gui_input.connect(_on_input.bind(index))
		var holder := Control.new()
		holder.name = "Icon"
		holder.custom_minimum_size = Vector2(36, 36)
		holder.size_flags_vertical = Control.SIZE_SHRINK_CENTER
		holder.mouse_filter = Control.MOUSE_FILTER_IGNORE
		chip.add_child(holder)
		var icon := TextureRect.new()
		icon.name = "Texture"
		icon.texture = entry.icon
		icon.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
		icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(icon)
		var count := Label.new()
		count.name = "StackCount"
		count.text = "×%d" % copies
		count.add_theme_color_override("font_color", DentiUIStyle.INK)
		count.add_theme_color_override("font_outline_color", DentiUIStyle.PANEL)
		count.add_theme_constant_override("outline_size", 4)
		count.add_theme_font_size_override("font_size", 14)
		count.mouse_filter = Control.MOUSE_FILTER_IGNORE
		holder.add_child(count)
		count.set_anchors_and_offsets_preset(Control.PRESET_BOTTOM_RIGHT)
	return Vector2i(total, relic_count)


func highlight(selected_index: int) -> void:
	for index in get_child_count():
		DentiUIStyle.mark_card(get_child(index), DentiUIStyle.INK if selected_index == index else Color.TRANSPARENT)


func _on_input(event: InputEvent, index: int) -> void:
	if (event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed) or (event is InputEventScreenTouch and event.pressed) or event.is_action_pressed("ui_accept"):
		selected.emit(index)
		get_viewport().set_input_as_handled()
