class_name StoryRunController
extends RefCounted

signal presenting(screen: StringName)
signal finished(followup: StringName)
signal save_requested

var progress: StoryProgress
var dialogue: StoryDialogue
var travel: StoryTravel
var arena: DentiArena
var player: Player


func configure(state: StoryProgress, dialogue_view: StoryDialogue, travel_view: StoryTravel, run_arena: DentiArena, run_player: Player) -> void:
	progress = state
	dialogue = dialogue_view
	travel = travel_view
	arena = run_arena
	player = run_player


func show_line() -> void:
	var lines := StoryCatalog.dialogue(progress.dialogue_id)
	if lines.is_empty():
		return
	presenting.emit(&"dialogue")
	dialogue.show_line(lines[progress.dialogue_line], StoryCatalog.chapter(progress.chapter_index), progress.dialogue_line, lines.size())
	save_requested.emit()


func advance() -> void:
	if not dialogue.visible or progress.dialogue_id == &"":
		return
	var lines := StoryCatalog.dialogue(progress.dialogue_id)
	var line := lines[progress.dialogue_line]
	if line.has("enter") and progress.chapter_index < int(line.enter):
		progress.travel_target = int(line.enter)
		progress.travel_progress = 0
		show_travel()
		return
	if progress.dialogue_line + 1 < lines.size():
		progress.dialogue_line += 1
		show_line()
		return
	var next := progress.followup
	progress.dialogue_id = &""
	progress.dialogue_line = 0
	progress.followup = &""
	dialogue.visible = false
	finished.emit(next)


func show_travel() -> void:
	presenting.emit(&"travel")
	dialogue.visible = false
	travel.present(progress)
	save_requested.emit()


func arrive(index: int) -> void:
	progress.arrive(index)
	arena.set_story_chapter(StoryCatalog.chapter(index))
	player.global_position = arena.arena_size / 2.0
	var camera: Camera2D = player.get_node("Camera2D")
	camera.reset_smoothing()
	camera.force_update_scroll()
	save_requested.emit()


func finish_travel() -> void:
	progress.travel_target = -1
	progress.travel_progress = 0
	travel.visible = false
	progress.dialogue_line += 1
	show_line()
