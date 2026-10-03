class_name ShopDetails
extends VBoxContainer

var heading: Label
var subtitle: Label
var icon: TextureRect
var values_grid: GridContainer
var effect: Label
var synergy: Label
var compare: OptionButton
var compare_text: Label
var action_hint: Label
var sell_button: Button
var merge_button: Button
var confirm_button: Button
var cancel_button: Button
var close_button: Button
var terms_row: HFlowContainer
var evolution_options: VBoxContainer
signal evolution_requested(recipe_id: StringName)


func _ready() -> void:
	add_theme_constant_override("separation", 5)
	var header := HBoxContainer.new()
	header.add_theme_constant_override("separation", 10)
	add_child(header)
	icon = TextureRect.new()
	icon.custom_minimum_size = Vector2(56, 56)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	header.add_child(icon)
	var titles := VBoxContainer.new()
	titles.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	header.add_child(titles)
	heading = _label(titles, "", 21)
	subtitle = _label(titles, "", 15)
	close_button = Button.new()
	close_button.text = "×"
	close_button.custom_minimum_size = Vector2(36, 36)
	close_button.size_flags_vertical = Control.SIZE_SHRINK_BEGIN
	close_button.tooltip_text = "Details schließen"
	close_button.visible = false
	DentiUIStyle.style_button(close_button)
	header.add_child(close_button)
	values_grid = GridContainer.new()
	values_grid.columns = 2
	values_grid.add_theme_constant_override("h_separation", 14)
	values_grid.add_theme_constant_override("v_separation", 2)
	add_child(values_grid)
	effect = _label(self, "", 15)
	synergy = _label(self, "", 14)
	synergy.add_theme_color_override("font_color", DentiUIStyle.MINT)
	evolution_options = VBoxContainer.new()
	evolution_options.add_theme_constant_override("separation", 5)
	add_child(evolution_options)
	terms_row = HFlowContainer.new()
	terms_row.add_theme_constant_override("h_separation", 5)
	add_child(terms_row)
	compare = OptionButton.new()
	compare.custom_minimum_size.y = 44
	compare.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	compare.clip_text = true
	compare.fit_to_longest_item = false
	add_child(compare)
	compare_text = _label(self, "", 15)
	action_hint = _label(self, "", 16)
	merge_button = _button("Fusionieren", true)
	sell_button = _button("Verkaufen")
	confirm_button = _button("Verkauf bestätigen")
	cancel_button = _button("Abbrechen")
	clear_actions()


func show_weapon(data: WeaponData, tier: int, player: Player, equipped: bool, equipment: Array[Dictionary]) -> void:
	clear_actions()
	heading.text = data.display_name
	icon.texture = data.sprite
	subtitle.text = "%s · Stufe %s · %s · %s" % ["Ausgerüstet" if equipped else "Angebot", ["I", "II", "III", "IV"][tier - 1], data.roots_text(), data.damage_type_label()]
	if data.evolution_kind != &"":
		subtitle.text = "Spezialwaffe · %s · %s" % [data.roots_text(), data.damage_type_label()]
	var current := WeaponPresentation.values(data, tier, player)
	_clear_values()
	_value("Treffer", "%.1f" % current.damage)
	_value("Angriffspause", "%.2f s" % current.pause)
	_value("Reichweite", "%d" % roundi(current.range))
	_value(DentiAttributes.name_for(DentiAttributes.Type.CRIT_CHANCE), "%d %% · ×%.1f" % [roundi(current.crit * 100.0), current.multiplier])
	if data.knockback_at_tier(tier) > 0:
		_value("Rückstoß", "%d" % roundi(data.knockback_at_tier(tier)))
	if data.splash_at_tier(tier) > 0:
		_value("Explosionsradius", "%d" % roundi(data.splash_at_tier(tier)))
	var mechanics: PackedStringArray = []
	for part in data.combat_text().split(" · "):
		if part.begins_with("Schadensart:") or part.contains("Waffen-Crit") or part.ends_with("Crit"):
			continue
		mechanics.append(part)
	effect.text = " · ".join(mechanics)
	if data.evolution_kind != &"":
		effect.text = data.description
	effect.visible = not effect.text.is_empty()
	synergy.text = WeaponPresentation.synergy(data, equipment, player)
	synergy.visible = not synergy.text.is_empty()
	compare.visible = not equipped and not equipment.is_empty()
	compare_text.visible = compare.visible
	_terms(effect.text + " " + synergy.text + " Wurzeln " + DentiAttributes.name_for(DentiAttributes.Type.CRIT_CHANCE))


func show_item(entry: Dictionary, owned: bool) -> void:
	clear_actions()
	heading.text = str(entry.get("name", "Item"))
	icon.texture = entry.get("icon")
	subtitle.text = "×%d" % int(entry.get("count", 1)) if owned else "Item"
	_clear_values()
	effect.text = DentiAttributes.resolve_text(str(entry.get("description", "")))
	effect.visible = not effect.text.is_empty()
	synergy.visible = false
	compare.visible = false
	compare_text.visible = false
	_terms(effect.text)


func clear_actions() -> void:
	if evolution_options != null:
		for child in evolution_options.get_children():
			child.free()
	for button in [sell_button, merge_button, confirm_button, cancel_button]:
		button.visible = false
	action_hint.text = ""
	action_hint.visible = false


func show_evolutions(recipes: Array[WeaponEvolutionRecipe]) -> void:
	for recipe in recipes:
		_label(evolution_options, recipe.result.description, 14)
		var consumed := WeaponCatalog.by_id(recipe.base_weapon).display_name
		if recipe.partner_weapon != &"":
			consumed += " + " + WeaponCatalog.by_id(recipe.partner_weapon).display_name
		_label(evolution_options, "Ersetzt %s · %s\nItems bleiben erhalten" % [consumed, recipe.result.roots_text()], 13)
		var button := Button.new()
		button.text = "Fusionieren · " + recipe.result.display_name
		button.icon = recipe.result.sprite
		button.expand_icon = true
		button.add_theme_constant_override("icon_max_width", 32)
		button.custom_minimum_size.y = 44
		button.mouse_default_cursor_shape = Control.CURSOR_POINTING_HAND
		DentiUIStyle.style_button(button, true)
		DentiUIMotion.bind_action(button)
		evolution_options.add_child(button)
		button.pressed.connect(func() -> void: evolution_requested.emit(recipe.id))


func _value(key: String, value: String) -> void:
	var type := DentiAttributes.NAMES.find(key)
	var texture: Texture2D
	if key == "Treffer":
		texture = DentiUIIcons.stat(0)
	elif key == "Angriffspause":
		texture = DentiUIIcons.hud(5)
	elif key == "Reichweite":
		texture = DentiUIIcons.RANGE
	elif type >= 0:
		texture = DentiUIIcons.stat(DentiAttributes.ICONS[type])
	if texture != null:
		var image := TextureRect.new()
		image.texture = texture
		image.tooltip_text = key
		image.custom_minimum_size = Vector2(26, 26)
		image.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		values_grid.add_child(image)
	else:
		var label := _label(values_grid, key, 15)
		label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		label.add_theme_color_override("font_color", DentiUIStyle.MUTED)
	var number := _label(values_grid, value, 15)
	number.autowrap_mode = TextServer.AUTOWRAP_OFF
	number.horizontal_alignment = HORIZONTAL_ALIGNMENT_RIGHT
	number.tooltip_text = key + " · " + value


func _terms(text: String) -> void:
	for child in terms_row.get_children():
		terms_row.remove_child(child)
		child.queue_free()
	for term in DentiDentikon.terms_in(text):
		var link := Button.new()
		link.text = term
		link.tooltip_text = "Im Dentikon erklären"
		DentiUIStyle.style_button(link)
		link.add_theme_font_size_override("font_size", 13)
		terms_row.add_child(link)
		link.pressed.connect(func() -> void: DentiDentikon.open_term(link, term))


func _clear_values() -> void:
	for child in values_grid.get_children():
		values_grid.remove_child(child)
		child.queue_free()


func _button(text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 52
	DentiUIStyle.style_button(button, primary)
	add_child(button)
	return button


static func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", DentiUIStyle.INK)
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label
