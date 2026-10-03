extends SceneTree

var session: Node
var capture: bool
var capture_dir: String

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://test_story_boss_dialogue.json"
	session.report_dir = "user://test_story_boss_reports"
	session.selected_story_mode = true
	session.resume_requested = false
	session.clear_run()
	capture = "--capture" in OS.get_cmdline_user_args()
	capture_dir = ProjectSettings.globalize_path("res://.godot/story-boss-preview")
	if capture:
		DirAccess.make_dir_recursive_absolute(capture_dir)
	await _resize(Vector2i(1280, 720))
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	_finish_dialogue(game)
	game.choice_panel.buttons[0].pressed.emit()
	for milestone in [5, 10, 15, 20]:
		paused = true
		game.wave.active = false
		game._clear_arena(false)
		await process_frame
		game.wave.current_wave = milestone - 1
		game.story.arrive(milestone / 5 - 1)
		game.arena.set_story_chapter(StoryCatalog.chapter(game.story.chapter_index))
		game._open_shop()
		game._on_shop_continue()
		var data := WaveController.boss_for_wave(milestone)
		var dialogue_id := StoryCatalog.before_boss(milestone)
		var remaining: float = game.wave.remaining
		var reveals: int = game.story.revealed_chapters
		if not _check(paused and game.story.dialogue_id == dialogue_id and game.story.followup == &"wave" and not game.in_shop and not game.shop_panel.visible and not game.wave.active and game.wave.current_wave == milestone - 1 and game.get_node("Enemies").get_child_count() == 0, "boss dialogue started combat or left shop interactive"):
			return
		if not _check(game.story_dialogue.speaker_label.text == data.display_name and game.story_dialogue.portrait.texture == data.sprite and not game.hud.visible, "boss uses wrong portrait/name or combat HUD"):
			return
		for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(1280, 720)]:
			await _resize(extent)
			var lines := StoryCatalog.dialogue(dialogue_id)
			for index in lines.size():
				game.story.dialogue_line = index
				game._show_story_line()
				for frame in 5:
					await process_frame
				var dialog: StoryDialogue = game.story_dialogue
				var bounds := Rect2(Vector2.ZERO, Vector2(extent))
				if not _check(bounds.encloses(dialog.panel.get_global_rect()) and dialog.panel.get_global_rect().encloses(dialog.body_label.get_global_rect()) and dialog.panel.get_global_rect().encloses(dialog.speaker_label.get_global_rect()) and not dialog.speaker_label.get_theme_font("font").get_string_size(dialog.speaker_label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, dialog.speaker_label.get_theme_font_size("font_size")).x > dialog.speaker_label.size.x, "boss dialogue/name overflows %s for %s" % [extent, data.display_name]):
					return
				if not _check(dialog.portrait.texture == (data.sprite if index % 2 == 0 else StoryDialogue.DENTI), "portrait did not follow speaker"):
					return
				if index == 0 and capture:
					await create_timer(0.24, true).timeout
					await RenderingServer.frame_post_draw
					root.get_texture().get_image().save_png(capture_dir + "/boss_%d_%dx%d.png" % [milestone, extent.x, extent.y])
			if not _check(game.wave.remaining == remaining and not game.wave.active and game.get_node("Enemies").get_child_count() == 0 and game.story.revealed_chapters == reveals, "dialogue advanced timer, spawned enemies or revealed another world"):
				return
		game.story.dialogue_line = 1
		game._show_story_line()
		game = await _resume(game)
		if not _check(game.story_dialogue.visible and game.story.dialogue_id == dialogue_id and game.story.dialogue_line == 1 and game.story.followup == &"wave" and paused and not game.wave.active and game.get_node("Enemies").get_child_count() == 0, "resume lost pre-boss dialogue or started boss early"):
			return
		_finish_dialogue(game)
		if not _check(game.wave.current_wave == milestone and game.wave.active and not paused and not game.story_dialogue.visible and game.hud.visible and game.story.greeted_boss_wave == milestone and BossEncounter.remaining(game.get_node("Enemies")).size() == 1 and game.wave.remaining == WaveController.duration_for_wave(milestone), "Kämpfen must start exactly one complete boss wave"):
			return
		game = await _resume(game)
		if not _check(not game.story_dialogue.visible and game.wave.active and game.story.greeted_boss_wave == milestone and BossEncounter.remaining(game.get_node("Enemies")).size() == 1, "combat resume replayed greeting or duplicated boss"):
			return
	# Old StoryProgress payloads do not need the new greeting field.
	var legacy := StoryProgress.new()
	legacy.restore({"enabled": true, "completed_boss_wave": 10, "chapter": 2})
	if not _check(legacy.greeted_boss_wave == 10 and legacy.dialogue_id == &"", "legacy story saves require new field"):
		return
	# Classic and endless retain immediate wave starts, with no story banter.
	paused = true
	game.wave.active = false
	game._clear_arena(false)
	await process_frame
	game.story.enabled = false
	game.wave.current_wave = 4
	game._open_shop()
	game._on_shop_continue()
	if not _check(game.wave.current_wave == 5 and not game.story_dialogue.visible and game.wave.active, "classic boss acquired story dialogue"):
		return
	paused = true
	game.wave.active = false
	game._clear_arena(false)
	await process_frame
	game.story.enabled = true
	game.wave.endless_enabled = true
	game.wave.current_wave = 29
	game._open_shop()
	game._on_shop_continue()
	if not _check(game.wave.current_wave == 30 and game.wave.active and not game.story_dialogue.visible and BossEncounter.remaining(game.get_node("Enemies")).size() == 2, "endless boss continuation changed"):
		return
	paused = false
	session.selected_story_mode = false
	session.clear_run()
	print("Denti four boss dialogues, portraits, wave gating, resume and responsive UI test passed")
	quit(0)

func _finish_dialogue(game: Node2D) -> void:
	for index in 32:
		if not game.story_dialogue.visible:
			return
		game._on_story_advance()

func _resume(game: Node2D) -> Node2D:
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	return current_scene

func _resize(extent: Vector2i) -> void:
	root.content_scale_size = extent
	root.size = extent
	if capture:
		DisplayServer.window_set_size(extent)
	for frame in 4:
		await process_frame

func _check(ok: bool, message: String) -> bool:
	if ok:
		return true
	paused = false
	session.clear_run()
	push_error(message)
	quit(1)
	return false
