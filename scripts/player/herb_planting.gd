class_name HerbPlanting
extends RefCounted
## Planting animation of the Kräuterzahn, the counterpart of NecrodentSummon:
## the staff jabs into the ground, a glowing seed arcs from its head to the
## spot, the soil bursts open and leaves sparkle while the herb grows.

const CAST_SECONDS := 0.42
## Seed flight from the staff head to the ground, part of the growth time.
const SEED_SECONDS := 0.2
const SOIL := Color("5a3a22")
const SOIL_LIGHT := Color("9a6a3e")
const SEED := Color(0.62, 0.95, 0.45)


## Staff jab strength (0..1) for the remaining cast time.
static func plunge(time_left: float) -> float:
	if time_left <= 0.0: return 0.0
	var elapsed := CAST_SECONDS - time_left
	return smoothstep(0.0, 0.12, elapsed) * (1.0 - smoothstep(0.18, CAST_SECONDS, elapsed))


## Glowing seed with a short trail on its arc from the staff head to the ground.
static func draw_seed(canvas: Node2D, tip: Vector2, ground: Vector2, progress: float, color: Color) -> void:
	if progress <= 0.0 or progress >= 1.0: return
	var apex := tip.lerp(ground, 0.5) + Vector2(0, -28.0)
	var seed_color := color if color.a > 0.0 else SEED
	for step in 5:
		var along := maxf(progress - step * 0.06, 0.0)
		var at := _arc(tip, apex, ground, along)
		var fade := 1.0 - step / 5.0
		canvas.draw_circle(at, lerpf(4.5, 1.5, step / 4.0), Color(seed_color, 0.75 * fade), true, -1.0, true)
	var head := _arc(tip, apex, ground, progress)
	canvas.draw_circle(head, 3.0, Color(1, 1, 0.9, 0.95), true, -1.0, true)


## Soil burst and leaf sparkles at the planting spot; `rise` runs 0..1.
static func draw_sprout(canvas: Node2D, at: Vector2, rise: float, color: Color, seed: int) -> void:
	if rise <= 0.0 or rise >= 1.0: return
	var open := smoothstep(0.0, 0.35, rise)
	var fade := 1.0 - smoothstep(0.55, 1.0, rise)
	var width := lerpf(8.0, 22.0, open)
	canvas.draw_set_transform(at, 0.0, Vector2(1.0, 0.4))
	canvas.draw_circle(Vector2.ZERO, width, Color(SOIL, 0.8 * fade), true, -1.0, true)
	canvas.draw_arc(Vector2.ZERO, width, 0.0, TAU, 20, Color(SOIL_LIGHT, 0.9 * fade), 2.0, true)
	canvas.draw_set_transform(Vector2.ZERO)
	var leaf := color if color.a > 0.0 else SEED
	for crumb in 7:
		var angle := (crumb + 0.37 * seed) * TAU / 7.0
		var ray := Vector2(cos(angle), sin(angle) * 0.4)
		var height := sin(PI * minf(rise * 1.3, 1.0)) * (9.0 + (crumb + seed) % 3 * 5.0)
		var spot := at + ray * width * (0.8 + rise * 0.7) + Vector2.UP * height
		if crumb % 3 == 0:
			canvas.draw_circle(spot, lerpf(2.6, 1.0, rise), Color(leaf, fade), true, -1.0, true)
		else:
			canvas.draw_circle(spot, lerpf(2.2, 0.8, rise), Color(SOIL_LIGHT, fade), true, -1.0, true)


static func _arc(from: Vector2, apex: Vector2, to: Vector2, along: float) -> Vector2:
	return from.lerp(apex, along).lerp(apex.lerp(to, along), along)
