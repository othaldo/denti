class_name DentiArena
extends Node2D

const SIZE := Vector2(1920.0, 1080.0)
const VIEWPORT_PADDING := Vector2(640.0, 360.0)
const WALL_WIDTH := 36.0
const PLAYER_MARGIN := 48.0
## Extra space between an enemy's body and the wall when positions are confined.
const ENEMY_WALL_GAP := 6.0
## New enemies appear at least this far from the outer arena edge.
const SPAWN_MARGIN := WALL_WIDTH + 8.0
const FLOOR: Texture2D = preload("res://assets/environment/dental_arena_floor.png")
const VOID_COLOR := Color("30313c")
const WALL_COLOR := Color("484450")
const WALL_EDGE_COLOR := Color("827d83")
const WALL_TRIM_COLOR := Color("c9b58f")

var arena_size: Vector2 = SIZE
var floor_texture: Texture2D = FLOOR
var wall_color: Color = WALL_COLOR
var void_color: Color = VOID_COLOR
var trim_color: Color = WALL_TRIM_COLOR


func set_story_chapter(chapter: StoryChapter) -> void:
	floor_texture = chapter.floor_texture if chapter != null else FLOOR
	wall_color = chapter.wall_color if chapter != null else WALL_COLOR
	void_color = chapter.void_color if chapter != null else VOID_COLOR
	trim_color = chapter.trim_color if chapter != null else WALL_TRIM_COLOR
	queue_redraw()


## Floor area that stays `margin` away from the outer arena edge.
func inner_rect(margin: float) -> Rect2:
	return Rect2(Vector2.ONE * margin, arena_size - Vector2.ONE * margin * 2.0)


func clamp_inside(at: Vector2, margin: float) -> Vector2:
	return at.clamp(Vector2.ONE * margin, arena_size - Vector2.ONE * margin)


## Keeps an enemy body of `radius` clear of the walls.
func clamp_enemy(at: Vector2, radius: float) -> Vector2:
	return clamp_inside(at, enemy_margin(radius))


func clamp_player(at: Vector2) -> Vector2:
	return clamp_inside(at, PLAYER_MARGIN)


static func enemy_margin(radius: float) -> float:
	return WALL_WIDTH + radius + ENEMY_WALL_GAP


## World-space rectangle currently shown by the camera of `node`'s viewport.
static func visible_world_rect(node: CanvasItem) -> Rect2:
	return node.get_canvas_transform().affine_inverse() * node.get_viewport_rect()


func _ready() -> void:
	_resize()
	get_viewport().size_changed.connect(_resize)


func _resize() -> void:
	var viewport_size := get_viewport_rect().size
	arena_size = arena_size.max(Vector2(maxf(SIZE.x, viewport_size.x + VIEWPORT_PADDING.x), maxf(SIZE.y, viewport_size.y + VIEWPORT_PADDING.y)))
	queue_redraw()


func _draw() -> void:
	var viewport_size := get_viewport_rect().size
	draw_rect(Rect2(-viewport_size, arena_size + viewport_size * 2.0), void_color)
	var texture_size := floor_texture.get_size()
	var cover_scale := maxf(arena_size.x / texture_size.x, arena_size.y / texture_size.y)
	var source_size := arena_size / cover_scale
	var source_rect := Rect2((texture_size - source_size) / 2.0, source_size)
	draw_texture_rect_region(floor_texture, Rect2(Vector2.ZERO, arena_size), source_rect)
	var width := arena_size.x
	var height := arena_size.y
	draw_rect(Rect2(0.0, 0.0, width, WALL_WIDTH), wall_color)
	draw_rect(Rect2(0.0, height - WALL_WIDTH, width, WALL_WIDTH), wall_color)
	draw_rect(Rect2(0.0, WALL_WIDTH, WALL_WIDTH, height - WALL_WIDTH * 2.0), wall_color)
	draw_rect(Rect2(width - WALL_WIDTH, WALL_WIDTH, WALL_WIDTH, height - WALL_WIDTH * 2.0), wall_color)
	draw_rect(Rect2(Vector2.ZERO, arena_size), WALL_EDGE_COLOR, false, 4.0)
	draw_rect(Rect2(Vector2.ONE * WALL_WIDTH, arena_size - Vector2.ONE * WALL_WIDTH * 2.0), trim_color, false, 3.0)
	for x in range(112, int(width), 112):
		draw_line(Vector2(x, 4.0), Vector2(x, WALL_WIDTH - 5.0), WALL_EDGE_COLOR, 2.0)
		draw_line(Vector2(x, height - WALL_WIDTH + 5.0), Vector2(x, height - 4.0), WALL_EDGE_COLOR, 2.0)
	for y in range(112, int(height), 112):
		draw_line(Vector2(4.0, y), Vector2(WALL_WIDTH - 5.0, y), WALL_EDGE_COLOR, 2.0)
		draw_line(Vector2(width - WALL_WIDTH + 5.0, y), Vector2(width - 4.0, y), WALL_EDGE_COLOR, 2.0)
