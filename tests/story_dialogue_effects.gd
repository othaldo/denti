extends SceneTree

var session: Node
var capture: bool
var capture_dir: String

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://test_story_dialogue_effects.json"
	session.report_dir = "user://test_story_dialogue_effects_reports"
	session.selected_story_mode = true
	session.resume_requested = false
	session.reduced_ui_motion = false
	session.ui_sounds = true
	session.master_volume_percent = 100
	session.sfx_volume_percent = 100
	session.apply_volume()
	session.clear_run()
	capture = "--capture" in OS.get_cmdline_user_args()
	capture_dir = ProjectSettings.globalize_path("res://.godot/story-dialogue-preview")
	if capture:
		DirAccess.make_dir_recursive_absolute(capture_dir)
	await _resize(Vector2i(1280, 720))
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var dialog: StoryDialogue = game.story_dialogue
	dialog.set_process(false)
	dialog.speech.set_process(false)
	game._show_story_line()
	for frame in 5:
		await process_frame
	if not _check(paused and dialog.revealing and dialog.body_label.visible_characters == 0 and dialog.next_button.text == "Anzeigen", "dialogue must start typing while combat is paused"):
		return
	dialog._process(0.04)
	if not _check(dialog.cursor == 1 and dialog.body_label.visible_characters == 1 and dialog.speech.syllable_index == 1 and dialog.speech.voice.bus == &"SFX", "paused typing must reveal letters and produce SFX syllables"):
		return
	await _capture("typing")
	var bounds := dialog.body_label.get_global_rect()
	dialog.next_button.pressed.emit()
	if not _check(game.story.dialogue_line == 0 and not dialog.revealing and dialog.body_label.visible_characters == -1 and not dialog.speech.voice.playing and dialog.next_button.text == "Weiter", "first click must reveal only, with no trailing speech"):
		return
	await process_frame
	if not _check(bounds == dialog.body_label.get_global_rect(), "typing/skip changed the dialogue layout"):
		return
	dialog.next_button.pressed.emit()
	if not _check(game.story.dialogue_line == 1 and dialog.speaker_label.text == "Zahnfee" and dialog.revealing and dialog.cursor == 0 and not dialog.speech.voice.playing, "second click must begin the next speaker cleanly"):
		return
	# Punctuation creates a real pause; a large frame cannot dump all text or cues.
	dialog.show_line({"speaker": "Denti", "text": "a,b"}, StoryCatalog.chapter(0), 0, 2)
	dialog._process(0.03)
	dialog._process(0.03)
	dialog._process(0.05)
	if not _check(dialog.cursor == 2 and dialog.revealing, "comma must pause the typing cadence"):
		return
	dialog._process(0.05)
	if not _check(not dialog.revealing and dialog.body_label.visible_characters == -1, "typing must finish naturally"):
		return
	dialog.show_line({"text": "abcdefghijklmnopqrstuvwxyz"}, StoryCatalog.chapter(0), 0, 2)
	dialog._process(10)
	if not _check(dialog.cursor <= 4 and dialog.revealing and dialog.speech.syllable_index <= 1, "inactive tab gap created a text/audio burst"):
		return
	# Six distinct, cached PCM profiles with silent endpoints and no randomness.
	var fingerprints: Array[int] = []
	for speaker in StorySpeech.PROFILES:
		var stream := StorySpeech.stream_for(speaker)
		var pcm := stream.data
		if not _check(stream == StorySpeech.stream_for(speaker) and stream.mix_rate == StorySpeech.SAMPLE_RATE and stream.format == AudioStreamWAV.FORMAT_16_BITS and pcm.size() > 2000 and pcm[0] == 0 and pcm[1] == 0 and pcm[-1] == 0 and pcm[-2] == 0 and not fingerprints.has(hash(pcm)), "speech profile is missing, duplicated or has non-silent endpoints"):
			return
		fingerprints.append(hash(pcm))
	# UI, master and SFX mute all gate sounds without changing the reveal.
	for setting in ["ui_sounds", "master_volume_percent", "sfx_volume_percent"]:
		dialog.speech.begin_line()
		session.set(setting, false if setting == "ui_sounds" else 0)
		dialog.speech.syllable("Denti", "a")
		if not _check(dialog.speech.syllable_index == 0 and not dialog.speech.voice.playing, "%s mute ignored by dialogue" % setting):
			return
		session.set(setting, true if setting == "ui_sounds" else 100)
	dialog.speech.begin_line()
	for glyph in [" ", ".", ",", "!", "—", "\n"]:
		dialog.speech.syllable("Denti", glyph)
	if not _check(dialog.speech.syllable_index == 0, "spaces/punctuation must not make speech sounds"):
		return
	dialog.speech.syllable("Denti", "ä")
	session.ui_sounds = false
	dialog.speech._process(0.01)
	if not _check(not dialog.speech.voice.playing, "muting mid-syllable leaves audio playing"):
		return
	session.ui_sounds = true
	session.reduced_ui_motion = true
	dialog._process(0.01)
	if not _check(not dialog.revealing and dialog.body_label.visible_characters == -1, "reduced motion toggled mid-line must finish the reveal"):
		return
	dialog.show_line({"text": "Sofort sichtbar.", "action": "Kämpfen"}, StoryCatalog.chapter(0), 0, 1)
	if not _check(not dialog.revealing and dialog.next_button.text == "Kämpfen" and not dialog.speech.voice.playing, "reduced motion must show full text silently"):
		return
	session.reduced_ui_motion = false
	# Resume preserves the story cursor; it retypes that sentence, never advances it.
	game._show_story_line()
	dialog._process(0.07)
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await scene_changed
	game = current_scene
	dialog = game.story_dialogue
	dialog.set_process(false)
	dialog.speech.set_process(false)
	if not _check(game.story.dialogue_line == 1 and paused and dialog.revealing and dialog.cursor == 0, "resume lost the current sentence or started combat"):
		return
	# Every revised line retains its full-text bounds at all relevant sizes.
	var ids := [&"intro", &"boss_0", &"arrival_1", &"boss_1", &"arrival_2", &"boss_2", &"arrival_3", &"boss_3", &"finale"]
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(1280, 720)]:
		await _resize(extent)
		for id in ids:
			var lines := StoryCatalog.dialogue(id)
			var chapter_index := 3 if id == &"finale" else 0
			if str(id).begins_with("boss_"):
				chapter_index = int(str(id).get_slice("_", 1))
			elif str(id).begins_with("arrival_"):
				chapter_index = int(str(id).get_slice("_", 1)) - 1
			game.arena.set_story_chapter(StoryCatalog.chapter(chapter_index))
			game.player.global_position = game.arena.arena_size / 2.0
			game.player.get_node("Camera2D").reset_smoothing()
			game.player.get_node("Camera2D").force_update_scroll()
			for index in lines.size():
				dialog.show_line(lines[index], StoryCatalog.chapter(chapter_index), index, lines.size())
				dialog.finish_reveal()
				for frame in 4:
					await process_frame
				var viewport_bounds := Rect2(Vector2.ZERO, Vector2(extent))
				if not _check(viewport_bounds.encloses(dialog.panel.get_global_rect()) and dialog.panel.get_global_rect().encloses(dialog.body_label.get_global_rect()) and dialog.panel.get_global_rect().encloses(dialog.next_button.get_global_rect()), "revised line escapes %s: %s/%d" % [extent, id, index]):
					return
				if id == &"arrival_3" and index == 1:
					await _capture("turn_%dx%d" % [extent.x, extent.y])
	# Even the last boss line requires reveal + a separate deliberate combat click.
	game.arena.set_story_chapter(StoryCatalog.chapter(game.story.chapter_index))
	while game.story_dialogue.visible:
		game._on_story_advance()
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	game.wave.current_wave = 4
	game._clear_arena(false)
	await process_frame
	game._open_shop()
	game._on_shop_continue()
	game.story.dialogue_line = StoryCatalog.dialogue(&"boss_0").size() - 1
	game._show_story_line()
	dialog.next_button.pressed.emit()
	if not _check(paused and not game.wave.active and game.wave.current_wave == 4 and dialog.next_button.text == "Kämpfen", "revealing the final boss line must not start combat"):
		return
	dialog.next_button.pressed.emit()
	if not _check(not paused and game.wave.active and game.wave.current_wave == 5 and not dialog.speech.voice.playing, "second boss click must start combat without leftover audio"):
		return
	if capture:
		_export_voice_demo()
	session.clear_run()
	print("Denti dialogue typing, speaker synthesis/mute, skip/pause, resume, boss gating and revised text layouts test passed")
	quit(0)

func _export_voice_demo() -> void:
	var pcm := PackedByteArray()
	for speaker in StorySpeech.PROFILES:
		var stream := StorySpeech.stream_for(speaker)
		for syllable in 8:
			pcm.append_array(stream.data)
			var gap := PackedByteArray()
			gap.resize(int(StorySpeech.SAMPLE_RATE * 0.045) * 2)
			pcm.append_array(gap)
		var pause := PackedByteArray()
		pause.resize(int(StorySpeech.SAMPLE_RATE * 0.4) * 2)
		pcm.append_array(pause)
	var demo := AudioStreamWAV.new()
	demo.format = AudioStreamWAV.FORMAT_16_BITS
	demo.mix_rate = StorySpeech.SAMPLE_RATE
	demo.data = pcm
	demo.save_to_wav(capture_dir + "/speaker-demo.wav")

func _resize(extent: Vector2i) -> void:
	root.content_scale_size = extent
	root.size = extent
	if capture:
		DisplayServer.window_set_size(extent)
	for frame in 5:
		await process_frame

func _capture(name: String) -> void:
	if not capture:
		return
	await create_timer(0.2, true).timeout
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
