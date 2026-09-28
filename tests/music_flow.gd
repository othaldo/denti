extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_music_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	var music: MusicController = game.music
	if music.current_cue != &"wave_1" or not music.playing or music.stream.loop or music.fade_state != MusicController.FadeState.FADING_IN:
		_fail("first wave did not start with a fade-in")
		return
	music._process(MusicController.FADE_DURATION)
	game.wave.current_wave = 2
	game._sync_music()
	if music.current_cue != &"wave_1" or music.fade_state != MusicController.FadeState.PLAYING:
		_fail("normal wave change interrupted the current song")
		return
	game.wave.current_wave = 4
	game.wave.horde_spawned = true
	game._sync_music()
	game.wave.active = false
	game.in_shop = true
	game._sync_music()
	if music.current_cue != &"wave_1" or not music.playing:
		_fail("shop interrupted the current song")
		return
	game.in_shop = false
	game.wave.active = true
	if music.current_cue != &"wave_1":
		_fail("horde replaced normal wave music")
		return
	music.seek(music.stream.get_length() - MusicController.FADE_DURATION * 0.5)
	music._process(0.01)
	if music.fade_state != MusicController.FadeState.FADING_OUT or music.queued_cue != &"wave_2":
		_fail("song end did not start fading toward the next wave track")
		return
	music._process(MusicController.FADE_DURATION)
	if music.current_cue != &"wave_2" or music.fade_state != MusicController.FadeState.FADING_IN:
		_fail("wave playlist did not continue after fade-out")
		return
	music._process(MusicController.FADE_DURATION)
	game.wave.current_wave = 5
	game.wave.horde_spawned = false
	game._sync_music()
	if music.current_cue != &"wave_2" or music.queued_cue != &"mini_boss_1":
		_fail("wave five cut off music before the boss fade")
		return
	_complete_switch(music)
	if music.current_cue != &"mini_boss_1":
		_fail("wave five did not fade into mini-boss music")
		return
	music.seek(music.stream.get_length() - MusicController.FADE_DURATION * 0.5)
	music._process(0.01)
	if music.queued_cue != &"mini_boss_1":
		_fail("mini-boss music did not schedule its next loop")
		return
	_complete_switch(music)
	if music.current_cue != &"mini_boss_1" or not music.playing:
		_fail("mini-boss music did not restart with a fade")
		return
	game.wave.current_wave = 10
	game._sync_music()
	_complete_switch(music)
	if music.current_cue != &"mini_boss_2":
		_fail("wave ten did not start second mini-boss music")
		return
	game.wave.current_wave = 15
	game._sync_music()
	_complete_switch(music)
	if music.current_cue != &"mini_boss_1":
		_fail("wave fifteen did not return to first mini-boss music")
		return
	game.wave.active = false
	game.in_shop = true
	game._sync_music()
	if not music.playing or music.current_cue != &"mini_boss_1":
		_fail("mini-boss music stopped in the shop")
		return
	game.in_shop = false
	game.wave.active = true
	game.wave.current_wave = 20
	game.wave.horde_spawned = false
	game._sync_music()
	_complete_switch(music)
	if music.current_cue != &"final_boss_1":
		_fail("final wave did not start boss music")
		return
	game.boss_pending = true
	game.wave.active = false
	game._sync_music()
	_complete_switch(music)
	if music.current_cue != &"final_boss_2":
		_fail("boss overtime did not change music")
		return
	game._spawn_enemy(WaveController.FINAL_BOSS)
	game.boss.health -= 10.0
	game._process(8.1)
	var saved: Dictionary = session.load_run()
	if not bool(saved.get("boss_pending", false)) or saved.get("enemies", []).is_empty():
		_fail("boss overtime was not autosaved")
		return
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	if game.music.current_cue != &"final_boss_2" or not game.music.playing or not game.boss_pending or not is_instance_valid(game.boss):
		_fail("continued run did not restore the matching music")
		return
	game._finish_run()
	game.music._process(MusicController.FADE_DURATION)
	if game.music.playing or game.music.current_cue != &"":
		_fail("music did not fade out after the run")
		return
	session.clear_run()
	paused = false
	print("Denti music flow test passed")
	quit(0)


func _complete_switch(music: MusicController) -> void:
	music._process(MusicController.FADE_DURATION)
	music._process(MusicController.FADE_DURATION)


func _fail(message: String) -> void:
	paused = false
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
