class_name ElementImpactBatch
extends Node2D
## World-space cosmetic events. Two shared draw layers; no per-hit nodes/textures.

const ATLAS: Texture2D = preload("res://assets/vfx/element_hit_splats.png")
const PROFILES: Array[ElementImpactProfile] = [
	preload("res://data/vfx/impacts/fire.tres"), preload("res://data/vfx/impacts/ice.tres"),
	preload("res://data/vfx/impacts/poison.tres"), preload("res://data/vfx/impacts/electric.tres"),
	preload("res://data/vfx/impacts/bleed.tres"), preload("res://data/vfx/impacts/wet.tres"),
]
const MAX_EVENTS := 96
const MAX_BURSTS := 32
const MERGE_SECONDS := 0.055
const MERGE_DISTANCE := 22.0

class BurstLayer extends Node2D:
	var batch: ElementImpactBatch
	func _draw() -> void:
		if is_instance_valid(batch): batch.draw_bursts(self)

var events: Array[Dictionary] = []
var burst_layer: BurstLayer
var serial := 0


func _ready() -> void:
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	set_physics_process(false)


func attach_burst_layer(before: Node) -> void:
	burst_layer = BurstLayer.new()
	burst_layer.name = "ElementImpactBursts"
	# Enemy bodies use 3, hostile projectiles 4, Denti 5. Sibling order places
	# these short bursts above enemy bodies while preserving hostile bullets.
	burst_layer.z_index = 3
	burst_layer.batch = self
	burst_layer.texture_filter = texture_filter
	before.get_parent().add_child(burst_layer)
	before.get_parent().move_child(burst_layer, before.get_index())


func _exit_tree() -> void:
	if is_instance_valid(burst_layer) and not burst_layer.is_queued_for_deletion(): burst_layer.queue_free()


static func find(source: Node) -> ElementImpactBatch:
	if source.get_parent() == null or source.get_parent().get_parent() == null: return null
	return source.get_parent().get_parent().get_node_or_null("ElementImpacts") as ElementImpactBatch


static func emit_from(source: Node, element: StringName, at: Vector2, direction: Vector2, radius: float, area: bool = false) -> bool:
	var batch := find(source)
	return batch.emit_impact(element, at, direction, radius, area) if batch != null else false


func emit_impact(element: StringName, at: Vector2, direction: Vector2, radius: float, area: bool = false) -> bool:
	var profile: ElementImpactProfile
	for candidate in PROFILES:
		if candidate.element == element:
			profile = candidate
			break
	if profile == null or not at.is_finite() or not direction.is_finite() or not is_finite(radius): return false
	radius = clampf(radius, 16.0, 240.0)
	# Rapid fans, cones and bosses combine neighboring splashes without extending
	# their life indefinitely. Damage always happens independently of this budget.
	for index in range(events.size() - 1, -1, -1):
		var event: Dictionary = events[index]
		if float(event.age) > MERGE_SECONDS: break
		if event.profile == profile and bool(event.area) == area and Vector2(event.at).distance_squared_to(at) < MERGE_DISTANCE * MERGE_DISTANCE:
			event.radius = maxf(float(event.radius), radius)
			return true
	if events.size() >= MAX_EVENTS: events.remove_at(0)
	serial += 1
	events.append({"profile": profile, "at": at, "direction": direction.normalized() if not direction.is_zero_approx() else Vector2.RIGHT,
		"radius": radius, "area": area, "age": 0.0, "phase": fmod(serial * 2.399963, TAU)})
	set_physics_process(true)
	_redraw()
	return true


func _physics_process(delta: float) -> void:
	for index in range(events.size() - 1, -1, -1):
		var event: Dictionary = events[index]
		event.age = float(event.age) + delta
		var profile: ElementImpactProfile = event.profile
		if float(event.age) >= maxf(profile.ground_duration, profile.burst_duration): events.remove_at(index)
	set_physics_process(not events.is_empty())
	_redraw()


func clear() -> void:
	events.clear()
	set_physics_process(false)
	_redraw()


func _redraw() -> void:
	queue_redraw()
	if is_instance_valid(burst_layer): burst_layer.queue_redraw()


func _draw() -> void:
	var inverse := global_transform.affine_inverse()
	for event in events:
		var profile: ElementImpactProfile = event.profile
		var age := float(event.age)
		if age >= profile.ground_duration: continue
		var radius := float(event.radius)
		var area := bool(event.area)
		var grow := 1.0 - pow(1.0 - clampf(age / (0.16 if area else 0.09), 0, 1), 3)
		var fade := 1.0 - smoothstep(profile.ground_duration * 0.45, profile.ground_duration, age)
		var scale := Vector2(lerpf(0.22, 1.0, grow), lerpf(0.16, 0.72, grow))
		var at := Vector2(event.at) + Vector2(0, minf(radius * 0.25, 12))
		if not area: at += Vector2(event.direction) * radius * 0.14 * grow
		# Stains sit below enemies and their warnings, independently of shot life.
		# The floor ellipse stays horizontal while the splat pattern varies.
		var rect := Rect2(-Vector2.ONE * radius, Vector2.ONE * radius * 2)
		draw_set_transform_matrix(inverse * Transform2D(0, at).scaled_local(scale).rotated_local(float(event.phase)))
		draw_texture_rect_region(ATLAS, rect, profile.atlas_region, Color(1, 1, 1, profile.ground_opacity * fade))
	draw_set_transform_matrix(Transform2D.IDENTITY)


func draw_bursts(canvas: CanvasItem) -> void:
	var first := maxi(events.size() - MAX_BURSTS, 0)
	var inverse := canvas.get_global_transform().affine_inverse()
	for index in range(first, events.size()):
		var event: Dictionary = events[index]
		var profile: ElementImpactProfile = event.profile
		var age := float(event.age)
		if age >= profile.burst_duration: continue
		var time := age / profile.burst_duration
		var radius := float(event.radius)
		var at := Vector2(event.at)
		var direction := Vector2(event.direction)
		var area := bool(event.area)
		var phase := float(event.phase)
		canvas.draw_set_transform_matrix(inverse * Transform2D(0, at))
		# A fast, legible contact core, followed by the slower flying material.
		if time < 0.48:
			var pulse := time / 0.48
			WeaponElementVisuals.flash(canvas, profile.element, Vector2.ZERO, radius * lerpf(0.24, 0.75, pulse), Color(1, 1, 1, (1 - pulse) * 0.85), age)
		var particle: Rect2 = WeaponElementVisuals.PREPARED.REGIONS[str(profile.element) + ":7"]
		for fragment in profile.fragments:
			var fraction := float(fragment) / maxi(profile.fragments - 1, 1)
			var angle := phase + fraction * TAU if area else direction.angle() + (fraction - 0.5) * PI * 1.15
			var offset := Vector2.from_angle(angle) * radius * (0.12 + time * (1.0 if area else 1.1))
			var lift := sin(time * PI) * profile.lift * (0.8 + float(fragment % 3) * 0.15)
			match profile.motion:
				ElementImpactProfile.Motion.EMBER: lift = time * profile.lift
				ElementImpactProfile.Motion.BUBBLE: lift = sin(time * PI * 0.65) * profile.lift
				ElementImpactProfile.Motion.ARC:
					offset *= 0.75 + sin(age * 80 + fragment) * 0.12
					lift = 0
			var point := at + offset - Vector2(0, lift)
			var spin := angle + time * 5 if profile.motion == ElementImpactProfile.Motion.SHARD else angle
			canvas.draw_set_transform_matrix(inverse * Transform2D(spin, point))
			var size := clampf(radius * 0.22, 6, 16) * lerpf(1.0, 0.45, time)
			var extent := Vector2(size, size * particle.size.y / particle.size.x)
			var opacity := (1 - time * time) * 0.95
			if profile.motion == ElementImpactProfile.Motion.ARC: opacity *= 0.6 + 0.4 * absf(sin(age * 65 + fragment))
			canvas.draw_texture_rect_region(WeaponElementVisuals.PREPARED.PROJECTILES, Rect2(-extent * 0.5, extent), particle, Color(1, 1, 1, opacity))
	canvas.draw_set_transform_matrix(Transform2D.IDENTITY)
