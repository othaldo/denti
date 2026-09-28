class_name DentiArena
extends Node2D

const SIZE := Vector2(1280.0, 720.0)
const GRID_SPACING := 64


func _draw() -> void:
	draw_rect(Rect2(Vector2.ZERO, SIZE), Color(0.94, 0.91, 0.82))
	for x in range(0, int(SIZE.x) + 1, GRID_SPACING):
		draw_line(Vector2(x, 0), Vector2(x, SIZE.y), Color(0.86, 0.82, 0.72, 0.32), 1.0)
	for y in range(0, int(SIZE.y) + 1, GRID_SPACING):
		draw_line(Vector2(0, y), Vector2(SIZE.x, y), Color(0.86, 0.82, 0.72, 0.32), 1.0)
	draw_rect(Rect2(Vector2(14, 14), SIZE - Vector2(28, 28)), Color(0.55, 0.43, 0.44), false, 4.0)
