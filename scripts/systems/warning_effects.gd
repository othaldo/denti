class_name WarningEffects
extends RefCounted
## Shared pre-baked texture; animation changes transforms/tint, never pixels.

const ATLAS: Texture2D = preload("res://assets/vfx/attack_effects.png")
const PREPARED = preload("res://scripts/systems/prepared_warning_shapes.gd")
const RING := Rect2(1024, 992, 608, 608)
const RIPPLE := Rect2(1632, 1000, 384, 384)
const LANE_Y := 1600
static var lane_styles: Array[StyleBoxTexture] = []
const CHARGE_BODY := Rect2(1024, 1728, 64, 64)
const CHARGE_TAIL := Rect2(1088, 1728, 64, 64)
const CHARGE_HEAD := Rect2(1152, 1728, 64, 64)
const IMPACT_GLOW := Rect2(1216, 1728, 64, 64)
const IMPACT_SPARKS := Rect2(1280, 1728, 64, 64)

static func charge_impact(canvas: CanvasItem, at: Vector2, radius: float, progress: float, tint: Color = Color.WHITE) -> void:
	if radius <= 0 or tint.a <= 0: return
	var extent := radius * 32.0 / 28.0
	var rect := Rect2(at - Vector2.ONE * extent, Vector2.ONE * extent * 2)
	canvas.draw_texture_rect_region(ATLAS, rect, IMPACT_GLOW, Color(1, 0.25, 0.12, lerpf(0.45, 0.9, progress)) * tint)
	var sparks := lerpf(0.3, 0.85, progress)
	canvas.draw_texture_rect_region(ATLAS, rect, IMPACT_SPARKS, Color(1, 0.76, 0.34, sparks) * tint)

static func charge_front(path_length: float, aim_distance: float, progress: float) -> float:
	var destination := minf(aim_distance, path_length) if aim_distance > 0 else path_length
	return destination * smoothstep(0, 1, progress)

static func charge(canvas: CanvasItem, start: Vector2, end: Vector2, half_width: float, aim_distance: float, tint: Color, progress: float, base: Transform2D = Transform2D.IDENTITY, density: PackedFloat32Array = PackedFloat32Array()) -> void:
	var length := start.distance_to(end)
	if length < 0.01 or half_width <= 0 or tint.a <= 0: return
	canvas.draw_set_transform_matrix(AttackEffects.strip_transform(start, end, base))
	# A quiet, feathered footprint also discloses overshoot beyond the locked target.
	_ribbon(canvas, length, length, half_width, Color(tint, tint.a * 0.22), density, false)
	var local_aim := maxf(aim_distance - start.length(), 0.001) if aim_distance > 0 else 0.0
	var front := charge_front(length, local_aim, progress)
	if front > 0.01:
		_ribbon(canvas, front, length, half_width, Color(tint, tint.a * lerpf(0.7, 1, progress)), density, true)
	canvas.draw_set_transform_matrix(base)

static func _ribbon(canvas: CanvasItem, length: float, full_length: float, half_width: float, tint: Color, density: PackedFloat32Array, bright: bool) -> void:
	var cap := minf(28, length * 0.5)
	var head := minf(36, length * 0.5)
	var height := half_width * 2.5
	var slices := WarningVisualDensity.SLICES if density.size() == WarningVisualDensity.SLICES + 1 else 1
	canvas.draw_texture_rect_region(ATLAS, Rect2(0, -height * 0.5, cap, height), CHARGE_TAIL, Color(tint, tint.a * density[0]) if slices > 1 else tint)
	for index in slices:
		# Density samples belong to the full path, not to the current reveal length.
		var begin := maxf(cap, full_length * index / slices)
		var finish := minf(length - head, full_length * (index + 1) / slices)
		if finish <= begin: continue
		var opacity := (density[index] + density[index + 1]) * 0.5 if slices > 1 else 1.0
		canvas.draw_texture_rect_region(ATLAS, Rect2(begin, -height * 0.5, finish - begin, height), CHARGE_BODY, Color(tint, tint.a * opacity))
	# The curved nose stays readable even when overlapping bodies are attenuated.
	canvas.draw_texture_rect_region(ATLAS, Rect2(length - head, -height * 0.5, head, height), CHARGE_HEAD, Color(1, 0.79, 0.44, tint.a) if bright else tint)

static func prepare() -> void:
	if not lane_styles.is_empty(): return
	for frame in 5:
		for part in 3:
			var style := StyleBoxTexture.new()
			style.texture = ATLAS
			var x: int = [0, 16, 240][part]
			var width: int = [16, 224, 16][part]
			style.region_rect = Rect2(1024 + (frame * 256 if frame < 4 else 0) + x, LANE_Y if frame < 4 else 1664, width, 64)
			style.texture_margin_top = 8
			style.texture_margin_bottom = 8
			style.texture_margin_left = 8 if part == 0 else 0
			style.texture_margin_right = 8 if part == 2 else 0
			style.axis_stretch_horizontal = StyleBoxTexture.AXIS_STRETCH_MODE_TILE
			lane_styles.append(style)

static func _piece(canvas: CanvasItem, part: int, frame: int, rect: Rect2, tint: Color) -> void:
	if rect.size.x <= 0: return
	var style := lane_styles[frame * 3 + part]
	style.modulate_color = tint
	canvas.draw_style_box(style, rect)

static func lane(canvas: CanvasItem, start: Vector2, end: Vector2, half_width: float, tint: Color, progress: float, base: Transform2D, density: PackedFloat32Array) -> void:
	var length := start.distance_to(end)
	if length < 0.01 or half_width <= 0 or tint.a <= 0: return
	prepare()
	canvas.draw_set_transform_matrix(AttackEffects.strip_transform(start, end, base))
	var frame := clampi(int(progress * 4), 0, 3)
	tint.a *= lerpf(0.70, 1.0, progress)
	var cap := minf(12, length * 0.5)
	var y := -half_width - 4
	var height := half_width * 2 + 8
	var faded := density.size() == WarningVisualDensity.SLICES + 1
	var left := Color(tint, tint.a * density[0]) if faded else tint
	var right := Color(tint, tint.a * density[-1]) if faded else tint
	_piece(canvas, 0, frame, Rect2(-4, y, cap + 4, height), left)
	_piece(canvas, 2, frame, Rect2(length - cap, y, cap + 4, height), right)
	var middle := length - cap * 2
	if faded:
		for index in WarningVisualDensity.SLICES:
			var begin := maxf(cap, length * index / WarningVisualDensity.SLICES)
			var finish := minf(length - cap, length * (index + 1) / WarningVisualDensity.SLICES)
			var opacity := (density[index] + density[index + 1]) * 0.5
			_piece(canvas, 1, frame, Rect2(begin, y, finish - begin, height), Color(tint, tint.a * opacity))
		# Density fades the floor fill, never the warning's complete boundary.
		var reduced := false
		for opacity in density:
			if opacity < 0.999: reduced = true
		if reduced:
			_piece(canvas, 0, 4, Rect2(-4, y, cap + 4, height), tint)
			_piece(canvas, 1, 4, Rect2(cap, y, middle, height), tint)
			_piece(canvas, 2, 4, Rect2(length - cap, y, cap + 4, height), tint)
	else:
		_piece(canvas, 1, frame, Rect2(cap, y, middle, height), tint)
	canvas.draw_set_transform_matrix(base)

static func sector(canvas: CanvasItem, origin: Vector2, direction: Vector2, reach: float, half_angle: float, progress: float, active: bool, flash: bool, base: Transform2D = Transform2D.IDENTITY) -> void:
	var degrees := rad_to_deg(half_angle)
	var source := Rect2(1024, 0, 384, 480)
	var reference: float = PREPARED.FAN_REACH
	var arc_offset := 384.0
	if is_equal_approx(degrees, PREPARED.THRUST_ANGLE):
		source = Rect2(1024, 768, 448, 224)
		reference = PREPARED.THRUST_REACH
		arc_offset = 448
	elif is_equal_approx(degrees, PREPARED.EDGE_ANGLE):
		source = Rect2(1024, 480, 384, 288)
	var scale := reach / reference
	var transform := Transform2D(direction.angle(), Vector2.ONE * scale, 0, origin)
	canvas.draw_set_transform_matrix(base * transform)
	var tint := Color(1, 0.34, 0.26, 0.95 if not active or flash else 0.3)
	var rect := Rect2(Vector2(-8, -source.size.y * 0.5), source.size)
	canvas.draw_texture_rect_region(ATLAS, rect, source, tint)
	if not active or flash:
		var sweep := lerpf(0.20, 0.98, smoothstep(0, 1, progress))
		var arc := Rect2(source.position + Vector2(arc_offset, 0), source.size)
		canvas.draw_texture_rect_region(ATLAS, Rect2(rect.position * sweep, rect.size * sweep), arc, Color(1, 0.86, 0.50, 0.40 + progress * 0.45))
	canvas.draw_set_transform_matrix(base)

static func ring(canvas: CanvasItem, origin: Vector2, inner: float, outer: float, progress: float, active: bool, flash: bool) -> void:
	# Canonical ring proportions are baked from count_ring.tres.
	var scale := outer / PREPARED.RING_OUTER
	var extent := 304.0 * scale
	canvas.draw_texture_rect_region(ATLAS, Rect2(origin - Vector2.ONE * extent, Vector2.ONE * extent * 2), RING, Color(1, 0.34, 0.26, 0.95 if not active or flash else 0.3))
	if not active or flash:
		var radius := lerpf(inner + 8, outer - 8, smoothstep(0, 1, progress))
		var ripple_extent := radius * 384.0 / 352.0
		canvas.draw_texture_rect_region(ATLAS, Rect2(origin - Vector2.ONE * ripple_extent, Vector2.ONE * ripple_extent * 2), RIPPLE, Color(1, 0.86, 0.50, 0.45 + progress * 0.4))
