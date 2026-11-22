class_name WeaponMasteries
extends RefCounted

const ALL: Array[WeaponMasteryData] = [
	preload("res://data/masteries/exam.tres"), preload("res://data/masteries/bronze.tres"),
	preload("res://data/masteries/silver.tres"), preload("res://data/masteries/gold.tres"),
]


static func valid_weapon(id: StringName) -> bool:
	return WeaponCatalog.by_id(id) in WeaponCatalog.ALL


static func by_id(id: StringName) -> WeaponMasteryData:
	for definition in ALL:
		if definition.id == id: return definition
	return null


static func flags_for(event: StringName, difficulty: StringName, wave: int) -> int:
	var rank := difficulty_rank(difficulty)
	if rank < 0: return 0
	var result := 0
	for definition in ALL:
		if rank < difficulty_rank(definition.minimum_difficulty): continue
		if event == &"victory" and wave == WaveController.MAX_WAVES:
			result |= definition.flag
		elif event == &"boss" and not definition.requires_victory and wave == definition.boss_wave:
			result |= definition.flag
	return result


static func difficulty_rank(id: StringName) -> int:
	for index in DifficultyCatalog.ALL.size():
		if DifficultyCatalog.ALL[index].id == id: return index
	return -1


static func ids_for(flags: int) -> Array[String]:
	var result: Array[String] = []
	for definition in ALL:
		if flags & definition.flag: result.append(str(definition.id))
	return result


static func all_flags() -> int:
	var result := 0
	for definition in ALL: result |= definition.flag
	return result


static func details(flags: int) -> String:
	var lines: PackedStringArray = []
	for definition in ALL:
		lines.append("%s · %s\n%s" % [definition.display_name, "Erreicht" if flags & definition.flag else "Offen", definition.requirement])
	return "\n\n".join(lines) + "\n\nEs zählt die bestätigte Startwaffe. Verkauf, Fusion und Evolution ändern die Zuordnung nicht. Story und Arena zählen gleichermaßen; höhere Siege schließen niedrigere Medaillen ein."
