class_name DentiExpressions
extends Node2D

# Matches the painted atlas in row-major order. These are presentation states,
# independent of combat damage, invulnerability and future status mechanics.
enum Face { NORMAL, BLINK, HURT, HEAL, LOW_HEALTH, BLOCK, CELEBRATE, DEAD, POISON, BLEED, DODGE, POISON_BLEED }
enum Status { POISON, BLEED }

const ATLAS: Texture2D = preload("res://assets/denti/expressions/denti_faces.png")
const BODY: Texture2D = preload("res://assets/denti/expressions/denti_body.png")
const DEFAULT_SETTINGS: DentiExpressionSettings = preload("res://data/player/denti_expressions.tres")
const CANONICAL_CANVAS := 1280.0

@export var settings: DentiExpressionSettings = DEFAULT_SETTINGS

var stats: PlayerStats
var face_sprite: Sprite2D
var current_face: Face = Face.NORMAL
var statuses: Dictionary = {}
var reaction: Face = Face.NORMAL
var reaction_remaining := 0.0
var heal_cooldown_remaining := 0.0
var healing_accumulated := 0.0
var blink_remaining := 0.0
var next_blink := 4.0
var elapsed := 0.0
var rng := RandomNumberGenerator.new()

func _ready() -> void:
	var body := get_parent() as Sprite2D
	# Normalize generated canvas sizes without changing Denti's gameplay size.
	var original_width := float(body.texture.get_width())
	body.texture = BODY
	body.scale *= original_width / float(BODY.get_width())
	scale = Vector2.ONE * float(BODY.get_width()) / CANONICAL_CANVAS
	face_sprite = Sprite2D.new()
	face_sprite.name = "Face"
	face_sprite.texture = ATLAS
	face_sprite.hframes = 4
	face_sprite.vframes = 3
	face_sprite.scale = settings.face_frame_size / Vector2(float(ATLAS.get_width()) / 4.0, float(ATLAS.get_height()) / 3.0)
	add_child(face_sprite)
	_set_face(Face.NORMAL)
	rng.randomize()
	_schedule_blink()

func configure(source: PlayerStats) -> void:
	if stats == source:
		return
	if is_instance_valid(stats):
		stats.changed.disconnect(_refresh_face)
		stats.damage_taken.disconnect(_on_damage)
		stats.healed.disconnect(_on_healed)
		stats.shield_blocked.disconnect(_on_block)
		stats.dodged.disconnect(show_dodge)
	stats = source
	if stats != null:
		stats.changed.connect(_refresh_face)
		stats.damage_taken.connect(_on_damage)
		stats.healed.connect(_on_healed)
		stats.shield_blocked.connect(_on_block)
		stats.dodged.connect(show_dodge)
	_refresh_face()

func _process(delta: float) -> void:
	var had_statuses := not statuses.is_empty()
	elapsed += delta
	reaction_remaining = maxf(reaction_remaining - delta, 0.0)
	heal_cooldown_remaining = maxf(heal_cooldown_remaining - delta, 0.0)
	blink_remaining = maxf(blink_remaining - delta, 0.0)
	for status: int in statuses.keys():
		var remaining: float = statuses[status]
		if remaining > 0.0:
			remaining -= delta
			if remaining <= 0.0:
				statuses.erase(status)
			else:
				statuses[status] = remaining
	next_blink -= delta
	if next_blink <= 0.0:
		if _base_face() == Face.NORMAL and reaction_remaining <= 0.0:
			blink_remaining = settings.blink_duration
		_schedule_blink()
	_refresh_face()
	if had_statuses or not statuses.is_empty():
		queue_redraw()

func set_status(status: Status, active: bool = true, duration: float = 0.0) -> void:
	if active:
		statuses[status] = maxf(duration, 0.0) # Zero means active until explicitly cleared.
	else:
		statuses.erase(status)
	_refresh_face()
	queue_redraw()

func has_status(status: Status) -> bool:
	return statuses.has(status)

func celebrate() -> void:
	react(Face.CELEBRATE, settings.celebrate_duration)

func show_dodge() -> void:
	react(Face.DODGE, settings.dodge_duration)

func react(expression: Face, duration: float) -> bool:
	if _base_face() == Face.DEAD or expression not in [Face.HURT, Face.HEAL, Face.BLOCK, Face.CELEBRATE, Face.DODGE]:
		return false
	if reaction_remaining > 0.0 and _priority(expression) < _priority(reaction):
		return false
	reaction = expression
	reaction_remaining = maxf(duration, 0.0)
	blink_remaining = 0.0
	_refresh_face()
	return true

func _base_face() -> Face:
	if is_instance_valid(stats) and stats.health <= 0.0:
		return Face.DEAD
	if has_status(Status.POISON) and has_status(Status.BLEED):
		return Face.POISON_BLEED
	if has_status(Status.POISON):
		return Face.POISON
	if has_status(Status.BLEED):
		return Face.BLEED
	if is_instance_valid(stats) and stats.health / maxf(stats.max_health, 1.0) <= settings.low_health_fraction:
		return Face.LOW_HEALTH
	return Face.NORMAL

func _refresh_face() -> void:
	var desired := _base_face()
	if desired != Face.DEAD:
		if reaction_remaining > 0.0:
			desired = reaction
		elif desired == Face.NORMAL and blink_remaining > 0.0:
			desired = Face.BLINK
	if current_face != desired:
		_set_face(desired)

func _set_face(expression: Face) -> void:
	current_face = expression
	face_sprite.frame = expression
	var cell_size := Vector2(float(ATLAS.get_width()) / 4.0, float(ATLAS.get_height()) / 3.0)
	face_sprite.position = settings.mouth_position - (settings.face_anchors[expression] - cell_size / 2.0) * face_sprite.scale
	queue_redraw()

func _on_damage(amount: float) -> void:
	if amount > 0.0:
		react(Face.HURT, settings.hurt_duration)

func _on_healed(amount: float, _overheal: float) -> void:
	if amount <= 0.0 or heal_cooldown_remaining > 0.0:
		return
	healing_accumulated += amount
	if healing_accumulated >= settings.minimum_heal:
		healing_accumulated = 0.0
		if react(Face.HEAL, settings.heal_duration):
			heal_cooldown_remaining = settings.heal_cooldown

func _on_block() -> void:
	react(Face.BLOCK, settings.block_duration)

func _schedule_blink() -> void:
	next_blink = rng.randf_range(settings.blink_interval.x, settings.blink_interval.y)

func _priority(expression: Face) -> int:
	return {Face.HURT: 80, Face.BLOCK: 70, Face.DODGE: 65, Face.HEAL: 60, Face.CELEBRATE: 40}.get(expression, 0)

func save_data() -> Dictionary:
	var active: Dictionary = {}
	for status: int in statuses:
		active[str(status)] = statuses[status]
	return {"statuses": active}

func restore(saved: Dictionary) -> void:
	statuses.clear()
	var active: Variant = saved.get("statuses", {})
	if active is Dictionary:
		for status in [Status.POISON, Status.BLEED]:
			if active.has(str(status)):
				statuses[status] = maxf(float(active[str(status)]), 0.0)
	# Brief reactions and blink timing are cosmetic and restart cleanly.
	reaction_remaining = 0.0
	heal_cooldown_remaining = 0.0
	healing_accumulated = 0.0
	blink_remaining = 0.0
	_refresh_face()
	queue_redraw()

func _draw() -> void:
	if current_face == Face.DEAD:
		return
	# Small attached indicators remain visible while a hit/heal face overlays a
	# persistent condition. Geometry keeps them cheap and distinct from bullets.
	if has_status(Status.POISON):
		for index in 3:
			var phase := fposmod(elapsed * 0.55 + float(index) / 3.0, 1.0)
			var center := Vector2(-430.0 + float(index) * 45.0, -20.0 - phase * 190.0)
			var radius := 28.0 + float(index) * 5.0
			draw_circle(center, radius, Color(0.43, 0.82, 0.23, 0.8))
			draw_arc(center, radius, 0.0, TAU, 16, Color(0.18, 0.39, 0.18, 0.9), 8.0, true)
			draw_circle(center + Vector2(-radius * 0.28, -radius * 0.3), radius * 0.25, Color(0.85, 1.0, 0.65))
	if has_status(Status.BLEED):
		for index in 2:
			var phase := fposmod(elapsed * 0.7 + float(index) * 0.5, 1.0)
			var center := Vector2(425.0 + float(index) * 38.0, 160.0 + phase * 150.0)
			var radius := 32.0
			var color := Color(0.78, 0.13, 0.24, 0.9)
			draw_circle(center, radius, color)
			draw_colored_polygon(PackedVector2Array([center + Vector2(-radius, 0.0), center + Vector2(0.0, -radius * 1.8), center + Vector2(radius, 0.0)]), color)
			draw_circle(center + Vector2(-8, -4), 7.0, Color(1.0, 0.56, 0.58))
