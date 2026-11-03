class_name CaramelRitualPressure
extends RefCounted
## Per-heart clocks: destruction removes that heart's shots and opens a route.

var ritual: CaramelOverload
var entries: Array[Dictionary] = []
var breaks: Array[Dictionary] = []

func start() -> void:
	entries.clear()
	breaks.clear()
	for pylon in ritual.live_pylons():
		entries.append({"slot": pylon.boss_objective_slot, "at": pylon.global_position, "aim": Vector2.DOWN, "warning": false, "remaining": 0.20 + pylon.boss_objective_slot * ritual.profile.heart_stagger_seconds, "speed": pylon.global_position.distance_to(ritual.anchor) / ritual.trial().courier_arrival_seconds * (1 + maxf(ritual.profile.rank - 1, 0) * 0.2)})

func pylon_for(slot: int) -> Enemy:
	for pylon in ritual.live_pylons():
		if pylon.boss_objective_slot == slot: return pylon
	return null

func source(slot: int) -> StringName: return StringName("ritual_heart_%d" % slot)

func winding(slot: int) -> bool:
	for entry in entries:
		if entry.slot == slot: return entry.warning
	return false

func next_event() -> float:
	var seconds := INF
	for entry in entries: seconds = minf(seconds, entry.remaining)
	return seconds

func move_couriers(delta: float) -> void:
	if ritual.trial().kind != CaramelTrialData.Kind.COURIERS: return
	for entry in entries.duplicate():
		var pylon := pylon_for(entry.slot)
		if pylon == null or entry.warning: continue
		pylon.global_position = pylon.global_position.move_toward(ritual.anchor, entry.speed * delta)
		if pylon.global_position.distance_to(ritual.anchor) <= 45:
			ritual.escaped += 1
			remove(entry.slot, false)
			pylon.queue_free()

func remove(slot: int, broken: bool = true) -> void:
	for index in range(entries.size() - 1, -1, -1):
		if entries[index].slot != slot: continue
		if broken:
			breaks.append({"at": entries[index].at, "life": 0.5})
			ritual.encounter.enemy.attack_performed.emit(&"boss_pulse")
		entries.remove_at(index)
	ritual.encounter.hearts.clear_source(source(slot))

func advance(delta: float) -> void:
	for index in range(breaks.size() - 1, -1, -1):
		breaks[index].life -= delta
		if breaks[index].life <= 0: breaks.remove_at(index)
	if ritual.state != CaramelOverload.State.ACTIVE: return
	for entry in entries.duplicate():
		var pylon := pylon_for(entry.slot)
		if pylon == null:
			remove(entry.slot)
			continue
		entry.at = pylon.global_position
		entry.remaining = maxf(entry.remaining - delta, 0)
		if entry.remaining > 0.000001: continue
		if entry.warning:
			ritual.encounter.hearts.fire(entry.at, directions(entry.aim), source(entry.slot), pylon.data.radius + 8)
			entry.warning = false
			entry.remaining = ritual.profile.heart_pause_seconds
		else:
			entry.warning = true
			entry.aim = pylon.global_position.direction_to(ritual.encounter.enemy.target.global_position)
			if entry.aim.is_zero_approx(): entry.aim = Vector2.DOWN
			entry.remaining = ritual.profile.heart_warning_seconds

func directions(aim: Vector2) -> Array[Vector2]:
	var count := maxi(ritual.trial().shots_per_heart + ritual.profile.rank * 2, 1)
	return EnemyProjectilePatterns.fan_directions(aim, count, deg_to_rad(ritual.profile.heart_fan_degrees))

func clear(keep_breaks := false) -> void:
	entries.clear()
	if not keep_breaks: breaks.clear()

func save_data() -> Dictionary:
	var shots: Array = []
	for entry in entries:
		shots.append({"slot": entry.slot, "position": SnapshotValues.vector_data(entry.at), "aim": SnapshotValues.vector_data(entry.aim), "warning": entry.warning, "remaining": entry.remaining, "speed": entry.speed})
	var flashes: Array = []
	for burst in breaks: flashes.append({"position": SnapshotValues.vector_data(burst.at), "life": burst.life})
	return {"shots": shots, "breaks": flashes}

func restore(saved: Dictionary) -> void:
	clear()
	var seen: Array[int] = []
	for raw: Dictionary in saved.get("shots", []):
		var slot := clampi(int(raw.get("slot", 0)), 0, 3)
		if seen.has(slot): continue
		seen.append(slot)
		entries.append({"slot": slot, "at": SnapshotValues.read_vector(raw.get("position", [0, 0])), "aim": SnapshotValues.read_vector(raw.get("aim", [0, 1])), "warning": bool(raw.get("warning", false)), "remaining": clampf(float(raw.get("remaining", 0)), 0, maxf(ritual.profile.heart_pause_seconds, ritual.profile.heart_warning_seconds)), "speed": clampf(float(raw.get("speed", 0)), 0, 300)})
	for raw: Dictionary in saved.get("breaks", []):
		if breaks.size() >= 4: break
		breaks.append({"at": SnapshotValues.read_vector(raw.get("position", [0, 0])), "life": clampf(float(raw.get("life", 0)), 0, 0.5)})

static func valid(saved: Variant) -> bool:
	if not saved is Dictionary: return false
	for key in ["shots", "breaks"]:
		if saved.has(key) and not saved[key] is Array: return false
		for raw in saved.get(key, []):
			if not raw is Dictionary: return false
			for number in ["slot", "remaining", "speed", "life"]:
				if raw.has(number) and not (raw[number] is int or raw[number] is float): return false
			if raw.has("warning") and not raw.warning is bool: return false
			for vector in ["position", "aim"]:
				if not raw.has(vector): continue
				if not raw[vector] is Array or raw[vector].size() != 2: return false
				for coordinate in raw[vector]:
					if not (coordinate is float or coordinate is int): return false
	return true
