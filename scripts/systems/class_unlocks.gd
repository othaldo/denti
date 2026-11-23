class_name ClassUnlocks
extends RefCounted
## Class meta unlocks: each class except Good Old Molar opens once a run ends
## with a matching element weapon equipped. The state is a list of unlocked
## class ids in the progression file.

const ALL: Array[ClassUnlockData] = [
	preload("res://data/unlocks/classes/assassin.tres"),
	preload("res://data/unlocks/classes/rinser.tres"),
	preload("res://data/unlocks/classes/ember.tres"),
	preload("res://data/unlocks/classes/frost_warden.tres"),
	preload("res://data/unlocks/classes/tooth_fairy.tres"),
	preload("res://data/unlocks/classes/necrodent.tres"),
	preload("res://data/unlocks/classes/herb_druid.tres"),
]
## Plural role names for requirement texts.
const ROLE_NAMES := {&"ranged": "Fernkampfwaffen", &"contact": "Kontaktwaffen"}
const COUNT_WORDS: Array[String] = ["null", "einer", "zwei", "drei", "vier", "fünf", "sechs"]

## Weapon damage types that count as an element on their own.
const DAMAGE_TYPE_ELEMENTS := {"Wasser": &"water", "Licht": &"light"}
## Adjective forms for requirement texts ("Gift-Waffe").
const ELEMENT_NAMES := {&"poison": "Gift", &"water": "Wasser", &"electric": "Elektro", &"fire": "Feuer",
	&"ice": "Eis", &"light": "Licht", &"bleed": "Blutungs"}


static func rule(id: StringName) -> ClassUnlockData:
	for entry in ALL:
		if entry.class_id == id: return entry
	return null


## Elements a weapon brings: its damage type and its element enchantments.
static func weapon_elements(weapon: WeaponInstance) -> Array[StringName]:
	var result: Array[StringName] = []
	if weapon == null or weapon.data == null: return result
	var typed: Variant = DAMAGE_TYPE_ELEMENTS.get(weapon.data.damage_type)
	if typed != null: result.append(typed)
	for affix in weapon.affixes:
		var element := StringName(str(affix.get("id", "")))
		if ELEMENT_NAMES.has(element) and not result.has(element): result.append(element)
	return result


## Whether a finished run meets the rule.
static func qualifies(entry: ClassUnlockData, weapons: Array[WeaponInstance], wave: int, victory: bool, difficulty: StringName) -> bool:
	if entry == null or wave < entry.min_wave: return false
	if entry.victory and not victory: return false
	if entry.min_difficulty != &"" and WeaponMasteries.difficulty_rank(difficulty) < WeaponMasteries.difficulty_rank(entry.min_difficulty): return false
	if entry.role_count > 0:
		var count := 0
		for weapon in weapons:
			if weapon != null and weapon.data != null and entry.role in weapon.data.class_roles: count += 1
		return count >= entry.role_count
	for weapon in weapons:
		for element in weapon_elements(weapon):
			if element in entry.elements: return true
	return false


## Class ids a finished run newly qualifies for (not yet unlocked).
static func earned(unlocked: Array[String], weapons: Array[WeaponInstance], wave: int, victory: bool, difficulty: StringName) -> Array[String]:
	var result: Array[String] = []
	for entry in ALL:
		if str(entry.class_id) in unlocked: continue
		if qualifies(entry, weapons, wave, victory, difficulty): result.append(str(entry.class_id))
	return result


## Short German requirement, e.g. "Run ab Welle 10 mit einer Gift-Waffe beenden".
static func requirement(id: StringName) -> String:
	var entry := rule(id)
	if entry == null: return ""
	if entry.role_count > 0:
		var amount: String = COUNT_WORDS[entry.role_count] if entry.role_count < COUNT_WORDS.size() else str(entry.role_count)
		return "Run ab Welle %d mit %s %s beenden" % [entry.min_wave, amount, ROLE_NAMES.get(entry.role, str(entry.role))]
	var names: PackedStringArray = []
	for element in entry.elements: names.append(ELEMENT_NAMES.get(element, str(element)))
	# "Wasser- oder Elektro-Waffe": hyphenate every element but the last.
	for index in names.size() - 1: names[index] = names[index] + "-"
	var weapon := " oder ".join(names) + "-Waffe"
	if entry.victory:
		var difficulty := DifficultyCatalog.by_id(entry.min_difficulty) if entry.min_difficulty != &"" else null
		var level := (" auf %s oder höher" % difficulty.display_name) if difficulty != null else ""
		return "Welle %d%s gewinnen, mit einer %s" % [entry.min_wave, level, weapon]
	return "Run ab Welle %d mit einer %s beenden" % [entry.min_wave, weapon]
