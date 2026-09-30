class_name DentiArena
extends Node2D

const SIZE := Vector2(1920.0, 1080.0)
const VIEWPORT_PADDING := Vector2(640.0, 360.0)
const WALL_WIDTH := 36.0
const PLAYER_MARGIN := 48.0
const FLOOR: Texture2D = preload("res://assets/environment/dental_arena_floor.png")
const VOID_COLOR := Color("30313c")
const WALL_COLOR := Color("484450")
const WALL_EDGE_COLOR := Color("827d83")
const WALL_TRIM_COLOR := Color("c9b58f")

var arena_size: Vector2 = SIZE


func _ready() -> void:
	_resize()
	get_viewport().size_changed.connect(_resize)


func _resize() -> void:
	var viewport_size := get_viewport_rect().size
	arena_size = arena_size.max(Vector2(maxf(SIZE.x, viewport_size.x + VIEWPORT_PADDING.x), maxf(SIZE.y, viewport_size.y + VIEWPORT_PADDING.y)))
	queue_redraw()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(-viewport_size, arena_size + viewport_size * 2.0), VOID_COLOR)
	var texture_size := FLOOR.get_size()
	var cover_scale := maxf(arena_size.x / texture_size.x, arena_size.y / texture_size.y)
	var source_size := arena_size / cover_scale
	var source_rect := Rect2((texture_size - source_size) / 2.0, source_size)
	draw_texture_rect_region(FLOOR, Rect2(Vector2.ZERO, arena_size), source_rect)
	var width := arena_size.x
	var height := arena_size.y
	draw_rect(Rect2(0.0, 0.0, width, WALL_WIDTH), WALL_COLOR)
	draw_rect(Rect2(0.0, height - WALL_WIDTH, width, WALL_WIDTH), WALL_COLOR)
	draw_rect(Rect2(0.0, WALL_WIDTH, WALL_WIDTH, height - WALL_WIDTH * 2.0), WALL_COLOR)
	draw_rect(Rect2(width - WALL_WIDTH, WALL_WIDTH, WALL_WIDTH, height - WALL_WIDTH * 2.0), WALL_COLOR)
	draw_rect(Rect2(Vector2.ZERO, arena_size), WALL_EDGE_COLOR, false, 4.0)
	draw_rect(Rect2(Vector2.ONE * WALL_WIDTH, arena_size - Vector2.ONE * WALL_WIDTH * 2.0), WALL_TRIM_COLOR, false, 3.0)
	for x in range(112, int(width), 112):
		draw_line(Vector2(x, 4.0), Vector2(x, WALL_WIDTH - 5.0), WALL_EDGE_COLOR, 2.0)
		draw_line(Vector2(x, height - WALL_WIDTH + 5.0), Vector2(x, height - 4.0), WALL_EDGE_COLOR, 2.0)
	for y in range(112, int(height), 112):
		draw_line(Vector2(4.0, y), Vector2(WALL_WIDTH - 5.0, y), WALL_EDGE_COLOR, 2.0)
		draw_line(Vector2(width - WALL_WIDTH + 5.0, y), Vector2(width - 4.0, y), WALL_EDGE_COLOR, 2.0)
