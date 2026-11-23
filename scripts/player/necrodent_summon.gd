class_name NecrodentSummon
extends RefCounted

const CAST_SECONDS := 0.52
const RISE_SECONDS := 0.34
const FIRST_DELAY := 0.16
const REVIVE_DELAY := 0.08
const STAGGER := 0.027
const JADE := Color("80f4be")
const ECTOPLASM := Color("a783cf")
const CRACK := Color("382337")


static func lift(time_left: float) -> float:
	var elapsed := CAST_SECONDS - time_left
	return smoothstep(0.0, 0.19, elapsed) * (1.0 - smoothstep(0.23, CAST_SECONDS, elapsed))


static func draw_focus(canvas: Node2D, tip: Vector2, strength: float) -> void:
	if strength <= 0.0: return
	var radius := lerpf(4.0, 11.0, strength)
	canvas.draw_circle(tip, radius, Color(JADE, 0.19 * strength), true, -1.0, true)
	canvas.draw_arc(tip, radius, -0.55, 3.2, 18, Color(JADE, 0.8 * strength), 1.4, true)
	for index in 3:
		var ray := Vector2.from_angle(index * TAU / 3.0 - 1.4)
		canvas.draw_line(tip + ray * (radius + 2.0), tip + ray * (radius + 2.0 + strength * 5.0), Color(JADE, strength), 1.4, true)


static func draw_wisp(canvas: Node2D, tip: Vector2, ground: Vector2, alpha: float) -> void:
	var bend := tip.lerp(ground, 0.43) + Vector2(25.0 if ground.x > tip.x else -25.0, -8.0)
	var points := PackedVector2Array()
	for point in 11:
		var along := point / 10.0
		points.append(tip.lerp(bend, along).lerp(bend.lerp(ground, along), along))
	canvas.draw_polyline(points, Color(ECTOPLASM, alpha * 0.42), 4.0, true)
	canvas.draw_polyline(points, Color(JADE, alpha * 0.70), 1.6, true)


static func draw_ground(canvas: Node2D, at: Vector2, rise: float, radius: float, index: int) -> void:
	var open := smoothstep(-0.36, 0.20, rise)
	var fade := open * (1.0 - smoothstep(0.47, 1.0, rise))
	if fade <= 0.0: return
	var width := radius * (0.45 + 0.55 * open)
	canvas.draw_set_transform(at, 0.0, Vector2(1.0, 0.42))
	canvas.draw_circle(Vector2.ZERO, width, Color(CRACK, 0.77 * fade), true, -1.0, true)
	canvas.draw_arc(Vector2.ZERO, width, 0.20, 2.9, 18, Color(JADE, 0.90 * fade), 2.0, true)
	canvas.draw_arc(Vector2.ZERO, width, 3.38, 6.08, 18, Color(ECTOPLASM, fade), 2.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
	if rise <= 0.0: return
	for shard in 6:
		var angle := (shard + 0.1 * index) * TAU / 6.0
		var ray := Vector2(cos(angle), sin(angle) * 0.42)
		var edge := at + ray * width * 0.9
		var end := at + ray * width * (1.0 + open * 0.42)
		var elbow := edge.lerp(end, 0.48) + Vector2(0, 2.0 * signf(ray.x))
		canvas.draw_line(edge, elbow, Color(CRACK, fade), 2.0, true)
		canvas.draw_line(elbow, end, Color(CRACK, fade), 1.2, true)
		var dust := end + ray * rise * 8.0 + Vector2.UP * sin(PI * rise) * (6.0 + shard % 3 * 4.0)
		canvas.draw_circle(dust, lerpf(2.3, 0.7, rise), Color(JADE if shard % 2 == 0 else ECTOPLASM, fade), true, -1.0, true)
