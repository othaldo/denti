class_name ProgressionStore
extends RefCounted

var hell_unlocked: bool = false
var discovered_fusions: Array[String] = []
var weapon_masteries: Dictionary = {}


func load_from(path: String) -> void:
	var config := ConfigFile.new()
	var loaded := config.load(path) == OK
	hell_unlocked = loaded and bool(config.get_value("difficulty", "hell_unlocked", false))
	discovered_fusions.clear()
	weapon_masteries.clear()
	var mastery: Variant = config.get_value("mastery", "weapons", {}) if loaded else {}
	if mastery is Dictionary:
		for id in mastery:
			if WeaponMasteries.valid_weapon(StringName(str(id))) and mastery[id] is int:
				weapon_masteries[str(id)] = maxi(int(mastery[id]), 0) & WeaponMasteries.all_flags()
	if loaded:
		for id in config.get_value("dentipedia", "fusions", []):
			if WeaponEvolutions.by_id(StringName(str(id))) != null and not discovered_fusions.has(str(id)):
				discovered_fusions.append(str(id))


func save_to(path: String) -> Error:
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("difficulty", "hell_unlocked", hell_unlocked)
	config.set_value("dentipedia", "fusions", discovered_fusions)
	config.set_value("mastery", "weapons", weapon_masteries.duplicate())
	var temporary := "%s.%d.tmp" % [path, OS.get_process_id()]
	var error := config.save(temporary)
	if error == OK:
		error = DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary), ProjectSettings.globalize_path(path))
	if error != OK:
		DirAccess.remove_absolute(ProjectSettings.globalize_path(temporary))
		push_warning("Fortschritt konnte nicht gespeichert werden: %s" % path)
	return error
