class_name ProgressionStore
extends RefCounted

var hell_unlocked: bool = false
var discovered_fusions: Array[String] = []
var weapon_masteries: Dictionary = {}
var class_wins: Array[String] = []
## Classes opened through ClassUnlocks (see data/unlocks/classes).
var unlocked_classes: Array[String] = []
## Lifetime counters across all runs (MetaCounters.KEYS): kills, bosses, ...
var counters: Dictionary = {}
## Classes that won wave 20 at least once, on any difficulty.
var class_victories: Array[String] = []
## Unlocked weapons/classes not tried yet ("weapon:id", "class:id") for "Neu" badges.
var fresh_unlocks: Array[String] = []
var necrodent_debug_unlocked := false


func load_from(path: String) -> void:
	var config := ConfigFile.new()
	var loaded := config.load(path) == OK
	hell_unlocked = loaded and bool(config.get_value("difficulty", "hell_unlocked", false))
	necrodent_debug_unlocked = loaded and bool(config.get_value("debug", "necrodent_unlocked", false))
	discovered_fusions.clear()
	weapon_masteries.clear()
	class_wins.clear()
	unlocked_classes.clear()
	counters.clear()
	class_victories.clear()
	fresh_unlocks.clear()
	var mastery: Variant = config.get_value("mastery", "weapons", {}) if loaded else {}
	if mastery is Dictionary:
		for id in mastery:
			if WeaponMasteries.valid_weapon(StringName(str(id))) and mastery[id] is int:
				weapon_masteries[str(id)] = maxi(int(mastery[id]), 0) & WeaponMasteries.all_flags()
	if loaded:
		var wins: Variant = config.get_value("mastery", "classes", [])
		if wins is Array:
			for id in ClassCatalog.MASTERY_CLASSES:
				if str(id) in wins: class_wins.append(str(id))
		for key in MetaCounters.KEYS:
			counters[key] = maxi(int(config.get_value("counters", key, 0)), 0)
		var victories: Variant = config.get_value("unlocks", "class_victories", [])
		if victories is Array:
			for profile in ClassCatalog.profiles:
				if str(profile.id) in victories: class_victories.append(str(profile.id))
		var fresh: Variant = config.get_value("unlocks", "fresh", [])
		if fresh is Array:
			for key in fresh:
				if key is String and key.length() <= 64 and not fresh_unlocks.has(key): fresh_unlocks.append(key)
		var opened: Variant = config.get_value("unlocks", "classes", [])
		if opened is Array:
			for entry in ClassUnlocks.ALL:
				if str(entry.class_id) in opened: unlocked_classes.append(str(entry.class_id))
		for id in config.get_value("dentipedia", "fusions", []):
			if WeaponEvolutions.by_id(StringName(str(id))) != null and not discovered_fusions.has(str(id)):
				discovered_fusions.append(str(id))


## Copy of the unlock-relevant state, for before/after comparisons.
func meta_snapshot() -> ProgressionStore:
	var copy := ProgressionStore.new()
	copy.counters = counters.duplicate()
	copy.class_victories = class_victories.duplicate()
	copy.unlocked_classes = unlocked_classes.duplicate()
	copy.weapon_masteries = weapon_masteries.duplicate()
	return copy


func save_to(path: String) -> Error:
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("difficulty", "hell_unlocked", hell_unlocked)
	config.set_value("dentipedia", "fusions", discovered_fusions)
	config.set_value("mastery", "weapons", weapon_masteries.duplicate())
	config.set_value("mastery", "classes", class_wins.duplicate())
	config.set_value("unlocks", "classes", unlocked_classes.duplicate())
	config.set_value("unlocks", "class_victories", class_victories.duplicate())
	config.set_value("unlocks", "fresh", fresh_unlocks.duplicate())
	for key in MetaCounters.KEYS:
		config.set_value("counters", key, int(counters.get(key, 0)))
	config.set_value("debug", "necrodent_unlocked", necrodent_debug_unlocked)
	var temporary := "%s.%d.tmp" % [path, OS.get_process_id()]
	var error := config.save(temporary)
	if error == OK:
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		push_warning("Fortschritt konnte nicht gespeichert werden: %s" % path)
	return error
