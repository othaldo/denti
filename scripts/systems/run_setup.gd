class_name RunSetup
extends RefCounted

const STEPS: Array[StringName] = [&"difficulty", &"class", &"weapon"]
const LABELS := {&"difficulty": "Schwierigkeit", &"class": "Klasse", &"weapon": "Waffe"}
var step: StringName = &"difficulty"
var visited_step: StringName = &"difficulty"
var difficulty_id: StringName = &"normal"
var weapon_id: StringName = &""
var class_id: StringName = &"good_old_molar"
var story_mode := false
var root_capacity := PlayerStats.DEFAULT_ROOT_CAPACITY
var resume_pending := false

func select_class(id: StringName) -> bool:
	var profile := ClassCatalog.by_id(id)
	if profile == null or not profile.valid() or (resume_pending and id != class_id): return false
	if resume_pending: return true
	class_id = id
	root_capacity = profile.root_capacity
	if not WeaponEligibility.starter(WeaponCatalog.by_id(weapon_id), profile, root_capacity): weapon_id = &""
	return true

func next_step() -> void:
	step = STEPS[mini(STEPS.find(step) + 1, STEPS.size() - 1)]
	mark_reached(step)

func mark_reached(id: StringName) -> void:
	if STEPS.find(id) > STEPS.find(visited_step): visited_step = id

func can_visit(id: StringName) -> bool:
	return id in STEPS and STEPS.find(id) <= STEPS.find(visited_step)

func previous_step() -> bool:
	var index := STEPS.find(step)
	if index <= 0: return false
	step = STEPS[index - 1]
	return true

func save_to(path: String) -> void:
	var error := RunStore.save_run(path, {"step": str(step), "visited_step": str(visited_step), "difficulty": str(difficulty_id),
		"weapon": str(weapon_id), "class": str(class_id), "story": story_mode, "roots": root_capacity, "resume_pending": resume_pending})
	if error != OK: push_warning("Run-Vorbereitung konnte nicht gespeichert werden.")

static func load_from(path: String) -> RunSetup:
	if not FileAccess.file_exists(path): return null
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null: return null
	var value: Variant = JSON.parse_string(file.get_as_text())
	if not value is Dictionary: return null
	if not value.get("roots", PlayerStats.DEFAULT_ROOT_CAPACITY) is int and not value.get("roots", PlayerStats.DEFAULT_ROOT_CAPACITY) is float: return null
	for key in ["story", "resume_pending"]:
		if value.has(key) and not value[key] is bool: return null
	var result := RunSetup.new()
	if not value.get("class", "good_old_molar") is String: return null
	result.class_id = StringName(value.get("class", "good_old_molar"))
	if ClassCatalog.by_id(result.class_id) == null or not ClassCatalog.by_id(result.class_id).valid(): return null
	result.step = StringName(str(value.get("step", "difficulty")))
	if result.step not in STEPS: result.step = STEPS[0]
	result.difficulty_id = DifficultyCatalog.by_id(StringName(str(value.get("difficulty", "normal")))).id
	var weapon := WeaponCatalog.by_id(StringName(str(value.get("weapon", ""))))
	result.weapon_id = weapon.id if weapon in WeaponCatalog.ALL else &""
	result.visited_step = StringName(str(value.get("visited_step", str(result.step))))
	if result.visited_step not in STEPS: result.visited_step = STEPS[0]
	result.mark_reached(result.step)
	if result.weapon_id != &"": result.mark_reached(&"weapon")
	result.story_mode = bool(value.get("story", false))
	result.root_capacity = clampi(int(value.get("roots", PlayerStats.DEFAULT_ROOT_CAPACITY)), 1, 64)
	if not WeaponEligibility.starter(weapon, ClassCatalog.by_id(result.class_id), result.root_capacity): result.weapon_id = &""
	result.resume_pending = bool(value.get("resume_pending", false))
	return result
