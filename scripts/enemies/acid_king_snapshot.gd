class_name AcidKingSnapshot
extends RefCounted

static func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

static func _vector(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _number(value[0]) and _number(value[1])

static func valid(saved: Dictionary) -> bool:
	for key in ["version", "state", "remaining", "elapsed", "cycle", "attack_kind", "shift_index", "axis"]:
		if saved.has(key) and not _number(saved[key]): return false
	for key in ["anchor", "aim"]:
		if saved.has(key) and not _vector(saved[key]): return false
	for key in ["pending", "fields", "rows", "projectiles"]:
		if saved.has(key) and not saved[key] is Array: return false
		for entry in saved.get(key, []):
			if not entry is Dictionary: return false
			if key == "projectiles":
				if not _vector(entry.get("position")) or not _vector(entry.get("velocity")): return false
				for name in ["life", "damage"]:
					if not _number(entry.get(name)): return false
				if entry.has("source") and not entry.source is String: return false
			else:
				if not _vector(entry.get("at")): return false
				if key == "rows":
					if not _vector(entry.get("direction")) or not _number(entry.get("delay")): return false
					if not entry.get("fired") is bool or not entry.get("hit") is bool: return false
				else:
					if not _vector(entry.get("half_size")): return false
					if entry.half_size[0] <= 0 or entry.half_size[1] <= 0: return false
					if key == "fields":
						for name in ["life", "duration", "age", "cooldown"]:
							if not _number(entry.get(name)): return false
	return true

static func capture(encounter: AcidKingEncounter) -> Dictionary:
	var saved := {"version": encounter.SAVE_VERSION, "state": int(encounter.state), "remaining": encounter.remaining, "elapsed": encounter.elapsed, "cycle": encounter.cycle, "attack_kind": int(encounter.attack_kind), "shift_index": encounter.shift_index, "axis": encounter.axis, "anchor": SnapshotValues.vector_data(encounter.anchor), "aim": SnapshotValues.vector_data(encounter.aim), "pending": [], "fields": [], "rows": [], "projectiles": encounter.volley.save_data()}
	for key in ["pending", "fields", "rows"]:
		for raw: Dictionary in encounter.get(key):
			var entry := raw.duplicate()
			for name in ["at", "half_size", "direction"]:
				if entry.has(name): entry[name] = SnapshotValues.vector_data(entry[name])
			saved[key].append(entry)
	return saved

static func restore(encounter: AcidKingEncounter, saved: Dictionary) -> void:
	encounter.cancel()
	if int(saved.get("version", 0)) != encounter.SAVE_VERSION: return
	encounter.state = clampi(int(saved.get("state", 0)), 0, 8) as AcidKingEncounter.State
	encounter.cycle = maxi(int(saved.get("cycle", 0)), 0)
	encounter.attack_kind = clampi(int(saved.get("attack_kind", 0)), 0, 2) as AcidKingEncounter.Attack
	encounter.shift_index = clampi(int(saved.get("shift_index", 0)), 0, encounter.profile.shifts)
	encounter.axis = clampi(int(saved.get("axis", 0)), 0, 1)
	encounter.anchor = SnapshotValues.read_vector(saved.get("anchor", [0, 0]))
	encounter.aim = SnapshotValues.read_vector(saved.get("aim", [1, 0]))
	var profile := encounter.profile
	var limit: float = [profile.approach_seconds, profile.warning_seconds, maxf(profile.flow_seconds, profile.shift_flow_seconds), profile.shift_warning_seconds, profile.stomp_warning_seconds, encounter._stomp_duration(), profile.recall_seconds, profile.open_seconds, profile.recovery_seconds][encounter.state]
	encounter.remaining = clampf(float(saved.get("remaining", 0)), 0, limit)
	encounter.elapsed = maxf(float(saved.get("elapsed", 0)), 0)
	for key in ["pending", "fields", "rows"]:
		var entries: Array = encounter.get(key)
		var maximum := profile.rows(2) if key == "rows" else encounter.MAX_FIELDS
		for raw: Dictionary in saved.get(key, []):
			if entries.size() >= maximum: break
			var entry := raw.duplicate()
			for name in ["at", "half_size", "direction"]:
				if entry.has(name): entry[name] = SnapshotValues.read_vector(entry[name])
			if key == "fields":
				entry.life = clampf(entry.life, 0, 12)
				entry.cooldown = clampf(entry.cooldown, 0, profile.field_tick_seconds)
			entries.append(entry)
	encounter.volley.restore(saved.get("projectiles", []))
	encounter.enemy.special_phase = Enemy.SpecialPhase.COOLDOWN
	encounter.enemy.boss_radial_volleys_remaining = 0
	encounter.enemy.boss_phase_burst_fired = true
	if encounter.enemy.dying: encounter.cancel()
	encounter.sync_visual()
	encounter.queue_redraw()
