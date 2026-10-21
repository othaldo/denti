class_name CrownCourtSnapshot
extends RefCounted

const NUMBERS := ["version", "state", "attack_kind", "remaining", "elapsed", "cycle", "step_index", "turn_from", "turn_to", "edict_angle"]
const VECTORS := ["facing", "origin", "portal_a", "portal_b"]

static func _number(value: Variant) -> bool: return (value is float or value is int) and is_finite(float(value))
static func _vector(value: Variant) -> bool: return value is Array and value.size() == 2 and _number(value[0]) and _number(value[1])

static func valid(saved: Dictionary) -> bool:
	for key in NUMBERS:
		if saved.has(key) and not _number(saved[key]): return false
	for key in VECTORS:
		if saved.has(key) and not _vector(saved[key]): return false
	for key in ["combo", "verdict_hit"]:
		if saved.has(key) and not saved[key] is bool: return false
	for key in ["shots", "lances"]:
		if saved.has(key) and not saved[key] is Array: return false
		for entry in saved.get(key, []):
			if not entry is Dictionary or not _vector(entry.get("position")) or not _vector(entry.get("velocity")): return false
			if not _number(entry.get("life")) or not _number(entry.get("damage")): return false
			if entry.has("source") and not entry.source is String: return false
	return true

static func capture(encounter: CrownCourtEncounter) -> Dictionary:
	var saved := {"version": encounter.SAVE_VERSION, "state": int(encounter.state), "attack_kind": int(encounter.attack_kind), "shots": encounter.shots.save_data(), "lances": encounter.lances.save_data()}
	for key in NUMBERS:
		if not saved.has(key): saved[key] = encounter.get(key)
	for key in VECTORS: saved[key] = SnapshotValues.vector_data(encounter.get(key))
	for key in ["combo", "verdict_hit"]: saved[key] = encounter.get(key)
	return saved

static func restore(encounter: CrownCourtEncounter, saved: Dictionary) -> void:
	encounter.cancel()
	if int(saved.get("version", 0)) != encounter.SAVE_VERSION: return
	encounter.state = clampi(int(saved.get("state", 0)), 0, 9) as CrownCourtEncounter.State
	encounter.attack_kind = clampi(int(saved.get("attack_kind", 0)), 0, 2) as CrownCourtEncounter.Attack
	encounter.cycle = maxi(int(saved.get("cycle", 0)), 0)
	encounter.step_index = clampi(int(saved.get("step_index", 0)), 0, 6)
	encounter.remaining = clampf(float(saved.get("remaining", 0)), 0, 3)
	encounter.elapsed = maxf(float(saved.get("elapsed", 0)), 0)
	for key in ["turn_from", "turn_to", "edict_angle"]: encounter.set(key, float(saved.get(key, 0)))
	for key in VECTORS: encounter.set(key, SnapshotValues.read_vector(saved.get(key, [0, 0])))
	for key in ["combo", "verdict_hit"]: encounter.set(key, bool(saved.get(key, false)))
	encounter.shots.restore(saved.get("shots", []))
	encounter.lances.restore(saved.get("lances", []))
	encounter.enemy.special_phase = Enemy.SpecialPhase.COOLDOWN
	encounter.enemy.boss_radial_volleys_remaining = 0
	encounter.enemy.boss_phase_burst_fired = true
	if encounter.enemy.dying: encounter.cancel()
	encounter.sync_visual()
	encounter.queue_redraw()
