extends SceneTree

const GAME: PackedScene = preload("res://scenes/game/game.tscn")
var session: Node
var capture: bool
var capture_dir: String

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://test_story_run.json"
	session.progression_path = "user://test_story_progression.cfg"
	session.report_dir = "user://test_story_reports"
	session.clear_run()
	session.selected_story_mode = true
	session.resume_requested = false
	capture = "--capture" in OS.get_cmdline_user_args()
	capture_dir = ProjectSettings.globalize_path("res://.godot/story-preview")
	if capture:
		DirAccess.make_dir_recursive_absolute(capture_dir)
	await _resize(Vector2i(1280, 720))
	var game: Node2D = GAME.instantiate()
	root.add_child(game)
	current_scene = game
	if not _check(game.story_dialogue.visible and paused and not game.wave.active and not game.choice_panel.visible and game.story.revealed_chapters == 1, "intro must explain the summon before starter/combat"):
		return
	game.story_dialogue.next_button.pressed.emit()
	if not _check(game.story.dialogue_line == 0 and not game.story_dialogue.revealing, "first click must reveal the sentence without skipping it"):
		return
	game.story_dialogue.next_button.pressed.emit()
	game.story_dialogue.next_button.scale = Vector2.ONE
	game = await _resume(game)
	if not _check(game.story.dialogue_line == 1 and game.story_dialogue.speaker_label.text == "Zahnfee" and game.wave.current_wave == 0 and not game.starter_pending, "resume lost intro cursor or began at wave one"):
		return
	# Every dialogue line must fit even at small landscape and portrait sizes.
	for extent in [Vector2i(320, 568), Vector2i(360, 640), Vector2i(568, 320), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		await _resize(extent)
		for index in StoryCatalog.INTRO.size():
			game.story.dialogue_line = index
			game._show_story_line()
			for frame in 5:
				await process_frame
			var dialog: StoryDialogue = game.story_dialogue
			var bounds := Rect2(Vector2.ZERO, Vector2(extent))
			if not _check(bounds.encloses(dialog.panel.get_global_rect()) and dialog.panel.get_global_rect().encloses(dialog.body_label.get_global_rect()) and dialog.panel.get_global_rect().encloses(dialog.next_button.get_global_rect()), "dialog content escapes %s: %s" % [extent, dialog.panel.get_global_rect()]):
				return
			if index == 1:
				await _capture("intro_%dx%d" % [extent.x, extent.y])
	game.story.dialogue_line = 0
	_finish_dialogue(game)
	if not _check(game.starter_pending and game.choice_panel.mode == &"starter" and not game.wave.active, "intro must lead to starter choice"):
		return
	game = await _resume(game)
	if not _check(game.starter_pending and game.wave.current_wave == 0 and not game.story_dialogue.visible, "resume replayed intro after completion"):
		return
	game.choice_panel.buttons[0].pressed.emit()
	if not _check(game.wave.active and game.wave.current_wave == 1 and not paused, "story starter must begin wave one"):
		return
	await _resize(Vector2i(1280, 720))
	game.wave.active = false
	game.wave.current_wave = 5
	game._spawn_enemy(load("res://data/enemies/cavity_count.tres"))
	game._on_wave_finished(5)
	if not _check(game.boss_pending and not game.story_dialogue.visible and game.story.completed_boss_wave == 0, "surviving boss must block story transition"):
		return
	game._clear_arena(false)
	await process_frame
	game.boss_pending = false
	game.rewards.earn_level()
	game.rewards.queue_chest(&"metal_crown", 5)
	game._begin_loot_collection()
	if not _check(game.rewards.step == PostWaveRewards.Step.LEVELS and game.rewards.pending_story == &"arrival_1" and not game.story_dialogue.visible, "story must queue after levels/chests/relics"):
		return
	game = await _resume(game)
	game.choice_panel.buttons[0].pressed.emit()
	if not _check(game.rewards.step == PostWaveRewards.Step.CHESTS and not game.story_dialogue.visible, "story interrupted chest decision"):
		return
	game.choice_panel.buttons[0].pressed.emit()
	if not _check(game.rewards.step == PostWaveRewards.Step.RELICS and not game.story_dialogue.visible, "story interrupted relic decision"):
		return
	game.choice_panel.buttons[0].pressed.emit()
	if not _check(game.rewards.step == PostWaveRewards.Step.STORY and game.story_dialogue.visible and game.story.chapter_index == 0 and game.story.revealed_chapters == 1, "next world revealed before arrival"):
		return
	game = await _resume(game)
	if not _check(game.story.dialogue_line == 0 and game.story.chapter_index == 0 and game.rewards.pending_story == &"arrival_1", "pre-arrival resume lost current world"):
		return
	game._on_story_advance()
	game._on_story_advance()
	if not _check(game.story.chapter_index == 0 and not game.story_travel.visible, "departure revealed the next world"):
		return
	game._on_story_advance()
	if not _check(game.story_travel.visible and not game.story_dialogue.visible and paused, "departure must open the travel screen"):
		return
	game.story_travel.advance()
	game.story_travel.advance()
	if not _check(game.story.chapter_index == 1 and game.story.revealed_chapters == 2 and game.arena.floor_texture == StoryCatalog.chapter(1).floor_texture, "arrival did not reveal and apply sugar arena"):
		return
	game = await _resume(game)
	if not _check(game.story.dialogue_line == 3 and game.story.chapter_index == 1 and game.story.revealed_chapters == 2, "mid-arrival resume lost reveal or cursor"):
		return
	_finish_dialogue(game)
	if not _check(game.in_shop and game.shop_panel.visible and not game.story_dialogue.visible, "transition must return to a usable shop"):
		return
	game.coins = 200
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		await _resize(extent)
		game._update_shop_panel()
		for frame in 8:
			await process_frame
		var ui: ShopPanel = game.shop_panel
		var timeline: StoryTimeline = ui.story_timeline
		if not _check(timeline.visible and Rect2(Vector2.ZERO, Vector2(extent)).encloses(timeline.get_global_rect()) and timeline.get_global_rect().end.y <= ui.main_scroll.global_position.y, "timeline overlaps shop or viewport at %s" % extent):
			return
		for index in 4:
			var known := index < 2
			if not _check((timeline.preview_images[index].texture != null) == known and (timeline.preview_labels[index].text != "Unentdeckt") == known and (timeline.preview_panels[index].tooltip_text != "") == known, "future preview leaks image, name or tooltip"):
				return
		await _capture("shop_%dx%d" % [extent.x, extent.y])
	await _resize(Vector2i(1280, 720))
	for milestone in [10, 15]:
		game._on_shop_continue()
		game.wave.active = false
		game.wave.current_wave = milestone
		game._clear_arena(false)
		await process_frame
		game._begin_loot_collection()
		if game.rewards.step == PostWaveRewards.Step.RELICS:
			game.choice_panel.buttons[0].pressed.emit()
		var previous: int = game.story.chapter_index
		if not _check(game.story_dialogue.visible and previous == milestone / 5 - 1, "chapter advanced before arrival dialogue"):
			return
		_finish_dialogue(game)
		if not _check(game.in_shop and game.story.chapter_index == milestone / 5 and game.story.revealed_chapters == milestone / 5 + 1 and game.arena.floor_texture == StoryCatalog.chapter(game.story.chapter_index).floor_texture, "milestone failed to change stage"):
			return
		game = await _resume(game)
		if not _check(game.in_shop and not game.story_dialogue.visible, "shop resume replayed completed dialogue"):
			return
		await _capture("chapter_%d_shop" % game.story.chapter_index)
	game._on_shop_continue()
	game.wave.active = false
	game.wave.current_wave = 20
	game._clear_arena(false)
	await process_frame
	game.rewards.earn_level()
	game._begin_loot_collection()
	if not _check(not game.ended and game.rewards.step == PostWaveRewards.Step.LEVELS, "finale skipped final rewards"):
		return
	game.choice_panel.buttons[0].pressed.emit()
	if not _check(game.story.dialogue_id == &"finale" and not game.ended, "victory appeared before epilogue"):
		return
	_finish_dialogue(game)
	if not _check(game.ended and game.base_victory and not session.has_run(), "story did not finish after epilogue"):
		return
	game._on_endless_requested()
	game._on_shop_continue()
	if not _check(game.wave.current_wave == 21 and game.story.completed_boss_wave == 20 and not game.story_dialogue.visible, "endless replayed story"):
		return
	if capture:
		paused = true
		game.wave.active = false
		for index in 4:
			game.arena.set_story_chapter(StoryCatalog.chapter(index))
			game.player.global_position = Vector2(540, 350)
			game.player.get_node("Camera2D").force_update_scroll()
			await _capture("arena_%d" % index)
	# Old saves remain ordinary arena runs even if the menu mode was Story.
	var old: Dictionary = game.RUN_SNAPSHOT.capture(game)
	old.erase("story")
	game._restore_run(old)
	if not _check(not game.story.enabled and game.arena.floor_texture == DentiArena.FLOOR, "old save was silently converted to story"):
		return
	paused = false
	game.queue_free()
	await process_frame
	session.clear_run()
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	var story_button: Button
	for child in menu.rows.get_children():
		if child is Button and child.text == "Story-Modus":
			story_button = child
	if not _check(story_button != null, "main menu lacks story entry"):
		return
	story_button.pressed.emit()
	if not _check(session.selected_story_mode and menu.page == &"difficulty", "story entry did not preserve mode through difficulty selection"):
		return
	menu._new_game()
	if not _check(not session.selected_story_mode, "classic new game inherited story selection"):
		return
	session.clear_run()
	print("Denti story flow, save/fog, classic compatibility and responsive UI test passed")
	quit(0)

func _finish_dialogue(game: Node2D) -> void:
	for index in 32:
		if game.story_travel.visible:
			game.story_travel.advance()
			continue
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

func _capture(name: String) -> void:
	if not capture:
		return
	await create_timer(0.24, true).timeout
	for frame in 15:
		await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(capture_dir + "/" + name + ".png")

func _check(ok: bool, message: String) -> bool:
	if ok:
		return true
	paused = false
	session.clear_run()
	push_error(message)
	quit(1)
	return false
