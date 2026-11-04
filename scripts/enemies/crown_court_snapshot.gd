class_name CrownCourtSnapshot
extends RefCounted

const NUMBERS := ["version", "state", "attack_kind", "remaining", "elapsed", "cycle", "step_index", "turn_from", "turn_to", "edict_angle", "guard_remaining", "guard_delay"]
const FLAGS := ["combo", "portal_combo", "verdict_hit", "portal_followup", "legacy_sequence"]
const VECTORS := ["facing", "origin", "portal_a", "portal_b"]

static func valid(saved: Dictionary) -> bool:
	if not ImperialRetinue.valid(saved.get("retinue", {})): return false
	for key in NUMBERS:
		if saved.has(key) and not SnapshotValues.is_number(saved[key]): return false
	for key in VECTORS:
		if saved.has(key) and not SnapshotValues.is_vector(saved[key]): return false
	for key in FLAGS:
		if saved.has(key) and not saved[key] is bool: return false
	if saved.has("needle_rays"):
		if not saved.needle_rays is Array: return false
		for ray in saved.needle_rays:
			if not SnapshotValues.is_vector(ray): return false
	for key in ["shots", "lances", "needles"]:
		if saved.has(key) and not saved[key] is Array: return false
		for entry in saved.get(key, []):
			if not entry is Dictionary or not SnapshotValues.is_vector(entry.get("position")) or not SnapshotValues.is_vector(entry.get("velocity")): return false
			if not SnapshotValues.is_number(entry.get("life")) or not SnapshotValues.is_number(entry.get("damage")): return false
			if entry.has("source") and not entry.source is String: return false
	return true

static func capture(encounter: CrownCourtEncounter) -> Dictionary:
	var saved := {"version": encounter.SAVE_VERSION, "state": int(encounter.state), "attack_kind": int(encounter.attack_kind), "shots": encounter.shots.save_data(), "lances": encounter.lances.save_data()}
	saved.merge({"needles": encounter.needles.save_data(), "needle_rays": []})
	saved["retinue"] = encounter.retinue.save_data() if encounter.retinue != null else {}
	for ray in encounter.needle_rays: saved.needle_rays.append(SnapshotValues.vector_data(ray))
	for key in NUMBERS:
		if not saved.has(key): saved[key] = encounter.get(key)
	for key in VECTORS: saved[key] = SnapshotValues.vector_data(encounter.get(key))
	for key in FLAGS: saved[key] = encounter.get(key)
	return saved

static func restore(encounter: CrownCourtEncounter, saved: Dictionary) -> void:
	encounter.cancel(false)
	var version := int(saved.get("version", 0))
	if version not in [1, 2, encounter.SAVE_VERSION]: return
	encounter.state = clampi(int(saved.get("state", 0)), 0, CrownCourtEncounter.State.REPOSITION) as CrownCourtEncounter.State
	encounter.attack_kind = clampi(int(saved.get("attack_kind", 0)), 0, 2) as CrownCourtEncounter.Attack
	encounter.cycle = maxi(int(saved.get("cycle", 0)), 0)
	encounter.step_index = clampi(int(saved.get("step_index", 0)), 0, 6)
	encounter.remaining = clampf(float(saved.get("remaining", 0)), 0, 3)
	encounter.elapsed = maxf(float(saved.get("elapsed", 0)), 0)
	for key in ["turn_from", "turn_to", "edict_angle"]: encounter.set(key, float(saved.get(key, 0)))
	for key in VECTORS: encounter.set(key, SnapshotValues.read_vector(saved.get(key, [0, 0])))
	for key in FLAGS: encounter.set(key, bool(saved.get(key, false)))
	if version == 1: encounter.legacy_sequence = true
	encounter.guard_remaining = clampf(float(saved.get("guard_remaining", 0)), 0, encounter.profile.turn_seconds)
	encounter.guard_delay = clampf(float(saved.get("guard_delay", 0)), 0, encounter.profile.recovery_settle_seconds)
	encounter.shots.restore(saved.get("shots", []))
	encounter.lances.restore(saved.get("lances", []))
	encounter.needles.restore(saved.get("needles", []))
	if encounter.retinue != null:
		encounter.retinue.restore(saved.get("retinue", {}))
		if version < 3:
			encounter.retinue.cancel()
			encounter.retinue.used = true
	for ray in saved.get("needle_rays", []):
		if encounter.needle_rays.size() >= encounter.profile.needle_count(): break
		encounter.needle_rays.append(SnapshotValues.read_vector(ray))
	encounter.enemy.special_phase = Enemy.SpecialPhase.COOLDOWN
	encounter.enemy.boss_radial_volleys_remaining = 0
	encounter.enemy.boss_phase_burst_fired = true
	if encounter.enemy.dying: encounter.cancel()
	encounter.sync_visual()
	encounter.queue_redraw()
