class_name RunEndNotices
extends ScrollContainer

const HELL_ART: Texture2D = preload("res://assets/ui/run_setup/hell.png")
const CARD_HEIGHT := 60.0

var content: MarginContainer
var notices: VBoxContainer


func _ready() -> void:
	horizontal_scroll_mode = SCROLL_MODE_DISABLED
	follow_focus = true
	content = MarginContainer.new()
	content.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	content.mouse_filter = Control.MOUSE_FILTER_PASS
	add_child(content)
	notices = VBoxContainer.new()
	notices.add_theme_constant_override("separation", 8)
	content.add_child(notices)
	var scrollbar := get_v_scroll_bar()
	scrollbar.custom_minimum_size.x = 7
	scrollbar.add_theme_stylebox_override("scroll", MenuStyle.box(DentiUIStyle.BACKGROUND, Color.TRANSPARENT, 3, 0))
	for state in ["grabber", "grabber_highlight", "grabber_pressed"]:
		var color := DentiUIStyle.MUTED if state == "grabber" else DentiUIStyle.INK
		scrollbar.add_theme_stylebox_override(state, MenuStyle.box(color, Color.TRANSPARENT, 3, 0))
	hide()


func present(recap: Dictionary) -> void:
	for card in notices.get_children():
		notices.remove_child(card)
		card.queue_free()
	scroll_vertical = 0

	if recap.get("hell_unlocked_now", false):
		_add_notice("Hell", "Schwierigkeit freigeschaltet", HELL_ART, DentiUIStyle.MINT, &"difficulty")
	for id in recap.get("class_unlocks", []):
		var profile := ClassCatalog.by_id(StringName(str(id)))
		if profile != null: _add_notice(profile.display_name, "Klasse freigeschaltet", profile.portrait, DentiUIStyle.MINT, &"class")

	# The wave-20 results already celebrated the starter's seals and their unlocks.
	var after_victory := bool(recap.get("endless_enabled", false)) and bool(recap.get("base_victory", false))
	if not after_victory:
		var mastery: Dictionary = recap.get("weapon_mastery", {})
		for id in recap.get("weapon_unlocks", []):
			var weapon := WeaponCatalog.by_id(StringName(id))
			if weapon != null:
				_add_notice(weapon.display_name, "Waffe freigeschaltet", RunSetupPresentation.weapon_icon(weapon), DentiUIStyle.MINT, &"weapon")
		var starter := StringName(mastery.get("starter_id", ""))
		if WeaponMasteries.valid_weapon(starter):
			var weapon := WeaponCatalog.by_id(starter)
			for id in mastery.get("earned", []):
				var award := WeaponMasteries.by_id(StringName(id))
				if award == null: continue
				var title := "Zahnprüfung bestanden" if award.id == &"exam" else award.display_name + " erreicht"
				_add_notice(title, weapon.display_name, WeaponMasteryIcons.icon(award.icon_index), DentiUIStyle.GOLD, &"seal")

	for id in recap.get("new_fusion_discoveries", []):
		var recipe := WeaponEvolutions.by_id(StringName(id))
		if recipe != null:
			_add_notice(recipe.result.display_name, "Neu in der Dentipedia", RunSetupPresentation.weapon_icon(recipe.result), DentiUIStyle.MINT, &"fusion")

	# The closest next goals keep "one more run" in view, even after a death.
	# An endless death after the wave-20 result does not repeat them.
	for goal: Dictionary in ([] if after_victory else recap.get("near_unlocks", [])):
		var weapon := WeaponCatalog.by_id(StringName(str(goal.get("id", ""))))
		if weapon == null: continue
		var labels := _add_notice(weapon.display_name, "Fast geschafft · " + str(goal.get("text", "")), RunSetupPresentation.weapon_icon(weapon), DentiUIStyle.GOLD, &"goal")
		var bar := ProgressBar.new()
		bar.name = "GoalProgress"
		bar.show_percentage = false
		bar.custom_minimum_size = Vector2(0, 6)
		bar.max_value = maxf(1.0, float(goal.get("goal", 1)))
		bar.value = float(goal.get("current", 0))
		bar.mouse_filter = Control.MOUSE_FILTER_IGNORE
		bar.add_theme_stylebox_override("background", MenuStyle.box(DentiUIStyle.BACKGROUND, Color.TRANSPARENT, 3, 0))
		bar.add_theme_stylebox_override("fill", MenuStyle.box(DentiUIStyle.GOLD, Color.TRANSPARENT, 3, 0))
		labels.add_child(bar)

	if not has_entries() or not DentiUIMotion.enabled(self):
		return
	var gap := minf(0.11, 0.44 / maxf(1, notices.get_child_count() - 1))
	for index in notices.get_child_count():
		DentiUIMotion.reveal(notices.get_child(index), index * gap, 0.0)


func has_entries() -> bool:
	return notices.get_child_count() > 0


func fit(width: float, height: float) -> void:
	var content_height := notices.get_combined_minimum_size().y
	var scrollable := content_height > height
	content.add_theme_constant_override("margin_right", 12 if scrollable else 0)
	custom_minimum_size = Vector2(width, minf(height, content_height))
	for card: Control in notices.get_children():
		card.focus_mode = Control.FOCUS_ALL if scrollable else Control.FOCUS_NONE


## Cards per kind (&"seal", &"weapon", &"class", &"fusion", &"goal", ...).
func count(kind: StringName) -> int:
	return notices.get_children().filter(func(card: Node) -> bool: return card.get_meta("notice_kind", &"") == kind).size()


func _add_notice(title: String, detail: String, texture: Texture2D, accent: Color, kind: StringName = &"") -> VBoxContainer:
	var card := PanelContainer.new()
	card.set_meta("notice_kind", kind)
	card.custom_minimum_size.y = CARD_HEIGHT
	card.mouse_filter = Control.MOUSE_FILTER_PASS
	var surface := MenuStyle.box(DentiUIStyle.PANEL.lerp(accent, 0.09), accent.darkened(0.32), 14, 1)
	surface.content_margin_left = 10
	surface.content_margin_right = 10
	surface.content_margin_top = 6
	surface.content_margin_bottom = 6
	card.add_theme_stylebox_override("panel", surface)
	var focused := surface.duplicate() as StyleBoxFlat
	focused.border_color = DentiUIStyle.INK
	focused.set_border_width_all(2)
	card.focus_entered.connect(func() -> void: card.add_theme_stylebox_override("panel", focused))
	card.focus_exited.connect(func() -> void: card.add_theme_stylebox_override("panel", surface))
	card.tooltip_text = title + "\n" + detail
	notices.add_child(card)

	var row := HBoxContainer.new()
	row.mouse_filter = Control.MOUSE_FILTER_IGNORE
	row.add_theme_constant_override("separation", 10)
	card.add_child(row)
	var icon := TextureRect.new()
	icon.mouse_filter = Control.MOUSE_FILTER_IGNORE
	icon.texture = texture
	icon.custom_minimum_size = Vector2(40, 40)
	icon.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	icon.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	row.add_child(icon)
	var labels := VBoxContainer.new()
	labels.mouse_filter = Control.MOUSE_FILTER_IGNORE
	labels.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	labels.size_flags_vertical = Control.SIZE_SHRINK_CENTER
	labels.add_theme_constant_override("separation", 0)
	row.add_child(labels)
	_add_label(labels, title, 15, DentiUIStyle.INK)
	_add_label(labels, detail, 13, accent)
	return labels


func _add_label(parent: Control, value: String, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = value
	label.text_overrun_behavior = TextServer.OVERRUN_TRIM_ELLIPSIS
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
