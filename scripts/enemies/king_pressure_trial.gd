class_name KingPressureTrial
extends Node2D
## The King's own locked ray breaks his shield valves. No weapon/DPS check.

signal valve_broken(at: Vector2, remaining_valves: int)
signal shield_broken(at: Vector2)
enum State { IDLE, INTRODUCTION, TRACKING, LOCKED, FIRING, RECOIL, SHATTER, EXPOSED, BLAST_WARNING, FINISHED }
var encounter: AcidKingEncounter
var profile: KingPressureData
var state := State.IDLE
var used := false
var completed_mask := 0
var trial_index := 0
var remaining := 0.0
var elapsed := 0.0
var shots := 0
var beam_hit := false
var fired := false
var aim := Vector2.DOWN
var origin := Vector2.ZERO
var destination := Vector2.ZERO
var arrival_origin := Vector2.ZERO
var anchor := Vector2.ZERO
var frame_center := Vector2.ZERO
var framing := KingPressureFraming.new()
var valves: Array[Dictionary] = []
var hit_valve := -1
var flash_remaining := 0.0
var flash_at := Vector2.ZERO
var opening_damage_remaining := 0.0

func _ready() -> void:
	z_index = 3
	texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS

func _process(_delta: float) -> void:
	if busy(): framing.follow(frame_center)

func _exit_tree() -> void:
	framing.release()

func next_trial() -> int:
	if profile == null or used or busy(): return -1
	for index in profile.health_thresholds.size():
		if not completed_mask & (1 << index) and encounter.enemy.health <= encounter.enemy.max_health * profile.health_thresholds[index] + 0.01: return index
	return -1

func pending() -> bool:
	return next_trial() >= 0

func damage_limit(backfire: bool = false) -> float:
	var enemy := encounter.enemy
	var limit := enemy.health
	if state == State.EXPOSED and not backfire: limit = minf(limit, opening_damage_remaining)
	if profile == null or used: return limit
	for index in profile.health_thresholds.size():
		if completed_mask & (1 << index): continue
		limit = minf(limit, maxf(enemy.health - enemy.max_health * profile.health_thresholds[index], 0))
	return limit

func spend_opening_damage(amount: float) -> void:
	opening_damage_remaining = maxf(opening_damage_remaining - amount, 0)

func _finish_opening() -> void:
	state = State.FINISHED
	framing.release()
	encounter.enemy.boss_damage_budget = 0
	encounter.state = AcidKingEncounter.State.RECOVERY
	encounter.remaining = encounter.profile.recovery_seconds

func valve_count() -> int:
	return maxi(2, profile.valves - (profile.health_thresholds.size() - 1 - trial_index))

func busy() -> bool:
	return state not in [State.IDLE, State.FINISHED]

func blocks_damage() -> bool:
	return pending() or busy() and state != State.EXPOSED

func remaining_valves() -> int:
	var count := 0
	for valve in valves:
		if not valve.broken: count += 1
	return count

func begin() -> void:
	if used or profile == null: return
	trial_index = next_trial()
	if trial_index < 0: return
	encounter.cancel()
	completed_mask |= 1 << trial_index
	used = completed_mask == (1 << profile.health_thresholds.size()) - 1
	state = State.INTRODUCTION
	remaining = profile.introduction_seconds
	elapsed = 0
	shots = 0
	hit_valve = -1
	beam_hit = false
	fired = false
	var enemy := encounter.enemy
	var player := enemy.target
	framing.begin(player.get_node("Camera2D"), enemy.get_viewport_rect().size)
	var visible := enemy.get_canvas_transform().affine_inverse() * enemy.get_viewport_rect()
	var top := minf(140, visible.size.y * 0.28)
	var bottom := minf(185, visible.size.y * 0.47)
	var safe := Rect2(visible.position + Vector2(60, top), visible.size - Vector2(120, top + bottom)).intersection(Rect2(Vector2.ONE * 75, player.arena.arena_size - Vector2.ONE * 150))
	var extent := profile.layout_extent.min(safe.size)
	if visible.size.y < 400: extent.x = minf(extent.x, visible.size.x * 0.46)
	var center := player.global_position.clamp(safe.position + extent * 0.5, safe.end - extent * 0.5)
	frame_center = center
	framing.follow(frame_center)
	anchor = center - Vector2(0, extent.y * 0.23)
	arrival_origin = enemy.global_position
	var positions: Array[Vector2] = [center + Vector2(-extent.x * 0.45, extent.y * 0.16), center + Vector2(extent.x * 0.45, extent.y * 0.16)]
	if valve_count() == 3: positions.append(center + Vector2(0, extent.y * 0.48))
	elif valve_count() == 4:
		positions.append(center + Vector2(-extent.x * 0.45, -extent.y * 0.44))
		positions.append(center + Vector2(extent.x * 0.45, -extent.y * 0.44))
	valves.clear()
	for at in positions: valves.append({"at": at, "broken": false})
	enemy.attack_performed.emit(&"boss_warning")
	queue_redraw()

func stance(index: int) -> Vector2:
	var at: Vector2 = valves[index].at
	var distance := anchor.distance_to(at)
	return at - anchor.direction_to(at) * minf(85, distance * 0.38)

func aligned_valve(direction: Vector2, from: Vector2) -> int:
	var best := INF
	var result := -1
	for index in valves.size():
		if valves[index].broken: continue
		var relative: Vector2 = valves[index].at - from
		var along := relative.dot(direction)
		var side := absf(relative.cross(direction))
		if along <= 0 or side > profile.valve_radius + profile.beam_half_width: continue
		if along < best:
			best = along
			result = index
	return result

func advance(delta: float) -> bool:
	if state == State.EXPOSED and damage_limit() <= 0.01: _finish_opening()
	if pending() and encounter.enemy.boss_phase_timer <= 0:
		for other: AcidKingEncounter in get_tree().get_nodes_in_group("acid_king_encounters"):
			if other != encounter and other.pressure != null and other.pressure.busy(): return true
		begin()
	if not busy(): return false
	var left := maxf(delta, 0)
	var spent := 0.0
	while left > 0.000001 and busy():
		var step := minf(left, maxf(remaining, 0))
		flash_remaining = maxf(flash_remaining - step, 0)
		if state == State.INTRODUCTION:
			encounter.enemy.global_position = arrival_origin.lerp(anchor, clampf(1 - (remaining - step) / profile.introduction_seconds, 0, 1))
		elif state == State.TRACKING:
			origin = anchor
			aim = origin.direction_to(HazardGeometry.player_at(encounter.enemy.target, spent + step))
			if aim.is_zero_approx(): aim = Vector2.DOWN
			destination = origin + aim * 2400
		elif state == State.FIRING:
			if not fired: _fire()
			if not beam_hit and HazardGeometry.swept_capsule(encounter.enemy.target, origin + aim * 30, destination, profile.beam_half_width, spent, spent + step):
				beam_hit = true
				encounter.enemy.target.take_hit(encounter.enemy.attack_damage * profile.beam_damage_factor)
		remaining = maxf(remaining - step, 0)
		elapsed += step
		spent += step
		left -= step
		if remaining <= 0.000001: _next(spent)
	if not busy(): framing.release()
	queue_redraw()
	return true

func _track() -> void:
	state = State.TRACKING
	remaining = profile.tracking_seconds
	origin = anchor
	aim = anchor.direction_to(encounter.enemy.target.global_position)
	if aim.is_zero_approx(): aim = Vector2.DOWN
	destination = origin + aim * 2400
	encounter.enemy.attack_performed.emit(&"boss_warning")

func _fire() -> void:
	fired = true
	shots += 1
	encounter.enemy.attack_performed.emit(&"boss_pulse")
	if hit_valve >= 0 and not valves[hit_valve].broken:
		valves[hit_valve].broken = true
		flash_at = valves[hit_valve].at
		flash_remaining = 0.7
		valve_broken.emit(flash_at, remaining_valves())

func _next(_seconds_in_frame: float) -> void:
	match state:
		State.INTRODUCTION: _track()
		State.TRACKING:
			state = State.LOCKED
			remaining = profile.lock_seconds
			hit_valve = aligned_valve(aim, origin)
			encounter.enemy.attack_performed.emit(&"boss_warning")
		State.LOCKED:
			state = State.FIRING
			remaining = profile.firing_seconds
			beam_hit = false
			fired = false
		State.FIRING:
			state = State.RECOIL
			remaining = profile.recoil_seconds
		State.RECOIL:
			if remaining_valves() == 0:
				state = State.SHATTER
				remaining = profile.shatter_seconds
				shield_broken.emit(anchor)
			elif shots >= valve_count() + profile.extra_attempts:
				state = State.BLAST_WARNING
				remaining = profile.blast_warning_seconds
			else: _track()
		State.SHATTER:
			state = State.EXPOSED
			remaining = profile.exposure_seconds
			var enemy := encounter.enemy
			opening_damage_remaining = enemy.max_health * profile.opening_damage_fraction
			enemy.boss_damage_budget = 0
			enemy.take_damage(enemy.max_health * profile.backfire_fraction / profile.exposure_damage_factor, null, false, &"king_backfire")
		State.EXPOSED:
			_finish_opening()
		State.BLAST_WARNING:
			encounter.spit.fire(anchor, EnemyProjectilePatterns.circle_directions(8 + remaining_valves() * 4, 0), &"king_overpressure")
			state = State.FINISHED
			encounter.state = AcidKingEncounter.State.RECOVERY
			encounter.remaining = encounter.profile.recovery_seconds

func cancel() -> void:
	framing.release()
	state = State.FINISHED if used or completed_mask > 0 else State.IDLE
	valves.clear()
	flash_remaining = 0
	queue_redraw()

func save_data() -> Dictionary:
	var objects: Array = []
	for valve in valves: objects.append({"position": SnapshotValues.vector_data(valve.at), "broken": valve.broken})
	return {"version": 3, "opening_damage_remaining": opening_damage_remaining, "used": used, "completed_mask": completed_mask, "trial_index": trial_index, "state": int(state), "remaining": remaining, "elapsed": elapsed, "shots": shots, "beam_hit": beam_hit, "fired": fired, "aim": SnapshotValues.vector_data(aim), "origin": SnapshotValues.vector_data(origin), "destination": SnapshotValues.vector_data(destination), "arrival_origin": SnapshotValues.vector_data(arrival_origin), "anchor": SnapshotValues.vector_data(anchor), "frame_center": SnapshotValues.vector_data(frame_center), "hit_valve": hit_valve, "flash_at": SnapshotValues.vector_data(flash_at), "flash_remaining": flash_remaining, "valves": objects}

func restore(saved: Dictionary) -> void:
	used = bool(saved.get("used", false))
	completed_mask = int(saved.get("completed_mask", 0)) & ((1 << profile.health_thresholds.size()) - 1)
	trial_index = clampi(int(saved.get("trial_index", 0)), 0, profile.health_thresholds.size() - 1)
	# Version 1 had one task. Preserve its current/completed task without
	# inserting new earlier shields into an existing saved battle.
	if int(saved.get("version", 0)) == 1 and used:
		completed_mask = (1 << profile.health_thresholds.size()) - 1
		trial_index = profile.health_thresholds.size() - 1
	state = clampi(int(saved.get("state", 0)), 0, State.FINISHED) as State
	remaining = clampf(float(saved.get("remaining", 0)), 0, maxf(profile.exposure_seconds, profile.tracking_seconds))
	opening_damage_remaining = clampf(float(saved.get("opening_damage_remaining", encounter.enemy.max_health * profile.opening_damage_fraction)), 0, encounter.enemy.max_health * profile.opening_damage_fraction)
	elapsed = maxf(float(saved.get("elapsed", 0)), 0)
	shots = clampi(int(saved.get("shots", 0)), 0, profile.valves + profile.extra_attempts)
	beam_hit = bool(saved.get("beam_hit", false))
	fired = bool(saved.get("fired", false))
	for key in ["aim", "origin", "destination", "arrival_origin", "anchor", "frame_center", "flash_at"]: set(key, SnapshotValues.read_vector(saved.get(key, [0, 0])))
	if not saved.has("frame_center"): frame_center = anchor
	hit_valve = clampi(int(saved.get("hit_valve", -1)), -1, profile.valves - 1)
	flash_remaining = clampf(float(saved.get("flash_remaining", 0)), 0, 0.7)
	valves.clear()
	for raw: Dictionary in saved.get("valves", []):
		if valves.size() >= profile.valves: break
		valves.append({"at": SnapshotValues.read_vector(raw.get("position", [0, 0])), "broken": bool(raw.get("broken", false))})
	hit_valve = mini(hit_valve, valves.size() - 1)
	if busy():
		framing.begin(encounter.enemy.target.get_node("Camera2D"), encounter.enemy.get_viewport_rect().size)
		framing.follow(frame_center)
	else: framing.release()
	queue_redraw()

static func valid(saved: Variant) -> bool:
	if not saved is Dictionary: return false
	for key in ["version", "opening_damage_remaining", "completed_mask", "trial_index", "state", "remaining", "elapsed", "shots", "hit_valve", "flash_remaining"]:
		if saved.has(key) and not AcidKingSnapshot._number(saved[key]): return false
	for key in ["used", "beam_hit", "fired"]:
		if saved.has(key) and not saved[key] is bool: return false
	for key in ["aim", "origin", "destination", "arrival_origin", "anchor", "frame_center", "flash_at"]:
		if saved.has(key) and not AcidKingSnapshot._vector(saved[key]): return false
	if saved.has("valves") and not saved.valves is Array: return false
	for valve in saved.get("valves", []):
		if not valve is Dictionary or not AcidKingSnapshot._vector(valve.get("position")) or not valve.get("broken") is bool: return false
	return true

func _draw() -> void:
	if busy() and not encounter.enemy.dying: KingPressureVisuals.draw(self)
