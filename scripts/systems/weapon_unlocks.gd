class_name WeaponUnlocks
extends RefCounted
## Meta progression for standard weapons. A locked weapon opens through a
## lifetime counter (kills, bosses, elites, coins, first death) or the first
## wave-20 victory with a class. No rule depends on another locked weapon.
## Weapons without a rule are available from the first run.

const ALL: Array[WeaponUnlockData] = [
	preload("res://data/unlocks/interdental_brush.tres"),
	preload("res://data/unlocks/cavity_grinder.tres"),
	preload("res://data/unlocks/crown_launcher.tres"),
	preload("res://data/unlocks/floss_garrote.tres"),
	preload("res://data/unlocks/enamel_mirror.tres"),
	preload("res://data/unlocks/prophylaxis_polisher.tres"),
	preload("res://data/unlocks/mouthwash_mortar.tres"),
	preload("res://data/unlocks/water_turbine.tres"),
	preload("res://data/unlocks/uv_lamp.tres"),
	preload("res://data/unlocks/fluoride_rocket.tres"),
]


static func rule(id: StringName) -> WeaponUnlockData:
	for entry in ALL:
		if entry.weapon_id == id: return entry
	return null


static func unlocked(id: StringName, progression: ProgressionStore) -> bool:
	var entry := rule(id)
	if entry == null: return true
	if entry.class_victory != &"": return str(entry.class_victory) in progression.class_victories
	return int(progression.counters.get(str(entry.counter), 0)) >= entry.amount


## Current and goal value of a counter rule; (0, 0) for class victories.
static func progress(id: StringName, progression: ProgressionStore) -> Vector2i:
	var entry := rule(id)
	if entry == null or entry.counter == &"": return Vector2i.ZERO
	return Vector2i(mini(int(progression.counters.get(str(entry.counter), 0)), entry.amount), entry.amount)


## Weapons open now that were locked in `before` (a progression snapshot).
static func newly_unlocked(before: ProgressionStore, after: ProgressionStore) -> Array[StringName]:
	var result: Array[StringName] = []
	for entry in ALL:
		if not unlocked(entry.weapon_id, before) and unlocked(entry.weapon_id, after):
			result.append(entry.weapon_id)
	return result


## Short requirement; with `progression` counter rules show their progress.
static func requirement(id: StringName, progression: ProgressionStore = null) -> String:
	var entry := rule(id)
	if entry == null: return ""
	if entry.class_victory != &"":
		var profile := ClassCatalog.by_id(entry.class_victory)
		return "Welle 20 gewinnen mit %s" % (profile.display_name if profile != null else str(entry.class_victory))
	if entry.counter == &"deaths" and entry.amount == 1:
		return "Einmal ausfallen"
	if progression == null:
		return "%s %s" % [MetaCounters.number(entry.amount), MetaCounters.label(entry.counter)]
	var current := progress(id, progression)
	return "%s / %s %s" % [MetaCounters.number(current.x), MetaCounters.number(current.y), MetaCounters.label(entry.counter)]
