class_name ClassStatRuleData
extends Resource

# Amounts use the attribute's native units (chance is a fraction, not percent).
@export var stat: StringName
@export var gain_factor: float = 1.0
@export var penalty_factor: float = 1.0
@export var has_minimum: bool = false
@export var minimum: float = 0.0
@export var has_maximum: bool = false
@export var maximum: float = 0.0

func valid() -> bool:
	if stat == &"max_health" and has_maximum and maximum < 1.0: return false
	if stat in [&"crit_chance", &"dodge_chance"]:
		var inherited_limit := PlayerStatKeys.DEFAULT_CRIT_LIMIT if stat == &"crit_chance" else PlayerStatKeys.DEFAULT_DODGE_LIMIT
		if has_minimum and (minimum < 0 or minimum > (maximum if has_maximum else inherited_limit)): return false
		if has_maximum and (maximum < 0 or maximum > 1): return false
	return stat in PlayerStatKeys.ALL and is_finite(gain_factor) and gain_factor >= 0.0 and is_finite(penalty_factor) and penalty_factor >= 0.0 and is_finite(minimum) and is_finite(maximum) and (not has_minimum or not has_maximum or minimum <= maximum)

func contribution(amount: float) -> float:
	return amount * (gain_factor if amount >= 0.0 else penalty_factor)

func effective(raw: float) -> float:
	return clampf(raw, minimum if has_minimum else -INF, maximum if has_maximum else INF)
