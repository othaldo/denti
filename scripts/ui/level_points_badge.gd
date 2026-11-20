class_name LevelPointsBadge
extends Control

## Free level points in the talent header: the gold level-up chevron the HUD
## uses for pending level-ups, plus the count. Details live in the tooltip.

const FONT_SIZE := 22
const ICON := Vector2(22, 22)
const GAP := 8.0

var count := 0:
	set(value):
		count = value
		tooltip_text = "Freie Levelpunkte: %d" % count
		update_minimum_size()
		queue_redraw()

func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP
	size_flags_vertical = Control.SIZE_SHRINK_CENTER
	tooltip_text = "Freie Levelpunkte"

func _text_width() -> float:
	return DentiUIStyle.FONT.get_string_size(str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE).x

func _get_minimum_size() -> Vector2:
	return Vector2(ICON.x + GAP + _text_width() + 4, maxf(ICON.y, 32))

func _draw() -> void:
	var middle := size.y * 0.5
	var color := DentiUIStyle.GOLD if count > 0 else DentiUIStyle.MUTED
	# Two stacked chevrons: "level up", matching the HUD pending-level marker.
	for offset in [-4.0, 4.0]:
		var y: float = middle + offset
		draw_polyline(PackedVector2Array([Vector2(2, y + 5), Vector2(ICON.x * 0.5, y - 4), Vector2(ICON.x - 2, y + 5)]), color, 3.0, true)
	var font := DentiUIStyle.FONT
	var baseline := middle + (font.get_ascent(FONT_SIZE) - font.get_descent(FONT_SIZE)) * 0.5
	draw_string(font, Vector2(ICON.x + GAP, baseline), str(count), HORIZONTAL_ALIGNMENT_LEFT, -1, FONT_SIZE, DentiUIStyle.INK if count > 0 else DentiUIStyle.MUTED)
