class_name WeaponMasteryCard
extends Button

var data: WeaponData
var flags := 0
var artwork: TextureRect
var heading: Label
var progress: Label
var badges: Array[TextureRect] = []
var captions: Array[Label] = []


func _ready() -> void:
	MenuStyle.action(self)
	custom_minimum_size.y = 164
	var complete := flags == WeaponMasteries.all_flags()
	add_theme_stylebox_override("normal", MenuStyle.box(DentiUIStyle.PANEL, DentiUIStyle.GOLD if complete else DentiUIStyle.LINE, 16, 1))
	artwork = _art(RunSetupPresentation.weapon_icon(data))
	heading = _label(18)
	progress = _label(14)
	progress.text = "%d/4" % WeaponMasteries.ids_for(flags).size()
	progress.add_theme_color_override("font_color", DentiUIStyle.GOLD if complete else DentiUIStyle.MUTED)
	for definition in WeaponMasteries.ALL:
		var art := _art(WeaponMasteryIcons.icon(definition.icon_index))
		art.modulate = Color.WHITE if flags & definition.flag else Color(0.42, 0.38, 0.46, 0.5)
		badges.append(art)
		var caption := _label(12)
		caption.text = "Prüfung" if definition.id == &"exam" else definition.display_name
		caption.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		caption.add_theme_color_override("font_color", DentiUIStyle.INK if flags & definition.flag else DentiUIStyle.MUTED)
		captions.append(caption)
	tooltip_text = data.display_name + " · " + progress.text + "\nAnforderungen ansehen"
	resized.connect(_layout)
	_layout()


func _art(texture: Texture2D) -> TextureRect:
	var art := TextureRect.new()
	art.texture = texture
	art.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	art.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	art.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	art.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(art)
	return art


func _label(font_size: int) -> Label:
	var label := Label.new()
	label.add_theme_font_size_override("font_size", font_size)
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(label)
	return label


func _layout() -> void:
	if artwork == null: return
	artwork.position = Vector2(14, 10)
	artwork.size = Vector2(60, 72)
	DentiUIComponents.wrap_text(heading, data.display_name, maxf(size.x - 100, 40), 18)
	heading.position = Vector2(88, 14)
	heading.size = Vector2(maxf(size.x - 102, 40), 48)
	progress.position = Vector2(88, 65)
	progress.size = Vector2(size.x - 102, 22)
	var cell := (size.x - 24) / 4
	for index in badges.size():
		badges[index].position = Vector2(12 + index * cell + (cell - 32) / 2, 100)
		badges[index].size = Vector2(32, 32)
		captions[index].position = Vector2(12 + index * cell, 136)
		captions[index].size = Vector2(cell, 20)
