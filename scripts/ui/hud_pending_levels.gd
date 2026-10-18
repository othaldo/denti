class_name HUDPendingLevels
extends Control

const EXTENT := Vector2(30, 18)
const PADDING := 6.0
const ICON_WIDTH := 8.0
const GAP := 4.0
const FLASH_DURATION := 0.3
var count := 0
var flash_remaining := 0.0
var label: Label
var _initialized := false
var _reward_focus := false
var _rim := StyleBoxFlat.new()
var _icon_left := PADDING


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	size = EXTENT
	_rim.set_corner_radius_all(9)
	_rim.set_border_width_all(1)
	_rim.anti_aliasing = true
	label = Label.new()
	label.name = "Count"
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	DentiUIStyle.style_hud_text(label, DentiUIStyle.INK, 12, 1, DentiUIStyle.BACKGROUND)
	add_child(label)
	resized.connect(_layout)
	label.theme_changed.connect(fit_content)
	label.minimum_size_changed.connect(fit_content)
	_layout()
	visible = false


func _layout() -> void:
	var factor := size.y / EXTENT.y
	var text_width := _text_width() + 2 * factor
	var group_width := (ICON_WIDTH + GAP) * factor + text_width
	_icon_left = (size.x - group_width) * 0.5
	label.position = Vector2(_icon_left + (ICON_WIDTH + GAP) * factor, 0)
	label.size = Vector2(text_width, size.y)
	queue_redraw()


func _text_width() -> float:
	return ceilf(label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x)


func content_size() -> Vector2:
	var factor := size.y / EXTENT.y
	return Vector2(maxf(EXTENT.x * factor, (PADDING * 2 + ICON_WIDTH + GAP + 2) * factor + _text_width()), size.y)


func fit_content() -> void:
	size = content_size()
	_layout()


func show_count(amount: int) -> void:
	var next := maxi(amount, 0)
	if _initialized and count == next:
		return
	var gained := _initialized and next > count
	count = next
	_initialized = true
	label.text = "99+" if count >= 100 else str(count)
	fit_content()
	tooltip_text = "%d offene Aufstiege · Auswahl nach der Welle" % count
	visible = count > 0
	flash_remaining = FLASH_DURATION if gained and DentiUIMotion.enabled(self) else 0.0
	queue_redraw()


func set_reward_focus(enabled: bool) -> void:
	if _reward_focus == enabled:
		return
	_reward_focus = enabled
	queue_redraw()


func _process(delta: float) -> void:
	if not DentiUIMotion.enabled(self):
		if flash_remaining > 0:
			flash_remaining = 0
			queue_redraw()
		return
	if not get_tree().paused:
		advance(delta)


func advance(delta: float) -> void:
	if flash_remaining <= 0:
		return
	flash_remaining = maxf(0, flash_remaining - delta)
	queue_redraw()


func _draw() -> void:
	var factor := size.y / EXTENT.y
	var flash := sin((1.0 - flash_remaining / FLASH_DURATION) * PI) if flash_remaining > 0 else 0.0
	var base := Color("3e2b41") if _reward_focus else Color("261d2e")
	_rim.bg_color = base.lerp(Color("69503a"), flash * 0.5)
	_rim.border_color = DentiUIStyle.GOLD.lerp(DentiUIStyle.INK, flash * 0.7)
	_rim.set_corner_radius_all(roundi(9 * factor))
	_rim.set_border_width_all(maxi(1, roundi((2 if _reward_focus else 1) * factor)))
	draw_style_box(_rim, Rect2(Vector2.ZERO, size))
	# The simple chevron remains crisp at its actual 8px width.
	var middle := size.y * 0.5 - flash * 0.6 * factor
	draw_polyline(PackedVector2Array([Vector2(_icon_left, middle + 2 * factor), Vector2(_icon_left + 4 * factor, middle - 2 * factor), Vector2(_icon_left + ICON_WIDTH * factor, middle + 2 * factor)]), DentiUIStyle.GOLD, 1.6 * factor, true)
