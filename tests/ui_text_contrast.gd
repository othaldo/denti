extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	root.theme = DentiUIStyle.make_theme()
	var font := root.theme.default_font as FontVariation
	var text_server := TextServerManager.get_primary_interface()
	var weight_tag := text_server.name_to_tag("weight")
	if font == null or float(text_server.font_get_variation_coordinates(font.get_rids()[0]).get(weight_tag, 300)) < 400:
		_fail("UI uses the thin default font instead of a readable text weight")
		return
	var shop := OfferCard.new()
	shop.selection_only = true
	root.add_child(shop)
	shop.set_catalog_layout(true)
	var reward := UpgradeCard.new()
	root.add_child(reward)
	for tier in range(1, 6):
		var item := ShopController.by_id(&"conductive_varnish").duplicate() as ShopOfferData
		item.rarity_tier = tier
		shop.show_offer(item, 0)
		reward.show_item(item)
		for card in [shop, reward]:
			for state in ["normal", "hover", "pressed", "disabled"]:
				var background: Color = (card.get_theme_stylebox(state) as StyleBoxFlat).bg_color
				for label in [card.name_label, card.effect_label]:
					if _contrast(label.get_theme_color("font_color"), background) < 7.0:
						_fail("name or effect lacks contrast at tier %d / %s" % [tier, state])
						return
				if card == shop and _contrast(shop.category_label.get_theme_color("font_color"), background) < 7.0:
					_fail("small weapon/item category lacks contrast at tier %d / %s" % [tier, state])
					return
				if card == reward and _contrast(reward.rarity_label.get_theme_color("font_color"), background) < 7.0:
					_fail("small rarity label lacks contrast at tier %d / %s" % [tier, state])
					return
		var price_background := (shop.buy_button.get_theme_stylebox("disabled") as StyleBoxFlat).bg_color
		var price := shop.price_label.get_theme_color("font_color")
		price = price_background.lerp(price, price.a * shop.price_label.get_parent().modulate.a)
		if not shop.buy_button.disabled or _contrast(price, price_background) < 7.0:
			_fail("unaffordable price disappears into the disabled button")
			return
	var button := Button.new()
	root.add_child(button)
	for primary in [false, true]:
		DentiUIStyle.style_button(button, primary)
		for state in ["normal", "hover", "pressed", "disabled"]:
			var color_key := "font_color" if state == "normal" else "font_%s_color" % state
			if _contrast(button.get_theme_color(color_key), (button.get_theme_stylebox(state) as StyleBoxFlat).bg_color) < 7.0:
				_fail("button text lacks contrast for primary=%s / %s" % [primary, state])
				return
		if (button.get_theme_stylebox("focus") as StyleBoxFlat).draw_center:
			_fail("focus fill washes out button text")
			return
	print("Denti UI text contrast test passed")
	quit(0)


func _contrast(first: Color, second: Color) -> float:
	var a := _luminance(first)
	var b := _luminance(second)
	return (maxf(a, b) + 0.05) / (minf(a, b) + 0.05)


func _luminance(color: Color) -> float:
	var value := 0.0
	var channels := [color.r, color.g, color.b]
	var weights := [0.2126, 0.7152, 0.0722]
	for index in 3:
		var c: float = channels[index]
		value += (c / 12.92 if c <= 0.04045 else pow((c + 0.055) / 1.055, 2.4)) * weights[index]
	return value


func _fail(message: String) -> void:
	push_error(message)
	quit(1)
