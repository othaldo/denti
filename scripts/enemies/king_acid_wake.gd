class_name KingAcidWake
extends Node2D
## The beam leaves a bounded, fixed floor hazard after its firing animation.

var encounter: AcidKingEncounter
var streams: Array[Dictionary] = []
var legacy := false

func _ready() -> void:
	z_index = 1
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	texture_repeat = CanvasItem.TEXTURE_REPEAT_MIRROR

func add_beam(from: Vector2, to: Vector2) -> void:
	if legacy: return
	var profile := encounter.pressure.profile
	var direction := from.direction_to(to)
	var distance := from.distance_to(to)
	if distance <= profile.acid_inner_gap: return
	var arena := Rect2(Vector2.ONE * 48, encounter.enemy.target.arena.arena_size - Vector2.ONE * 96)
	for axis in 2:
		if absf(direction[axis]) < 0.0001: continue
		var edge := arena.end[axis] if direction[axis] > 0 else arena.position[axis]
		distance = minf(distance, maxf((edge - from[axis]) / direction[axis], 0))
	if distance <= profile.acid_inner_gap: return
	while streams.size() >= profile.acid_max_streams: streams.pop_front()
	streams.append({"from": from + direction * profile.acid_inner_gap, "to": from + direction * distance, "age": 0.0, "life": profile.acid_seconds, "cooldown": 0.0})
	queue_redraw()

func advance(delta: float, first: float = 0) -> void:
	var profile := encounter.pressure.profile
	for entry in streams:
		var left := minf(maxf(delta, 0), entry.life)
		var spent := first
		while left > 0.000001:
			var step := left
			if entry.age < profile.acid_arm_seconds - 0.000001: step = minf(step, profile.acid_arm_seconds - entry.age)
			elif entry.cooldown > 0.000001: step = minf(step, entry.cooldown)
			else: step = minf(step, profile.acid_tick_seconds)
			if entry.age >= profile.acid_arm_seconds - 0.000001 and entry.cooldown <= 0.000001:
				if HazardGeometry.swept_capsule(encounter.enemy.target, entry.from, entry.to, profile.beam_half_width, spent, spent + step):
					encounter.enemy.target.take_hit(encounter.enemy.attack_damage * profile.acid_damage_factor)
					entry.cooldown = profile.acid_tick_seconds
			entry.age += step
			entry.cooldown = maxf(entry.cooldown - step, 0)
			entry.life = maxf(entry.life - step, 0)
			left -= step
			spent += step
	streams = streams.filter(func(entry: Dictionary) -> bool: return entry.life > 0.000001)
	queue_redraw()

func clear() -> void:
	streams.clear()
	queue_redraw()

func save_data() -> Dictionary:
	var entries: Array = []
	for stream in streams:
		var entry := stream.duplicate()
		entry.from = SnapshotValues.vector_data(stream.from)
		entry.to = SnapshotValues.vector_data(stream.to)
		entries.append(entry)
	return {"legacy": legacy, "streams": entries}

func restore(saved: Dictionary) -> void:
	clear()
	legacy = bool(saved.get("legacy", false))
	var profile := encounter.pressure.profile
	for raw: Dictionary in saved.get("streams", []):
		if streams.size() >= profile.acid_max_streams: break
		streams.append({"from": SnapshotValues.read_vector(raw.from), "to": SnapshotValues.read_vector(raw.to), "age": maxf(float(raw.age), 0), "life": clampf(float(raw.life), 0, profile.acid_seconds), "cooldown": clampf(float(raw.cooldown), 0, profile.acid_tick_seconds)})
	queue_redraw()

static func valid(saved: Variant) -> bool:
	if not saved is Dictionary or not saved.get("legacy", false) is bool or not saved.get("streams", []) is Array: return false
	for entry in saved.get("streams", []):
		if not entry is Dictionary: return false
		for key in ["from", "to"]:
			if not AcidKingSnapshot._vector(entry.get(key)): return false
		for key in ["age", "life", "cooldown"]:
			if not AcidKingSnapshot._number(entry.get(key)): return false
	return true

func _draw() -> void:
	if encounter.enemy.health <= 0: return
	var profile := encounter.pressure.profile
	var base := global_transform.affine_inverse()
	for stream in streams:
		var alpha := clampf(stream.life / 0.7, 0, 1)
		if stream.age < profile.acid_arm_seconds:
			WarningEffects.capsule(self, stream.from, stream.to, profile.beam_half_width, Color(0.7, 0.96, 0.24, alpha), stream.age / profile.acid_arm_seconds, base)
		else:
			AcidKingVisuals.draw_stream(self, stream.from, stream.to, profile.beam_half_width * 2, alpha, stream.age, base)
