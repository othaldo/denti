class_name CaramelBombVolley
extends RefCounted
## A bounded set of overlapping bombs, advanced by the encounter's clock.
const MAXIMUM := 3
var encounter: CaramelEncounter
var entries: Array[Dictionary] = []
func clear() -> void: entries.clear()
func warn(at: Vector2) -> void:
	assert(entries.size() < MAXIMUM, "Caramel bomb budget exceeded")
	if entries.size() >= MAXIMUM: return
	entries.append({"origin": encounter.origin, "at": at, "age": 0.0, "launched": false})
func winding() -> bool:
	for entry in entries:
		if not entry.launched: return true
	return false
func next_event() -> float:
	var wait := INF
	var p := encounter.profile
	for entry in entries:
		wait = minf(wait, (p.windup_seconds + p.flight_seconds if entry.launched else p.windup_seconds) - entry.age)
	return maxf(wait, 0.0)
func advance(delta: float, first: float) -> void:
	var p := encounter.profile
	for index in range(entries.size() - 1, -1, -1):
		var entry := entries[index]
		var before: float = entry.age
		entry.age += delta
		if not entry.launched and entry.age >= p.windup_seconds - 0.000001:
			encounter.rig.sample(encounter.elapsed + delta, 1, 0, false)
			entry.origin = encounter.rig.projectile_origin()
			entry.launched = true
			if index == entries.size() - 1: encounter.origin = entry.origin
			encounter.enemy.attack_performed.emit(&"boss_charge")
		if entry.age >= p.windup_seconds + p.flight_seconds - 0.000001:
			var impact := first + clampf(p.windup_seconds + p.flight_seconds - before, 0, delta)
			encounter.land_bomb_at(entry.at, impact)
			entries.remove_at(index)
func save_data() -> Array:
	var result: Array = []
	for entry in entries:
		result.append({"origin": SnapshotValues.vector_data(entry.origin), "position": SnapshotValues.vector_data(entry.at), "age": entry.age, "launched": entry.launched})
	return result
func restore(saved: Array) -> void:
	clear()
	var total := encounter.profile.windup_seconds + encounter.profile.flight_seconds
	for raw: Dictionary in saved:
		if entries.size() >= MAXIMUM: break
		var age := clampf(float(raw.age), 0, total)
		entries.append({"origin": SnapshotValues.read_vector(raw.origin), "at": SnapshotValues.read_vector(raw.position), "age": age, "launched": bool(raw.launched)})
static func valid(saved: Variant) -> bool:
	if not saved is Array or saved.size() > MAXIMUM: return false
	for entry in saved:
		if not entry is Dictionary or not entry.get("launched") is bool: return false
		if not (entry.get("age") is float or entry.get("age") is int) or not is_finite(float(entry.age)) or entry.age < 0: return false
		for key in ["origin", "position"]:
			if not entry.get(key) is Array or entry[key].size() != 2: return false
			for coordinate in entry[key]:
				if not (coordinate is float or coordinate is int) or not is_finite(float(coordinate)): return false
	return true
