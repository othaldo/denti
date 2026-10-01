class_name UpgradeData
extends Resource

@export var display_name: String
@export_multiline var description: String
@export var stat: StringName
@export var amount: float
@export_range(0, 9) var icon_index: int = 0
@export var tier_amounts: Array[float] = []

var tier: int = 1


func with_tier(new_tier: int) -> UpgradeData:
	var result := duplicate() as UpgradeData
	result.tier = clampi(new_tier, 1, 4)
	if tier_amounts.size() == 4:
		result.amount = tier_amounts[result.tier - 1]
	result.description = result.effect_text()
	return result


func effect_text() -> String:
	match stat:
		&"damage_bonus": return "+%d %% Schaden" % roundi(amount)
		&"melee_damage": return "+%d Nahschaden (Waffenskalierung)" % roundi(amount)
		&"ranged_damage": return "+%d Fernschaden (Waffenskalierung)" % roundi(amount)
		&"armor": return "+%d Rüstung" % roundi(amount)
		&"max_health": return "+%d maximales Leben und Heilung" % roundi(amount)
		&"speed_bonus": return "+%d %% Bewegung" % roundi(amount)
		&"attack_speed": return "+%d %% Angriffstempo" % roundi(amount)
		&"regen": return "+%d Regeneration" % roundi(amount)
		&"crit_chance": return "+%d %% kritische Chance" % roundi(amount * 100.0)
		&"luck": return "+%d Glück" % roundi(amount)
	return description
