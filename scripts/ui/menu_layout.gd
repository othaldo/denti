class_name MenuLayout
extends RefCounted

# Correct only menu descendants; the combat canvas keeps its own scale.
static func ui_scale(viewport: Viewport) -> float:
	var transform_scale := viewport.get_screen_transform().get_scale()
	return 1.0 / clampf(minf(transform_scale.x, transform_scale.y), 0.1, 1.0)

static func stage(safe: Rect2, maximum: Vector2 = Vector2(1600, 950)) -> Rect2:
	var compact := safe.size.x < 600 or safe.size.y < 480
	var margin := Vector2(12, 12) if compact else Vector2(48, 36)
	var available := (safe.size - margin * 2).max(Vector2(1, 1))
	var extent := available.min(maximum)
	return Rect2(safe.position + (safe.size - extent) * 0.5, extent)
