class_name EnemyDeathPops
extends Node2D
## Batched "Plopp" for ordinary enemy deaths: the body swells, flashes and
## shrinks away while small pieces of its own sprite fly out. One canvas item,
## no per-death nodes, and only textures the enemy already used.

const DURATION := 0.24
const MAX_EVENTS := 48
## The body swells this much before shrinking to nothing.
const SWELL := 0.28
## Share of DURATION spent swelling.
const SWELL_SHARE := 0.3
const PIECES := 5
const ECONOMY_PIECES := 3
## Crumbs are square cut-outs of the enemy's own texture: CRUMB_REGION of its
## shorter side, drawn at CRUMB_SIZE of the enemy radius.
const CRUMB_REGION := 0.3
const CRUMB_SIZE := 0.55
## Flight from the body edge, relative to the enemy radius.
const PIECE_START := 0.55
const PIECE_DISTANCE := 1.5
const PIECE_LIFT := 0.55
const RING_WIDTH := 3.0
## Brightness of the death flash; values above one brighten the sprite.
const FLASH := Color(1.7, 1.7, 1.6)

var events: Array[Dictionary] = []
var economy := false
var serial := 0


func _ready() -> void:
	# Above enemy bodies (3), below hostile projectiles (4) and Denti (5).
	z_index = 3
	set_process(false)


static func emit_from(enemy: Enemy) -> bool:
	var game := enemy.get_parent().get_parent() if enemy.get_parent() != null else null
	var pops := game.get_node_or_null("DeathPops") as EnemyDeathPops if game != null else null
	return pops.emit(enemy) if pops != null else false


func emit(enemy: Enemy) -> bool:
	var texture := enemy.sprite.texture
	if texture == null or not enemy.global_position.is_finite(): return false
	if events.size() >= MAX_EVENTS: events.remove_at(0)
	serial += 1
	var away := enemy.hit_reaction.direction if enemy.hit_reaction.direction.is_finite() else Vector2.RIGHT
	var flip := -1.0 if enemy.sprite.flip_h else 1.0
	events.append({"texture": texture, "at": enemy.global_position + enemy.sprite.position, "scale": enemy.sprite_base_scale * Vector2(flip, 1.0),
		"tint": enemy.sprite.modulate, "radius": enemy.data.radius, "direction": away, "age": 0.0,
		"phase": fmod(serial * 2.399963, TAU)})
	set_process(true)
	queue_redraw()
	return true


func _process(delta: float) -> void:
	for index in range(events.size() - 1, -1, -1):
		events[index].age = float(events[index].age) + delta
		if float(events[index].age) >= DURATION: events.remove_at(index)
	set_process(not events.is_empty())
	queue_redraw()


func clear() -> void:
	events.clear()
	set_process(false)
	queue_redraw()


static func body_scale(time: float) -> float:
	if time < SWELL_SHARE:
		return 1.0 + SWELL * sin(time / SWELL_SHARE * PI * 0.5)
	var shrink := (time - SWELL_SHARE) / (1.0 - SWELL_SHARE)
	return (1.0 + SWELL) * (1.0 - shrink)


func _draw() -> void:
	var inverse := global_transform.affine_inverse()
	var pieces := ECONOMY_PIECES if economy else PIECES
	for event in events:
		var time := float(event.age) / DURATION
		var texture: Texture2D = event.texture
		var size := texture.get_size()
		var tint: Color = event.tint
		var at: Vector2 = event.at
		var radius := float(event.radius)
		# Crumbs fly mostly away from the last hit, drop slightly and sit below
		# the collapsing body, so the first frames stay a clean flash.
		var away: Vector2 = event.direction
		var side := minf(size.x, size.y) * CRUMB_REGION
		var crumb_extent := Vector2.ONE * radius * CRUMB_SIZE * (1.0 - time * 0.55)
		var crumb_tint := tint
		crumb_tint.a = tint.a * (1.0 - time * time)
		for piece in pieces:
			var fraction := (float(piece) + 0.5) / pieces
			var angle := away.angle() + (fraction - 0.5) * PI * 1.4 + float(event.phase) * 0.15
			var travel := radius * (PIECE_START + PIECE_DISTANCE * (1.0 - pow(1.0 - time, 2.0)) * (0.75 + 0.25 * float(piece % 2)))
			var point := at + Vector2.from_angle(angle) * travel - Vector2(0, sin(time * PI) * radius * PIECE_LIFT)
			# Each crumb cuts a different patch of the body texture.
			var patch := Vector2(0.2 + 0.3 * float(piece % 3), 0.25 + 0.25 * float((piece + 1) % 3)) * (size - Vector2.ONE * side)
			draw_set_transform_matrix(inverse * Transform2D(angle + time * 7.0, point))
			draw_texture_rect_region(texture, Rect2(-crumb_extent * 0.5, crumb_extent), Rect2(patch, Vector2.ONE * side), crumb_tint)
		# Body: quick swell with a bright flash, then collapse.
		var body := Vector2(event.scale) * body_scale(time)
		var flash := clampf(1.0 - time / SWELL_SHARE, 0.0, 1.0)
		var body_tint := tint.lerp(FLASH, flash * 0.8)
		body_tint.a = tint.a * (1.0 - smoothstep(0.7, 1.0, time))
		draw_set_transform_matrix(inverse * Transform2D(0.0, body, 0.0, at))
		draw_texture(texture, -size * 0.5, body_tint)
		# Pop ring: one thin expanding outline, gone in the first half.
		if time < 0.5:
			draw_set_transform_matrix(inverse * Transform2D(0.0, at))
			var ring := time / 0.5
			draw_arc(Vector2.ZERO, radius * lerpf(0.6, 1.5, ring), 0.0, TAU, 24, Color(1, 1, 1, (1.0 - ring) * 0.7), RING_WIDTH * (1.0 - ring * 0.5), true)
	draw_set_transform_matrix(Transform2D.IDENTITY)
