class_name ShopLayout
extends RefCounted


static func build(view: ShopPanel) -> void:
	view.visible = false
	view.get_node("Root").theme = DentiUIStyle.make_theme()
	view.get_node("Root/Dim").color = DentiUIStyle.BACKGROUND
	DentiUIStyle.style_dialog(view.get_node("Root/Center/Panel"))
	for child in view.rows.get_children():
		view.rows.remove_child(child)
		child.queue_free()
	view.rows.add_theme_constant_override("separation", 12)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 12)
	view.rows.add_child(header)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	view.title_label = DentiUIComponents.label(titles, "Zahnklinik", 27)
	view.title_label.clip_text = true
	view.title_label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	var wallet_box := VBoxContainer.new()
	wallet_box.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	header.add_child(wallet_box)
	var coin_row := HBoxContainer.new()
	coin_row.alignment = BoxContainer.ALIGNMENT_END
	wallet_box.add_child(coin_row)
	view.coins_label = DentiUIComponents.label(coin_row, "", 18)
	var coin_icon := TextureRect.new()
	coin_icon.texture = DentiUIIcons.hud(2)
	coin_icon.custom_minimum_size = Vector2(24, 24)
	coin_icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	coin_icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	coin_row.add_child(coin_icon)
	view.luck_label = DentiUIComponents.label(wallet_box, "", 15)
	view.luck_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	view.luck_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	view.coins_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	view.coins_label.clip_text = true
	view.coins_label.custom_minimum_size.x = 40
	view.coins_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	view.story_timeline = StoryTimeline.new()
	view.rows.add_child(view.story_timeline)
	view.story_timeline.visible = false
	view.story_timeline.minimum_size_changed.connect(view._queue_layout)
	view.main_scroll = ScrollContainer.new()
	view.main_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	# This viewport owns the available area; child minima must not enlarge the shop.
	view.main_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_SHOW_NEVER
	view.rows.add_child(view.main_scroll)
	view.main_scroll.resized.connect(view._size_offer_grid)
	view.flow = BoxContainer.new()
	view.flow.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.flow.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.flow.add_theme_constant_override("separation", 10)
	view.main_scroll.add_child(view.flow)
	view.left_scroll = ScrollContainer.new()
	view.left_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.left_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.left_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	view.flow.add_child(view.left_scroll)
	var left := VBoxContainer.new()
	view.build_column = left
	left.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	left.add_theme_constant_override("separation", 6)
	var build_panel := PanelContainer.new()
	build_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DentiUIStyle.style_chip(build_panel)
	view.left_scroll.add_child(build_panel)
	build_panel.add_child(left)
	var portrait := TextureRect.new()
	view.build_portrait = portrait
	portrait.texture = preload("res://assets/denti/denti_unarmed.png")
	portrait.custom_minimum_size = Vector2(56, 56)
	portrait.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	portrait.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	portrait.mouse_filter = Control.MOUSE_FILTER_IGNORE
	var identity := HBoxContainer.new()
	identity.add_theme_constant_override("separation", 12)
	view.build_column.add_child(identity)
	identity.add_child(portrait)
	var name_label := DentiUIComponents.label(identity, "Denti", 19)
	name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	name_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	name_label.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	view.offer_scroll = ScrollContainer.new()
	view.offer_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.offer_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.offer_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	view.flow.add_child(view.offer_scroll)
	view.offer_column = VBoxContainer.new()
	view.offer_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.offer_column.add_theme_constant_override("separation", 12)
	view.offer_scroll.add_child(view.offer_column)
	view.offers_section = VBoxContainer.new()
	view.offers_section.add_theme_constant_override("separation", 4)
	view.offer_column.add_child(view.offers_section)
	view.offers_header = header
	view.reroll_button = DentiUIComponents.button(view.offers_header, "2")
	view.reroll_button.clip_text = true
	view.reroll_button.icon = ShopPanel.RELOAD_ICON
	view.reroll_button.add_theme_constant_override("icon_max_width", 20)
	view.reroll_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	view.offers_grid = GridContainer.new()
	view.offers_grid.columns = 2
	view.offers_grid.add_theme_constant_override("h_separation", 9)
	view.offers_section.add_child(view.offers_grid)
	for index in ShopController.OFFER_COUNT:
		var card := OfferCard.new()
		card.selection_only = true
		card.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		view.offers_grid.add_child(card)
		view.offer_buttons.append(card)
		card.pressed.connect(view._select.bind("offer", index))
		card.purchase_requested.connect(func() -> void: view.buy_requested.emit(index))
		card.reservation_requested.connect(func() -> void: view.reservation_requested.emit(index))
	view.inventory_label = DentiUIComponents.label(left, "", 17)
	view.inventory_scroll = ScrollContainer.new()
	view.inventory_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	view.inventory_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	view.inventory_scroll.custom_minimum_size.y = 76
	left.add_child(view.inventory_scroll)
	view.inventory_row = EquipmentSlots.new()
	view.inventory_row.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.inventory_row.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	view.inventory_scroll.add_child(view.inventory_row)
	view.stats_label = DentiUIComponents.label(left, "", 16)
	view.stat_grid = GridContainer.new()
	view.stat_grid.columns = 2
	view.stat_grid.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.stat_grid.add_theme_constant_override("h_separation", 5)
	view.stat_grid.add_theme_constant_override("v_separation", 5)
	view.build_column.add_child(view.stat_grid)
	view.stats_label.visible = false
	view.luck_label.visible = false
	for type in DentiAttributes.ACTIVE:
		var chip := Button.new()
		chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		chip.custom_minimum_size = Vector2(0, 34)
		chip.icon = DentiUIIcons.stat(DentiAttributes.ICONS[type])
		chip.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
		chip.expand_icon = true
		chip.add_theme_constant_override("icon_max_width", 23)
		chip.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
		chip.clip_text = true
		DentiUIStyle.style_button(chip, false, true)
		chip.add_theme_font_size_override("font_size", 13)
		for state in ["normal", "hover", "pressed", "disabled", "focus"]:
			var box := chip.get_theme_stylebox(state)
			box.content_margin_left = 5
			box.content_margin_right = 5
			box.content_margin_top = 3
			box.content_margin_bottom = 3
		view.stat_grid.add_child(chip)
		view.stat_chips.append(chip)
		chip.pressed.connect(func() -> void: DentiDentikon.open_attribute(chip, type))
	view.amalgam_chip = Button.new()
	view.amalgam_chip.visible = false
	view.amalgam_chip.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.amalgam_chip.custom_minimum_size.y = 34
	view.amalgam_chip.icon = DentiUIIcons.item(ShopController.by_id(&"amalgam_core").icon_index)
	view.amalgam_chip.expand_icon = true
	view.amalgam_chip.clip_text = true
	view.amalgam_chip.add_theme_constant_override("icon_max_width", 23)
	view.amalgam_chip.add_theme_font_size_override("font_size", 13)
	DentiUIStyle.style_button(view.amalgam_chip, false, true)
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		var box := view.amalgam_chip.get_theme_stylebox(state)
		box.content_margin_left = 5
		box.content_margin_right = 5
		box.content_margin_top = 3
		box.content_margin_bottom = 3
	view.stat_grid.add_child(view.amalgam_chip)
	view.amalgam_chip.pressed.connect(func() -> void:
		if is_instance_valid(view.player):
			DentiDentikon.open(view.amalgam_chip, "Amalgamkern", BuildPresentation.armor_explanation(view.player.items), view.amalgam_chip.icon)
	)
	view.detail_overlay = Control.new()
	view.detail_overlay.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.detail_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	view.get_node("Root").add_child(view.detail_overlay)
	var outside := ColorRect.new()
	outside.color = Color(0, 0, 0, 0.16)
	outside.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	view.detail_overlay.add_child(outside)
	outside.gui_input.connect(func(event: InputEvent) -> void:
		if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
			view.close_details()
			outside.accept_event()
		elif event is InputEventScreenTouch and event.pressed:
			view.close_details()
			outside.accept_event()
	)
	view.detail_popup = PanelContainer.new()
	DentiUIStyle.style_dialog(view.detail_popup)
	view.detail_overlay.add_child(view.detail_popup)
	view.details_panel = PanelContainer.new()
	view.details_panel.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DentiUIStyle.style_chip(view.details_panel, Color(0.96, 0.93, 0.85))
	view.details_scroll = ScrollContainer.new()
	view.details_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.details_scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.details_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	view.detail_column = VBoxContainer.new()
	view.detail_column.size_flags_vertical = Control.SIZE_EXPAND_FILL
	view.detail_popup.add_child(view.detail_column)
	view.detail_column.add_child(view.details_scroll)
	view.details_scroll.add_child(view.details_panel)
	var margin := MarginContainer.new()
	for edge in ["left", "right", "top", "bottom"]:
		margin.add_theme_constant_override("margin_" + edge, 8)
	view.details_panel.add_child(margin)
	view.details = ShopDetails.new()
	margin.add_child(view.details)
	view.details.merge_button.pressed.connect(func() -> void: view.merge_requested.emit(view.selected_index))
	view.details.evolution_requested.connect(func(id: StringName) -> void: view.evolution_requested.emit(view.selected_index, id))
	view.details.sell_button.pressed.connect(view._confirm_sale)
	view.details.confirm_button.pressed.connect(func() -> void: view.sell_requested.emit(view.selected_index))
	view.details.cancel_button.pressed.connect(view._render_selection)
	view.details.compare.item_selected.connect(view._compare)
	view.detail_actions = BoxContainer.new()
	view.detail_column.add_child(view.detail_actions)
	for button in [view.details.merge_button, view.details.sell_button, view.details.confirm_button, view.details.cancel_button]:
		button.reparent(view.detail_actions)
		button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		button.add_theme_font_size_override("font_size", 16)
	view.detail_buy_button = DentiUIComponents.button(view.detail_actions, "Kaufen", true)
	view.detail_buy_button.icon = DentiUIIcons.hud(2)
	view.detail_buy_button.add_theme_constant_override("icon_max_width", 23)
	view.detail_buy_button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.detail_buy_button.pressed.connect(func() -> void: view.buy_requested.emit(view.selected_index))
	view.detail_pin_button = DentiUIComponents.button(view.detail_actions, "")
	view.detail_pin_button.add_theme_constant_override("icon_max_width", 23)
	view.detail_pin_button.pressed.connect(func() -> void: view.reservation_requested.emit(view.selected_index))
	var actions := BoxContainer.new()
	view.shop_actions = actions
	view.rows.add_child(actions)
	view.reroll_button.pressed.connect(func() -> void: view.reroll_requested.emit())
	view.items_column = VBoxContainer.new()
	view.items_column.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.items_column.add_theme_constant_override("separation", 3)
	actions.add_child(view.items_column)
	view.items_label = DentiUIComponents.label(view.items_column, "Gesammelt · Keine Items", 13)
	view.items_label.autowrap_mode = TextServer.AUTOWRAP_OFF
	view.items_label.clip_text = true
	view.items_scroll = ScrollContainer.new()
	view.items_scroll.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	view.items_scroll.horizontal_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	view.items_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_DISABLED
	# Reserve the same footer slot before and after the first item purchase.
	view.items_scroll.custom_minimum_size.y = ShopPanel.FOOTER_ICONS_HEIGHT
	view.items_column.add_child(view.items_scroll)
	view.items_row = CollectedItems.new()
	view.items_row.add_theme_constant_override("separation", 5)
	view.items_scroll.add_child(view.items_row)
	view.continue_button = DentiUIComponents.button(actions, "Weiter", true)
	view.continue_button.clip_text = true
	view.continue_button.size_flags_horizontal = Control.SIZE_SHRINK_END
	view.continue_button.size_flags_vertical = Control.SIZE_SHRINK_END
	view.continue_button.pressed.connect(func() -> void: view.continue_requested.emit())
	view.get_viewport().size_changed.connect(view._queue_layout)
	view.left_scroll.resized.connect(view._layout_inventory)
	view.inventory_scroll.resized.connect(view._layout_inventory)
	view.detail_actions.add_theme_constant_override("separation", 6)
	view.detail_column.add_theme_constant_override("separation", 8)
	view.details_scroll.vertical_scroll_mode = ScrollContainer.SCROLL_MODE_AUTO
	view.details_panel.minimum_size_changed.connect(view._queue_popup_layout)
	view.detail_actions.minimum_size_changed.connect(view._queue_popup_layout)
	view.detail_overlay.visible = false
	view.details.close_button.pressed.connect(view.close_details)
	view.detail_column.visible = false
	view.detail_actions.visible = false
	view.inventory_row.selected.connect(func(index: int) -> void: view._select("equipment", index))
	view.inventory_row.merge_requested.connect(func(index: int) -> void: view.merge_requested.emit(index))
	view.items_row.selected.connect(func(index: int) -> void: view._select("item", index))
