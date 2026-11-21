class_name SkillPuffs
extends RefCounted
## Stateless animated clouds for class skills and similar areas. Every puff,
## bubble and sparkle is derived from the cloud's age and seed, so clouds need
## no particle objects, cost nothing to save and replay identically on resume.
## All parts come from one baked atlas (tools/bake_skill_puffs.py).

const ATLAS: Texture2D = preload("res://assets/vfx/skill_puffs.png")
const PUFF_CELL := 256.0
const SMALL_CELL := 64.0
const PUFF_VARIANTS := 4
const BUBBLE := Rect2(0, 256, 64, 64)
const SPARKLE := Rect2(64, 256, 64, 64)
## Sparing graphics draw fewer puffs; gameplay radius and timing stay the same.
const ECONOMY_PUFF_SHARE := 0.6
## Lanes place one puff per this share of their width along the axis.
const LANE_SPACING := 0.55
const MAX_LANE_PUFFS := 16

static var economy := false


static func puff_region(variant: int) -> Rect2:
	return Rect2(posmod(variant, PUFF_VARIANTS) * PUFF_CELL, 0, PUFF_CELL, PUFF_CELL)


static func hash01(seed: int, index: int, salt: int) -> float:
	var n := (seed * 73856093) ^ (index * 19349663) ^ (salt * 83492791)
	n = (n ^ (n >> 13)) * 1274126177
	return float((n ^ (n >> 16)) & 0xFFFF) / 65535.0


static func seed_for(at: Vector2) -> int:
	return int(roundf(at.x * 13.0)) * 31 + int(roundf(at.y * 7.0))


## Scale and opacity of the whole cloud over its life.
static func lifecycle(style: SkillCloudStyle, age: float, remaining: float) -> Vector2:
	var grow := clampf(age / style.spawn_seconds, 0.0, 1.0)
	grow = 1.0 - pow(1.0 - grow, 3.0)
	var dissolve := 1.0 - clampf(remaining / style.fade_seconds, 0.0, 1.0)
	return Vector2(lerpf(0.45, 1.0, grow) * (1.0 + 0.15 * dissolve), grow * (1.0 - dissolve * dissolve))


static func puff_count(style: SkillCloudStyle) -> int:
	return maxi(2, roundi(style.puffs * (ECONOMY_PUFF_SHARE if economy else 1.0)))


## Draws one cloud in the canvas's local space.
static func draw_cloud(canvas: CanvasItem, at: Vector2, radius: float, style: SkillCloudStyle, age: float, remaining: float, seed: int) -> void:
	var life := lifecycle(style, age, remaining)
	if life.y <= 0.001:
		return
	var count := puff_count(style)
	# Ground shadow keeps the gas anchored to the floor.
	if style.shadow_opacity > 0.0:
		var shadow := Vector2(radius * 2.3, radius * 1.15) * life.x
		canvas.draw_set_transform(at + Vector2(0, radius * 0.18), 0.0, Vector2.ONE)
		canvas.draw_texture_rect_region(ATLAS, Rect2(-shadow * 0.5, shadow), puff_region(seed), Color(style.shadow_color, style.shadow_opacity * life.y))
	if style.edge_opacity > 0.0:
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		canvas.draw_arc(at, radius, 0.0, TAU, 40, Color(style.color, style.edge_opacity * life.y), 2.0, true)
	# Back-to-front: upper puffs are further away and drawn first.
	var order: Array[Vector2] = []
	for index in count:
		order.append(Vector2(index, _puff_offset(style, radius, age, seed, index, count).y))
	order.sort_custom(func(a: Vector2, b: Vector2) -> bool: return a.y < b.y)
	for entry in order:
		var index := int(entry.x)
		var offset := _puff_offset(style, radius, age, seed, index, count)
		var r1 := hash01(seed, index, 1)
		var r3 := hash01(seed, index, 3)
		var depth := clampf(offset.y / maxf(radius * style.spread, 1.0) * 0.5 + 0.5, 0.0, 1.0)
		var size := radius * 2.0 * style.puff_size * (0.75 + 0.45 * r3) * life.x * (1.0 + style.breathe * sin(age * 2.1 + r1 * TAU))
		# Only a slight sway: the art is lit from the top-left and must stay so.
		var spin := sin(age * 0.9 + r1 * TAU) * 0.12
		var tint := style.color.darkened(style.depth_shade * (1.0 - depth)).lightened(style.depth_shade * 0.5 * depth)
		tint.a = style.opacity * life.y * (0.8 + 0.2 * hash01(seed, index, 2))
		canvas.draw_set_transform(at + offset * life.x, spin, Vector2.ONE)
		canvas.draw_texture_rect_region(ATLAS, Rect2(-Vector2.ONE * size * 0.5, Vector2.ONE * size), puff_region(seed + index), tint)
	_draw_bubbles(canvas, at, Vector2(radius * 0.6, 0), Vector2(0, radius * 0.35), radius, style, age, seed, life)
	_draw_sparkles(canvas, at, Vector2(radius, 0), Vector2(0, radius * 0.78), style, age, seed, life)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)


static func _puff_offset(style: SkillCloudStyle, radius: float, age: float, seed: int, index: int, count: int) -> Vector2:
	var r1 := hash01(seed, index, 1)
	var r2 := hash01(seed, index, 2)
	var r3 := hash01(seed, index, 3)
	var direction := 1.0 if r3 > 0.5 else -1.0
	var angle := (float(index) + r1 * 0.6) / count * TAU + age * style.drift * direction * (0.6 + 0.4 * r2)
	# Square-root spread fills the disc evenly; the first puff stays central.
	var distance := 0.0 if index == 0 else radius * style.spread * (0.3 + 0.7 * sqrt(r2))
	var bob := sin(age * 1.3 + r1 * TAU) * radius * 0.05
	return Vector2(cos(angle) * distance, sin(angle) * distance * 0.78 - bob)


## Rising particles inside a frame: center, half-length axis, half-width
## across and a size scale. Clouds use a disc, lanes their capsule.
static func _draw_bubbles(canvas: CanvasItem, center: Vector2, axis: Vector2, across: Vector2, scale: float, style: SkillCloudStyle, age: float, seed: int, life: Vector2) -> void:
	for index in style.bubbles:
		var phase := fposmod(age / style.bubble_period + hash01(seed, index, 11), 1.0)
		var cycle := int(age / style.bubble_period + hash01(seed, index, 11))
		var along := (hash01(seed, index + cycle * 7, 12) * 2.0 - 1.0) * 0.85
		var side := (hash01(seed, index + cycle * 7, 13) * 2.0 - 1.0) * 0.6
		var rise := lerpf(0.25, -0.55, phase) * scale * (1.5 if style.rise_sparkles else 1.0)
		var point := center + axis * along + across * side + Vector2(0, rise)
		var size := lerpf(5.0, 11.0, phase) * life.x
		var color := style.bubble_color
		if style.rise_sparkles:
			# Embers: glow up, drift and fade without popping.
			point.x += sin(age * 3.0 + index * 1.7) * scale * 0.08
			color.a *= life.y * sin(phase * PI)
			var glow := size * 2.6
			canvas.draw_set_transform(point, phase * 2.0, Vector2.ONE)
			canvas.draw_texture_rect_region(ATLAS, Rect2(-Vector2.ONE * glow * 0.5, Vector2.ONE * glow), SPARKLE, color)
		elif phase < 0.88:
			# Bubbles grow, rise, then pop into a quick sparkle.
			color.a *= life.y * smoothstep(0.0, 0.15, phase)
			canvas.draw_set_transform(point, 0.0, Vector2.ONE)
			canvas.draw_texture_rect_region(ATLAS, Rect2(-Vector2.ONE * size * 0.5, Vector2.ONE * size), BUBBLE, color)
		else:
			var pop := (phase - 0.88) / 0.12
			color.a *= life.y * (1.0 - pop)
			var burst := size * (1.2 + pop)
			canvas.draw_set_transform(point, 0.0, Vector2.ONE)
			canvas.draw_texture_rect_region(ATLAS, Rect2(-Vector2.ONE * burst * 0.5, Vector2.ONE * burst), SPARKLE, color)


static func _draw_sparkles(canvas: CanvasItem, center: Vector2, axis: Vector2, across: Vector2, style: SkillCloudStyle, age: float, seed: int, life: Vector2) -> void:
	for index in style.sparkles:
		var period := 0.9 + hash01(seed, index, 21) * 0.6
		var phase := fposmod(age / period + hash01(seed, index, 22), 1.0)
		var cycle := int(age / period + hash01(seed, index, 22))
		var along := hash01(seed, index + cycle * 5, 23) * 2.0 - 1.0
		var side := hash01(seed, index + cycle * 5, 24) * 2.0 - 1.0
		var point := center + axis * along * 0.9 + across * side * 0.8
		var size := 14.0 * sin(phase * PI) * life.x
		var color := style.sparkle_color
		color.a *= life.y * sin(phase * PI)
		canvas.draw_set_transform(point, phase * 1.5, Vector2.ONE)
		canvas.draw_texture_rect_region(ATLAS, Rect2(-Vector2.ONE * size * 0.5, Vector2.ONE * size), SPARKLE, color)


## Draws puffs along the segment a-b, e.g. walls, lanes and trails. Width is the
## full gameplay width; puff count follows the length.
static func draw_lane(canvas: CanvasItem, a: Vector2, b: Vector2, width: float, style: SkillCloudStyle, age: float, remaining: float, seed: int) -> void:
	var life := lifecycle(style, age, remaining)
	var length := a.distance_to(b)
	if life.y <= 0.001 or width <= 0.0:
		return
	var direction := (b - a) / length if length > 0.001 else Vector2.RIGHT
	var normal := direction.orthogonal()
	var count := clampi(roundi(length / (width * LANE_SPACING)) + 1, 2, MAX_LANE_PUFFS)
	if economy: count = maxi(2, roundi(count * ECONOMY_PUFF_SHARE))
	var half := width * 0.5
	if style.edge_opacity > 0.0:
		canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
		canvas.draw_line(a, b, Color(style.color.lightened(0.3), style.edge_opacity * life.y), 3.0, true)
	var points: Array[Vector3] = []
	for index in count:
		var r1 := hash01(seed, index, 1)
		var r2 := hash01(seed, index, 2)
		var t := (float(index) + 0.5 * r1) / maxf(count - 1, 1) if count > 1 else 0.5
		var sway := sin(age * (0.8 + style.drift) + r1 * TAU) * half * 0.18
		var point := a.lerp(b, clampf(t, 0.0, 1.0)) + normal * ((r2 - 0.5) * half * 0.5 + sway)
		points.append(Vector3(point.x, point.y, index))
	points.sort_custom(func(p: Vector3, q: Vector3) -> bool: return p.y < q.y)
	var top := minf(a.y, b.y) - half
	var span := maxf(absf(a.y - b.y) + width, 1.0)
	for entry in points:
		var index := int(entry.z)
		var r1 := hash01(seed, index, 1)
		var r3 := hash01(seed, index, 3)
		var depth := clampf((entry.y - top) / span, 0.0, 1.0)
		var size := width * style.puff_size * 2.0 * (0.8 + 0.4 * r3) * life.x * (1.0 + style.breathe * sin(age * 2.1 + r1 * TAU))
		var tint := style.color.darkened(style.depth_shade * (1.0 - depth)).lightened(style.depth_shade * 0.5 * depth)
		tint.a = style.opacity * life.y * (0.8 + 0.2 * hash01(seed, index, 2))
		canvas.draw_set_transform(Vector2(entry.x, entry.y), sin(age * 0.9 + r1 * TAU) * 0.12, Vector2.ONE)
		canvas.draw_texture_rect_region(ATLAS, Rect2(-Vector2.ONE * size * 0.5, Vector2.ONE * size), puff_region(seed + index), tint)
	var center := (a + b) * 0.5
	_draw_bubbles(canvas, center, (b - a) * 0.5, normal * half, half * 1.6, style, age, seed, life)
	_draw_sparkles(canvas, center, (b - a) * 0.5, normal * half, style, age, seed, life)
	canvas.draw_set_transform(Vector2.ZERO, 0.0, Vector2.ONE)
