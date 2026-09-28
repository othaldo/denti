class_name DentiArena
extends Node2D

const SIZE := Vector2(1280.0, 720.0)
const FLOOR: Texture2D = preload("res://assets/environment/dental_arena_floor.png")

var arena_size: Vector2 = SIZE


func _ready() -> void:
	_resize()
	get_viewport().size_changed.connect(_resize)


func _resize() -> void:
	arena_size = get_viewport_rect().size
	queue_redraw()


func _draw() -> void:
	var texture_size := FLOOR.get_size()
	var cover_scale := maxf(arena_size.x / texture_size.x, arena_size.y / texture_size.y)
	var source_size := arena_size / cover_scale
	var source_rect := Rect2((texture_size - source_size) / 2.0, source_size)
	draw_texture_rect_region(FLOOR, Rect2(Vector2.ZERO, arena_size), source_rect)
