class_name StoryProgress
extends RefCounted

var enabled: bool = false
var chapter_index: int = 0
var revealed_chapters: int = 0
var completed_boss_wave: int = 0
var greeted_boss_wave: int = 0
var dialogue_id: StringName = &""
var dialogue_line: int = 0
var followup: StringName = &""
var travel_target: int = -1
var travel_progress: float = 0.0

func start() -> void:
	enabled = true
	chapter_index = 0
	revealed_chapters = 1
	completed_boss_wave = 0
	greeted_boss_wave = 0
	travel_target = -1
	travel_progress = 0.0
	begin_dialogue(&"intro", &"starter")

func begin_dialogue(id: StringName, next: StringName) -> void:
	dialogue_id = id
	dialogue_line = 0
	followup = next

func arrive(index: int) -> void:
	chapter_index = clampi(index, 0, 3)
	revealed_chapters = maxi(revealed_chapters, chapter_index + 1)

func save_data() -> Dictionary:
	return {"enabled": enabled, "chapter": chapter_index, "revealed": revealed_chapters,
		"completed_boss_wave": completed_boss_wave, "greeted_boss_wave": greeted_boss_wave, "dialogue": str(dialogue_id),
		"line": dialogue_line, "followup": str(followup),
		"travel_target": travel_target, "travel_progress": travel_progress}

func restore(saved: Dictionary) -> void:
	enabled = bool(saved.get("enabled", false))
	chapter_index = clampi(int(saved.get("chapter", 0)), 0, 3) if enabled else 0
	revealed_chapters = clampi(int(saved.get("revealed", chapter_index + 1)), chapter_index + 1, 4) if enabled else 0
	completed_boss_wave = clampi(int(saved.get("completed_boss_wave", 0)), 0, 20)
	greeted_boss_wave = clampi(int(saved.get("greeted_boss_wave", completed_boss_wave)), 0, 20)
	dialogue_id = StringName(str(saved.get("dialogue", ""))) if enabled else &""
	var lines := StoryCatalog.dialogue(dialogue_id)
	dialogue_line = clampi(int(saved.get("line", 0)), 0, maxi(lines.size() - 1, 0))
	followup = StringName(str(saved.get("followup", "")))
	if lines.is_empty():
		dialogue_id = &""
	travel_target = clampi(int(saved.get("travel_target", -1)), -1, 3) if enabled and not lines.is_empty() else -1
	travel_progress = clampf(float(saved.get("travel_progress", 0)), 0, 1)
