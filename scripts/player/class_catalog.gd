class_name ClassCatalog
extends RefCounted

const DEFAULT: PlayerClassData = preload("res://data/classes/good_old_molar.tres")
static var profiles: Array[PlayerClassData] = [DEFAULT]

static func by_id(id: StringName) -> PlayerClassData:
	for profile in profiles:
		if profile.id == id: return profile
	return null

static func valid_state(state: Dictionary) -> bool:
	if state.is_empty(): return true # Saves from before classes.
	if not state.get("id") is String or not state.get("version") is float and not state.get("version") is int: return false
	var profile := by_id(StringName(state.id))
	if profile == null or not profile.valid() or float(state.version) != profile.rules_version: return false
	if not state.get("raw_stats") is Dictionary: return false
	for key in state.raw_stats:
		var value: Variant = state.raw_stats[key]
		if StringName(str(key)) not in PlayerStatKeys.ALL or not (value is int or value is float) or not is_finite(float(value)): return false
	return state.raw_stats.size() == PlayerStatKeys.ALL.size()
