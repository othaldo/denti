class_name DentiDentikon
extends RefCounted

# Stat names/meanings come from the same source as upgrades and inventory.
const MECHANICS := {
	"Nass": "Wasserangriffe können Gegner durchnässen. Passende Items verändern Dauer und Wechselwirkungen; die konkreten Werte stehen beim Item.",
	"Blutung": "Schaden über Zeit. Stärke und Dauer hängen von der Quelle ab. Bei Denti reduziert Härte den Blutungsschaden.",
	"Gift": "Schaden über Zeit. Gift an Denti ignoriert Härte. Laufende Effekte enden nach dem Kampf.",
	"Wurzeln": "Denti hat sechs Wurzeln. Waffen belegen eine oder zwei. Gleiche Waffen derselben Stufe können bis Stufe IV fusionieren; dabei werden Wurzeln frei.",
	"Münzen": "Währung für Waffen, Items und Neuwürfeln. Der Pin merkt ein Angebot kostenlos und hält seinen Preis fest.",
}


static func open_attribute(source: Control, type: DentiAttributes.Type) -> void:
	open(source, DentiAttributes.name_for(type), DentiAttributes.meaning_for(type), DentiUIIcons.stat(DentiAttributes.ICONS[type]))


static func open_term(source: Control, term: String) -> void:
	var index := DentiAttributes.NAMES.find(term)
	if index >= 0:
		open_attribute(source, index)
	elif MECHANICS.has(term):
		open(source, term, MECHANICS[term])


static func terms_in(text: String) -> PackedStringArray:
	var result: PackedStringArray = []
	for term in DentiAttributes.NAMES + MECHANICS.keys():
		if text.contains(term):
			result.append(term)
	return result


static func open(source: Control, title: String, explanation: String, icon: Texture2D = null) -> void:
	var popup := PopupPanel.new()
	popup.process_mode = Node.PROCESS_MODE_ALWAYS
	popup.theme = DentiUIStyle.make_theme()
	popup.add_theme_stylebox_override("panel", DentiUIStyle._box(DentiUIStyle.PANEL, DentiUIStyle.LINE, 16, 1))
	source.add_child(popup)
	var rows := VBoxContainer.new()
	rows.add_theme_constant_override("separation", 12)
	popup.add_child(rows)
	var header := HBoxContainer.new()
	rows.add_child(header)
	if icon != null:
		var image := TextureRect.new()
		image.texture = icon
		image.custom_minimum_size = Vector2(36, 36)
		image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		header.add_child(image)
	var heading := _label(header, title, 22)
	heading.autowrap_mode = TextServer.AUTOWRAP_OFF
	heading.clip_text = true
	heading.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	var close := Button.new()
	close.text = "×"
	close.tooltip_text = "Dentikon schließen"
	DentiUIStyle.style_button(close)
	header.add_child(close)
	close.pressed.connect(popup.hide)
	var width := minf(440, source.get_viewport_rect().size.x - 32)
	var body := _label(rows, explanation, 17)
	body.autowrap_mode = TextServer.AUTOWRAP_OFF
	body.custom_minimum_size.x = width - 32
	rows.custom_minimum_size.x = width - 32
	popup.popup_hide.connect(func() -> void:
		if is_instance_valid(source):
			source.grab_focus()
		popup.queue_free()
	)
	# Shape at the final width. PopupPanel asks for child minimums before its
	# first layout; Label autowrap otherwise reports a character-wide column.
	var paragraph := TextParagraph.new()
	paragraph.width = width - 32
	paragraph.add_string(explanation, body.get_theme_font("font"), 17)
	var lines: PackedStringArray = []
	for index in paragraph.get_line_count():
		var span := paragraph.get_line_range(index)
		lines.append(explanation.substr(span.x, span.y - span.x).strip_edges())
	body.text = "\n".join(lines)
	var height := ceili(rows.get_combined_minimum_size().y + 32)
	popup.popup_centered(Vector2i(roundi(width), height))
	close.grab_focus()


static func _label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", DentiUIStyle.INK)
	parent.add_child(label)
	return label
