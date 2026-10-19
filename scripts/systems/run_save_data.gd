class_name RunSaveData
extends RefCounted

const DICTIONARIES := ["player", "items", "relics", "telemetry", "rewards", "story"]
const ARRAYS := ["weapons", "owned_weapons", "enemies", "loot", "acid", "offers", "weapon_runtime", "player_projectiles", "upgrades", "horde_waves", "burst_times", "elite_times", "elite_counts"]
const RECORD_ARRAYS := ["weapons", "enemies", "loot", "acid", "weapon_runtime", "player_projectiles"]


static func normalize(value: Variant) -> Dictionary:
	if not value is Dictionary or not value.has("wave") or not value.get("player") is Dictionary or not _valid_values(value):
		return {}
	for key in DICTIONARIES:
		if value.has(key) and not value[key] is Dictionary:
			return {}
	for key in ARRAYS:
		if value.has(key) and not value[key] is Array:
			return {}
	for key in RECORD_ARRAYS:
		for entry in value.get(key, []):
			if not entry is Dictionary:
				return {}
	if not _valid_structure(value):
		return {}
	var result: Dictionary = value.duplicate(true)
	for section in ["stats", "presentation", "status_effects", "dash"]:
		if result.player.has(section) and not result.player[section] is Dictionary:
			return {}
	for key in ["offers", "upgrades"]:
		for entry in result.get(key, []):
			if not entry is Dictionary and not entry is String:
				return {}
	for offer in result.get("offers", []):
		if offer is Dictionary and offer.has("id"):
			offer.id = weapon_id(str(offer.id))
	for upgrade in result.get("upgrades", []):
		if upgrade is Dictionary and upgrade.has("stat"):
			upgrade.stat = {"move_speed": "speed_bonus", "attack_interval": "attack_speed", "damage": "damage_bonus"}.get(str(upgrade.stat), str(upgrade.stat))
	return result


static func weapon_id(id: String) -> String:
	return {"floss": "floss_whip", "drill": "turbo_drill"}.get(id, id)


static func _valid_values(value: Variant) -> bool:
	if value is float:
		return is_finite(value)
	if value is Dictionary:
		for child in value.values():
			if not _valid_values(child):
				return false
	elif value is Array:
		for child in value:
			if not _valid_values(child):
				return false
	return true


static func _numeric_values(value: Dictionary) -> bool:
	for entry in value.values():
		if not entry is int and not entry is float:
			return false
	return true


static func _containers(value: Dictionary, dictionaries: Array, arrays: Array) -> bool:
	for key in dictionaries:
		if value.has(key) and not value[key] is Dictionary:
			return false
	for key in arrays:
		if value.has(key) and not value[key] is Array:
			return false
	return true


static func _valid_structure(value: Dictionary) -> bool:
	# Check container contracts before passing JSON values to typed subsystem APIs.
	var player: Dictionary = value.player
	if not _containers(player, ["dash"], []): return false
	var dash: Dictionary = player.get("dash", {})
	if not _containers(dash, [], ["direction", "last_direction"]): return false
	for key in ["direction", "last_direction"]:
		if dash.has(key):
			if dash[key].size() != 2: return false
			for coordinate in dash[key]:
				if not (coordinate is float or coordinate is int): return false
	for key in ["charge", "cooldown", "recovery", "remaining"]:
		if dash.has(key) and not (dash[key] is float or dash[key] is int): return false
	if not _containers(player, ["stats", "presentation", "status_effects"], ["position"]) or not _numeric_values(player.get("stats", {})):
		return false
	for state in player.get("status_effects", {}).values():
		if not state is Dictionary or not _numeric_values(state):
			return false
	var items: Dictionary = value.get("items", {})
	if not _containers(items, ["owned", "cooldowns"], ["puddles"]) or not _numeric_values(items.get("owned", {})) or not _numeric_values(items.get("cooldowns", {})):
		return false
	for puddle in items.get("puddles", []):
		if not puddle is Dictionary or not _numeric_values(puddle):
			return false
	var rewards: Dictionary = value.get("rewards", {})
	if not _containers(rewards, [], ["pending_chests", "pending_relics"]) or not _containers(value.get("relics", {}), [], ["owned"]):
		return false
	for chest in rewards.get("pending_chests", []):
		if not chest is Dictionary or not _containers(chest, [], ["choices"]):
			return false
	var telemetry: Dictionary = value.get("telemetry", {})
	var metric_maps := ["status_damage", "status_applications", "wave_status_damage", "wave_status_applications", "weapon_damage", "proc_damage", "enchantment_support", "wave_enchantment_support", "wave_gold_sources", "wave_shop_spending"]
	if not _containers(telemetry, metric_maps, ["wave_history", "damage_events", "kill_events", "taken_events"]):
		return false
	for key in metric_maps:
		if not _numeric_values(telemetry.get(key, {})):
			return false
	for key in ["weapons", "offers", "player_projectiles"]:
		for entry in value.get(key, []):
			if entry is Dictionary and not _containers(entry, ["rolls", "upgrades"], ["affixes", "hits", "orbit_hits"]):
				return false
	for entry in value.get("player_projectiles", []):
		for key in ["id", "x", "y", "dx", "dy", "damage"]:
			if not entry.has(key):
				return false
	for entry in value.get("weapon_runtime", []):
		if not _containers(entry, ["motion"], []):
			return false
	for entry in value.get("enemies", []):
		if not _containers(entry, ["affix_effects"], ["position", "direction", "boss_dash_end", "boss_dash_origin", "inflicted_statuses"]):
			return false
	for entry in value.get("loot", []):
		if not _containers(entry, ["reward_data"], ["position"]):
			return false
	for entry in value.get("acid", []):
		if not _containers(entry, [], ["position", "direction", "inflicted_statuses"]):
			return false
	return _valid_scalars(value)


static func _valid_scalars(value: Variant, field: String = "") -> bool:
	# These fields are numeric maps or arrays; other primitive fields may be bools/IDs.
	const NUMBER_ARRAYS := ["position", "direction", "boss_dash_end", "boss_dash_origin", "horde_waves", "burst_times", "elite_times", "elite_counts", "hits", "orbit_hits", "kill_events"]
	const NUMBER_FIELDS := ["wave", "xp", "xp_goal", "level", "coins", "duration", "remaining", "spawn_cooldown", "burst_index", "elite_index", "elite_time", "reroll_cost", "tier", "price", "invested_coins", "affix_slots", "x", "y", "dx", "dy", "damage", "health", "timer", "phase", "boss_move", "cooldown", "focus_target", "focus_hits", "focus_time", "pending_levels", "level_rerolls", "step", "scrap_coins"]
	if field in NUMBER_ARRAYS:
		if not value is Array:
			return false
		for entry in value:
			if not entry is int and not entry is float:
				return false
		return true
	if field in NUMBER_FIELDS:
		return value is int or value is float
	if value is Dictionary:
		for key in value:
			if not _valid_scalars(value[key], str(key)):
				return false
	elif value is Array:
		for entry in value:
			if not _valid_scalars(entry):
				return false
	return true
