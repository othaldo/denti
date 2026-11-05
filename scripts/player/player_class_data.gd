class_name PlayerClassData
extends Resource

@export var id: StringName
@export var rules_version: int = 1
@export var display_name: String
@export_multiline var description: String
@export var root_capacity: int = 6
@export var starting_stats: Dictionary = {}
@export var stat_rules: Array[ClassStatRuleData] = []
@export var conversions: Array[ClassStatConversionData] = []
# Empty permits every weapon. Otherwise at least one explicit role must match.
@export var allowed_weapon_roles: Array[StringName] = []
@export var preferred_tags: Array[StringName] = []
@export var dash_override: DashData

func rule_for(stat: StringName) -> ClassStatRuleData:
	for rule in stat_rules:
		if rule.stat == stat: return rule
	return null

func valid() -> bool:
	if id == &"" or display_name.is_empty() or rules_version < 1 or root_capacity < 1: return false
	for role in allowed_weapon_roles:
		if role not in WeaponRoles.ALL: return false
	for key in starting_stats:
		var value: Variant = starting_stats[key]
		if StringName(str(key)) not in PlayerStatKeys.ALL or not (value is float or value is int) or not is_finite(float(value)): return false
	var seen: Array[StringName] = []
	for rule in stat_rules:
		if rule == null or not rule.valid() or rule.stat in seen: return false
		seen.append(rule.stat)
	for conversion in conversions:
		if conversion == null or not conversion.valid() or _cyclic(conversion.target_stat, []): return false
	if dash_override != null:
		for key in ["capacity", "cost", "distance", "duration", "recharge_rate", "cooldown", "contact_damage_multiplier"]:
			if not is_finite(float(dash_override.get(key))) or float(dash_override.get(key)) <= 0.0: return false
		if not is_finite(dash_override.recovery_delay) or dash_override.recovery_delay < 0.0 or not is_finite(dash_override.max_stamina_bonus) or dash_override.max_stamina_bonus < 0.0: return false
		if dash_override.capacity < dash_override.cost: return false
	return true

func _cyclic(stat: StringName, path: Array[StringName]) -> bool:
	if stat in path: return true
	var next := path.duplicate()
	next.append(stat)
	for conversion in conversions:
		if conversion == null: return true
		if conversion.target_stat == stat and _cyclic(conversion.source_stat, next): return true
	return false

func effective(values: Dictionary, stat: StringName) -> float:
	var amount := float(values.get(str(stat), 0.0))
	for conversion in conversions:
		if conversion.target_stat == stat:
			var source := effective(values, conversion.source_stat)
			amount += (maxf(source, 0.0) if conversion.positive_only else source) * conversion.factor
	var rule := rule_for(stat)
	amount = rule.effective(amount) if rule != null else amount
	return maxf(amount, 1.0) if stat == &"max_health" else amount

func dash_config() -> DashData:
	return dash_override if dash_override != null else preload("res://data/player/dash.tres")
