class_name ProgressionStore
extends RefCounted

var hell_unlocked: bool = false
var discovered_fusions: Array[String] = []


func load_from(path: String) -> void:
	var config := ConfigFile.new()
	var loaded := config.load(path) == OK
	hell_unlocked = loaded and bool(config.get_value("difficulty", "hell_unlocked", false))
	discovered_fusions.clear()
	if loaded:
		for id in config.get_value("dentipedia", "fusions", []):
			if WeaponEvolutions.by_id(StringName(str(id))) != null and not discovered_fusions.has(str(id)):
				discovered_fusions.append(str(id))


func save_to(path: String) -> void:
	var config := ConfigFile.new()
	config.load(path)
	config.set_value("difficulty", "hell_unlocked", hell_unlocked)
	config.set_value("dentipedia", "fusions", discovered_fusions)
	if config.save(path) != OK:
		push_warning("Fortschritt konnte nicht gespeichert werden: %s" % path)
