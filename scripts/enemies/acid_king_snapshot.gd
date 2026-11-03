class_name AcidKingSnapshot
extends RefCounted

static func _number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))

static func _vector(value: Variant) -> bool:
	return value is Array and value.size() == 2 and _number(value[0]) and _number(value[1])

static func valid(saved: Dictionary) -> bool:
	if not KingPressureTrial.valid(saved.get("pressure", {})): return false
	for key in ["version", "state", "remaining", "elapsed", "cycle", "attack_kind", "shift_index", "axis", "stomp_index", "stomp_total"]:
		if saved.has(key) and not _number(saved[key]): return false
	for key in ["anchor", "aim", "spit_origin"]:
		if saved.has(key) and not _vector(saved[key]): return false
	if saved.has("spit_rays"):
		if not saved.spit_rays is Array: return false
		for ray in saved.spit_rays:
			if not _vector(ray): return false
	for key in ["pending", "fields", "rows", "projectiles", "spit_projectiles"]:
		if saved.has(key) and not saved[key] is Array: return false
		for entry in saved.get(key, []):
			if not entry is Dictionary: return false
			if key in ["projectiles", "spit_projectiles"]:
				if not _vector(entry.get("position")) or not _vector(entry.get("velocity")): return false
				for name in ["life", "damage"]:
					if not _number(entry.get(name)): return false
				if entry.has("source") and not entry.source is String: return false
			else:
				if not _vector(entry.get("at")): return false
				if entry.has("half_span") and not _number(entry.half_span): return false
				if entry.has("circle_radius") and not _number(entry.circle_radius): return false
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
	saved.merge({"spit_origin": SnapshotValues.vector_data(encounter.spit_origin), "spit_rays": [], "spit_projectiles": encounter.spit.save_data(), "stomp_index": encounter.stomp_index, "stomp_total": encounter.stomp_total})
	saved["pressure"] = encounter.pressure.save_data() if encounter.pressure != null else {}
	for ray in encounter.spit_rays: saved.spit_rays.append(SnapshotValues.vector_data(ray))
	for key in ["pending", "fields", "rows"]:
		for raw: Dictionary in encounter.get(key):
			var entry := raw.duplicate()
			for name in ["at", "half_size", "direction"]:
				if entry.has(name): entry[name] = SnapshotValues.vector_data(entry[name])
			saved[key].append(entry)
	return saved

static func restore(encounter: AcidKingEncounter, saved: Dictionary) -> void:
	encounter.cancel()
	var version := int(saved.get("version", 0))
	if version not in [1, 2, encounter.SAVE_VERSION]: return
	encounter.state = clampi(int(saved.get("state", 0)), 0, AcidKingEncounter.State.PURSUE if version == 1 else AcidKingEncounter.State.CHASE_STOMP) as AcidKingEncounter.State
	encounter.cycle = maxi(int(saved.get("cycle", 0)), 0)
	encounter.attack_kind = clampi(int(saved.get("attack_kind", 0)), 0, 2) as AcidKingEncounter.Attack
	encounter.shift_index = clampi(int(saved.get("shift_index", 0)), 0, encounter.profile.shifts)
	encounter.axis = clampi(int(saved.get("axis", 0)), 0, 1)
	encounter.anchor = SnapshotValues.read_vector(saved.get("anchor", [0, 0]))
	encounter.aim = SnapshotValues.read_vector(saved.get("aim", [1, 0]))
	var profile := encounter.profile
	encounter.stomp_total = clampi(int(saved.get("stomp_total", 1)), 1, profile.stomp_sequences)
	encounter.stomp_index = clampi(int(saved.get("stomp_index", 0)), 0, encounter.stomp_total)
	encounter.spit_origin = SnapshotValues.read_vector(saved.get("spit_origin", SnapshotValues.vector_data(encounter.enemy.global_position)))
	for ray in saved.get("spit_rays", []):
		if encounter.spit_rays.size() >= profile.spit_count(): break
		encounter.spit_rays.append(SnapshotValues.read_vector(ray))
	var limit: float = [profile.approach_seconds, profile.warning_seconds, maxf(profile.flow_seconds, profile.shift_flow_seconds), profile.shift_warning_seconds, encounter.stomp_warning_duration(saved.get("rows", [])), encounter._stomp_duration(saved.get("rows", [])), profile.recall_seconds, profile.open_seconds, profile.recovery_seconds, profile.pursuit_seconds, profile.spit_warning_seconds, profile.stomp_chase_seconds][encounter.state]
	# Never shorten an already announced warning when a new difficulty profile
	# accelerates future stomps. Legacy warnings were at most 1.4 seconds.
	if encounter.state == AcidKingEncounter.State.WARN_STOMP: limit = maxf(limit, clampf(float(saved.get("remaining", 0)), 0, 2.0))
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
			if key == "rows" and entry.has("half_span"): entry.half_span = clampf(float(entry.half_span), 1, profile.stomp_half_span)
			if key == "rows" and entry.has("circle_radius"): entry.circle_radius = clampf(float(entry.circle_radius), 0, profile.stomp_near_radius)
			entries.append(entry)
	encounter.volley.restore(saved.get("projectiles", []))
	encounter.spit.restore(saved.get("spit_projectiles", []))
	if encounter.pressure != null:
		encounter.pressure.restore(saved.get("pressure", {}))
		if version < 3:
			encounter.pressure.used = true
			encounter.pressure.state = KingPressureTrial.State.FINISHED
	encounter.enemy.special_phase = Enemy.SpecialPhase.COOLDOWN
	encounter.enemy.boss_radial_volleys_remaining = 0
	encounter.enemy.boss_phase_burst_fired = true
	if encounter.enemy.dying: encounter.cancel()
	encounter.sync_visual()
	encounter.queue_redraw()
