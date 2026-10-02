class_name DentiAttributes
extends RefCounted

# Stable enum identities for gameplay/UI; resource and save keys stay compatible.
enum Type { DAMAGE, ARMOR, MAX_HEALTH, ATTACK_SPEED, CRIT_CHANCE, REGEN, MOVEMENT, LUCK, MELEE_DAMAGE, RANGED_DAMAGE, DODGE }

const KEYS: Array[StringName] = [
	&"damage_bonus", &"armor", &"max_health", &"attack_speed", &"crit_chance",
	&"regen", &"speed_bonus", &"luck", &"melee_damage", &"ranged_damage", &"dodge_chance",
]
const NAMES: Array[String] = [
	"Bisskraft", "Härte", "Schmelz", "Putzeifer", "Glanz", "Speichel",
	"Bewegung", "Zahnglück", "Nahschaden", "Fernschaden", "Zahnflutsch",
]
const MEANINGS: Array[String] = [
	"Schadensbonus für Waffen", "Rüstung: reduziert erlittenen Schaden",
	"Maximale Lebenspunkte (HP)", "Angriffstempo", "Chance auf kritische Treffer",
	"Regenerationspunkte und Heilung pro Sekunde", "Bewegungstempo", "Glück bei Beute und Seltenheiten",
	"Zusätzlicher Nahschaden nach Waffenskalierung", "Zusätzlicher Fernschaden nach Waffenskalierung",
	"Chance, einem Treffer auszuweichen (Dodge)",
]
const ICONS: Array[int] = [0, 1, 2, 3, 4, 5, 6, 7, 8, 9, -1]
# Dodge is reserved for the next gameplay slice, not yet in the upgrade pool.
const ACTIVE: Array[Type] = [Type.DAMAGE, Type.ARMOR, Type.MAX_HEALTH, Type.ATTACK_SPEED,
	Type.CRIT_CHANCE, Type.REGEN, Type.MOVEMENT, Type.LUCK, Type.MELEE_DAMAGE, Type.RANGED_DAMAGE]
const SHOP_ROWS: Array = [
	[Type.DAMAGE, Type.ARMOR, Type.MAX_HEALTH],
	[Type.ATTACK_SPEED, Type.CRIT_CHANCE, Type.REGEN],
	[Type.MOVEMENT, Type.LUCK, Type.MELEE_DAMAGE, Type.RANGED_DAMAGE],
]
# Legacy prose in Resources is resolved at presentation boundaries. These aliases
# never change effect identifiers or damage calculations.
const ALIASES: Dictionary = {
	"Rüstung": Type.ARMOR, "Regeneration": Type.REGEN, "Angriffstempo": Type.ATTACK_SPEED,
	"kritische Chance": Type.CRIT_CHANCE, "Krit": Type.CRIT_CHANCE, "Glück": Type.LUCK,
	"maximales Leben": Type.MAX_HEALTH, "maximalem Leben": Type.MAX_HEALTH,
}

static func from_key(key: StringName) -> int:
	return KEYS.find(key)

static func key_for(type: Type) -> StringName:
	return KEYS[type]

static func name_for(type: Type) -> String:
	return NAMES[type]

static func meaning_for(type: Type) -> String:
	return MEANINGS[type]

static func name_for_key(key: StringName) -> String:
	var type := from_key(key)
	return NAMES[type] if type >= 0 else str(key)

static func is_fraction(type: Type) -> bool:
	return type in [Type.CRIT_CHANCE, Type.DODGE]

static func is_percent(type: Type) -> bool:
	return is_fraction(type) or type in [Type.DAMAGE, Type.ATTACK_SPEED, Type.MOVEMENT]

static func number(value: float, signed: bool = false) -> String:
	return ("%+.0f" if signed else "%.0f") % value if is_equal_approx(value, roundf(value)) else ("%+.1f" if signed else "%.1f") % value

static func bonus_text(type: Type, amount: float) -> String:
	var value := amount * 100.0 if is_fraction(type) else amount
	return "%s%s %s" % [number(value, true), " %" if is_percent(type) else "", name_for(type)]

static func value_text(stats: PlayerStats, type: Type) -> String:
	match type:
		Type.ARMOR: return stats.armor_text()
		Type.REGEN: return stats.regen_text()
		Type.MAX_HEALTH: return "%.0f HP" % stats.max_health
	var value: float = float(stats.get(key_for(type)))
	if is_fraction(type):
		return "%s %%" % number(value * 100.0)
	return "%s%s" % [number(value, type != Type.LUCK), " %" if is_percent(type) else ""]

static func shop_text(stats: PlayerStats) -> String:
	var rows: PackedStringArray = []
	for types: Array in SHOP_ROWS:
		var entries: PackedStringArray = []
		for type: Type in types:
			entries.append("%s %s" % [name_for(type), value_text(stats, type)])
		rows.append(" · ".join(entries))
	return "\n".join(rows)

static func resolve_text(source: String) -> String:
	var result := source
	for alias: String in ALIASES:
		var pattern := RegEx.new()
		pattern.compile("\\b" + alias + "\\b")
		result = pattern.sub(result, name_for(ALIASES[alias]), true)
	# A signed percentage damage stat is Bisskraft; actual hit/proc damage keeps
	# the word Schaden. HP bonuses/debuffs are Schmelz, healing remains Leben.
	var pattern := RegEx.new()
	pattern.compile("([+-][0-9]+(?:[,.][0-9]+)? % )Schaden\\b")
	result = pattern.sub(result, "$1" + name_for(Type.DAMAGE), true)
	pattern.compile("(^|, )([+][0-9]+(?:[,.][0-9]+)? )Leben\\b")
	result = pattern.sub(result, "$1$2" + name_for(Type.MAX_HEALTH) + " (HP)", true)
	pattern.compile("(-[0-9]+(?:[,.][0-9]+)? )Leben\\b")
	return pattern.sub(result, "$1" + name_for(Type.MAX_HEALTH) + " (HP)", true)
