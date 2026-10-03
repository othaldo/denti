extends SceneTree

const GAME: PackedScene = preload("res://scenes/game/game.tscn")
var session: Node
var capture: bool
var capture_dir: String

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://test_travel_run.json"
	session.progression_path = "user://test_travel_progression.cfg"
	session.report_dir = "user://test_travel_reports"
	session.clear_run()
	session.selected_story_mode = true
	session.resume_requested = false
	session.reduced_ui_motion = false
	capture = "--capture" in OS.get_cmdline_user_args()
	capture_dir = ProjectSettings.globalize_path("res://.godot/story-travel-preview")
	if capture:
		DirAccess.make_dir_recursive_absolute(capture_dir)
	await _resize(Vector2i(1280, 720))
	var game: Node2D = GAME.instantiate()
	root.add_child(game)
	current_scene = game
	while game.story_dialogue.visible:
		game._on_story_advance()
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game._clear_arena(false)
	await process_frame
	for target in range(1, 4):
		game.wave.current_wave = target * 5
		game.rewards.pending_story = StringName("arrival_%d" % target)
		game.rewards.step = PostWaveRewards.Step.STORY
		game.story.begin_dialogue(game.rewards.pending_story, &"shop")
		game._show_story_line()
		game._on_story_advance()
		game._on_story_advance()
		game._on_story_advance()
		game.story_travel.set_process(false)
		if not _check(game.story_travel.visible and paused and game.story.chapter_index == target - 1 and not game.story_dialogue.visible and not game.shop_panel.visible and not game.wave.active, "travel must be its own paused intermission"):
			return
		game.story_travel._process(StoryTravel.DURATION * 0.35)
		if not _fog(game, target):
			return
		var moving_x: float = game.story_travel.denti.position.x
		game = await _resume(game)
		if not _check(game.story_travel.visible and is_equal_approx(game.story.travel_progress, 0.35) and is_equal_approx(moving_x, game.story_travel.denti.position.x) and game.story.chapter_index == target - 1, "resume lost journey progress or revealed destination"):
			return
		game.story_travel._process(StoryTravel.DURATION * 0.45)
		if not _check(game.story.chapter_index == target and game.story.revealed_chapters == target + 1 and game.arena.floor_texture == StoryCatalog.chapter(target).floor_texture and game.story_travel.cards[target].scale.x > 0.5 and game.story_travel.cards[target].scale.x < 1, "arrival failed to reveal and animate destination"):
			return
		game = await _resume(game)
		if not _check(game.story.chapter_index == target and is_equal_approx(game.story.travel_progress, 0.8) and game.story_travel.cards[target].art.texture != null, "resume lost partial reveal"):
			return
		if target == 1:
			game.story_travel.advance()
		else:
			game.story_travel._process(StoryTravel.DURATION * 0.2)
		if not _check(game.story_travel.visible and game.story_travel.next_button.text == "Weiter" and game.story.travel_progress == 1, "fast-forward must leave the completed reveal visible"):
			return
		if not _check(float(session.load_run().story.travel_progress) == 1, "completed reveal must persist without a manual save"):
			return
		for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(1280, 720), Vector2i(1920, 1080)]:
			await _resize(extent)
			var travel: StoryTravel = game.story_travel
			var bounds := Rect2(Vector2.ZERO, Vector2(extent))
			if not _check(bounds.encloses(travel.logo.get_global_rect()) and bounds.encloses(travel.heading.get_global_rect()) and bounds.encloses(travel.next_button.get_global_rect()) and bounds.encloses(travel.route.get_global_rect()), "travel escapes viewport at %s" % extent):
				return
			for card in travel.cards:
				if card.visible and not _check(bounds.encloses(card.get_global_rect()) and card.get_global_rect().end.y <= travel.route.global_position.y, "card overlaps journey route at %s" % extent):
					return
			if not _fog(game, target + 1):
				return
			await _capture("chapter_%d_%dx%d" % [target, extent.x, extent.y])
		game = await _resume(game)
		if not _check(game.story_travel.visible and game.story.travel_progress == 1, "completed travel should wait for Continue after resume"):
			return
		game.story_travel.advance()
		if not _check(game.story.travel_target == -1 and game.story_dialogue.visible and game.story.dialogue_line == 3, "Continue must finish travel and show arrival dialogue"):
			return
		game._on_story_advance()
		if not _check(game.shop_panel.visible and game.in_shop, "arrival did not return to shop"):
			return
	# The same arrival contract applies with reduced motion, without requiring a wait.
	game.story.chapter_index = 0
	game.story.revealed_chapters = 1
	game.story.begin_dialogue(&"arrival_1", &"shop")
	game.story.dialogue_line = 2
	game._show_story_line()
	session.reduced_ui_motion = true
	game._on_story_advance()
	if not _check(game.story.travel_progress == 1 and game.story.chapter_index == 1 and game.story_travel.cards[1].scale == Vector2.ONE, "reduced motion must reveal instantly"):
		return
	game.story_travel.advance()
	session.reduced_ui_motion = false
	paused = false
	game.queue_free()
	await process_frame
	session.clear_run()
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	for extent in [Vector2i(320, 568), Vector2i(1280, 720)]:
		await _resize(extent)
		if not _check(menu.title_logo != null and menu.title_logo.texture == StoryTravel.TITLE and Rect2(Vector2.ZERO, Vector2(extent)).encloses(menu.build_panel.get_global_rect()), "gold title or main menu does not fit %s" % extent):
			return
		await _capture("menu_%dx%d" % [extent.x, extent.y])
	print("Denti animated chapter travel, reveal/fog, save/resume, reduced motion and menu logo test passed")
	quit(0)

func _fog(game: Node2D, known: int) -> bool:
	for index in 4:
		var card: StoryTravelCard = game.story_travel.cards[index]
		if not _check((card.art.texture != null) == (index < known) and card.mystery.visible == (index >= known) and (card.caption.text == "Unentdeckt") == (index >= known), "travel exposes a future world"):
			return false
	return true

func _resume(game: Node2D) -> Node2D:
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await scene_changed
	current_scene.story_travel.set_process(false)
	await process_frame
	return current_scene

func _resize(extent: Vector2i) -> void:
	root.content_scale_size = extent
	root.size = extent
	if capture:
		DisplayServer.window_set_size(extent)
	for frame in 6:
		await process_frame

func _capture(name: String) -> void:
	if not capture:
		return
	await create_timer(0.25, true).timeout
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
