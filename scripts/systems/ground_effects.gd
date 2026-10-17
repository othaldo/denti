class_name GroundEffects
extends RefCounted

# All three effects share one texture/material; raster work happens offline.
const ATLAS: Texture2D = preload("res://assets/vfx/ground_effects.png")
const CELL := 384.0
const RADIUS := 176.0
enum Shape { POOL, RIPPLE, DANGER }

static func draw(canvas: CanvasItem, shape: Shape, at: Vector2, radius: float, tint: Color) -> void:
	if radius <= 0.0 or tint.a <= 0.0:
		return
	var extent := radius * CELL / (RADIUS * 2.0)
	canvas.draw_texture_rect_region(ATLAS, Rect2(at - Vector2.ONE * extent, Vector2.ONE * extent * 2.0), Rect2(CELL * shape, 0.0, CELL, CELL), tint)
