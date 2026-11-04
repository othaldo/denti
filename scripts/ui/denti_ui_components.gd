class_name DentiUIComponents
extends RefCounted


static func wrap_text(label: Label, source: String, width: float, font_size: int = 0, skip_empty_lines: bool = false) -> float:
	# Shape at the final width before containers ask for child minimum sizes.
	# Explicit newlines avoid stale deferred autowrap sizes after a resize.
	var paragraph := TextParagraph.new()
	paragraph.width = width
	paragraph.break_flags = TextServer.BREAK_MANDATORY | TextServer.BREAK_WORD_BOUND | TextServer.BREAK_ADAPTIVE
	paragraph.add_string(source, label.get_theme_font("font"), font_size if font_size > 0 else label.get_theme_font_size("font_size"))
	var lines := PackedStringArray()
	for index in paragraph.get_line_count():
		var span := paragraph.get_line_range(index)
		var line := source.substr(span.x, span.y - span.x).strip_edges()
		if not skip_empty_lines or not line.is_empty(): lines.append(line)
	label.autowrap_mode = TextServer.AUTOWRAP_OFF
	label.text = "\n".join(lines)
	return ceilf(paragraph.get_size().y)


static func label(parent: Node, text: String, font_size: int) -> Label:
	var label := Label.new()
	label.text = text
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	label.add_theme_color_override("font_color", DentiUIStyle.INK)
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
	return label


static func button(parent: Node, text: String, primary: bool = false) -> Button:
	var button := Button.new()
	button.text = text
	button.custom_minimum_size.y = 54
	button.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	DentiUIStyle.style_button(button, primary)
	parent.add_child(button)
	return button
