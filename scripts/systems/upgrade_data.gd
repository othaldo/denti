class_name UpgradeData
extends Resource

@export var display_name: String
@export_multiline var description: String
@export var stat: StringName
@export var amount: float
@export_range(0, 10) var icon_index: int = 0
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
	var type := DentiAttributes.from_key(stat)
	if type >= 0:
		var text := DentiAttributes.bonus_text(type, amount)
		if type == DentiAttributes.Type.MAX_HEALTH:
			text += " (HP) + Heilung"
		elif type in [DentiAttributes.Type.MELEE_DAMAGE, DentiAttributes.Type.RANGED_DAMAGE]:
			text += " (Waffenskalierung)"
		return text
	return description


func attribute_name() -> String:
	return DentiAttributes.name_for_key(stat) if DentiAttributes.from_key(stat) >= 0 else display_name


func attribute_icon() -> int:
	var type := DentiAttributes.from_key(stat)
	return DentiAttributes.ICONS[type] if type >= 0 else icon_index
