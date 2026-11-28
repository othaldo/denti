extends "res://tests/support/test_runtime.gd"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_music_run.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	var music: MusicController = game.music
	check(music.current_cue == &"intermission", "starter menu should play the intermission cue")
	_settle(music)
	music.player.seek(18.0)
	choose_panel(game.choice_panel, 0)
	var arena_deck := music.player
	check(music.current_cue == &"arena" and arena_deck.playing and music.outgoing.playing, "wave one did not crossfade from the starter menu")
	_settle(music)
	check(is_equal_approx(arena_deck.volume_db, MusicController.PLAY_DB) and not music.outgoing.playing, "crossfade did not settle")

	game.wave.current_wave = 4
	game.wave.horde_spawned = true
	game._sync_music()
	check(music.player == arena_deck and music.current_cue == &"arena", "normal waves or hordes restarted the arena music")
	arena_deck.seek(20.0)
	game.rewards.weapon_upgrades.points = 4
	game._spawn_loot(game.player.global_position + Vector2(480.0, 0.0), &"xp", 5)
	game._spawn_loot(game.player.global_position + Vector2(570.0, 0.0), &"chest", 4, &"metal_crown")
	game.wave._process(game.wave.remaining)
	var intermission_deck := music.player
	check(game.collecting_wave_loot and not game.choice_panel.visible, "wave did not begin its loot sweep")
	check(music.current_cue == &"intermission" and intermission_deck.playing, "loot sweep did not start intermission music")
	check(intermission_deck.get_playback_position() < 0.5, "intermission resumed in the middle of its arrangement")
	check(arena_deck.playing and music.outgoing == arena_deck, "wave end cut the arena music instead of fading")
	music._process(1.0)
	check(arena_deck.playing and arena_deck.volume_db < MusicController.PLAY_DB - 1.0, "combat music did not start fading at wave end")
	check(intermission_deck.volume_db < MusicController.PLAY_DB - 10.0, "the quiet intermission opening rose too fast")
	var arena_gain_after_one_second := arena_deck.volume_db
	music._process(1.0)
	check(arena_deck.playing and arena_deck.volume_db < arena_gain_after_one_second - 4.0, "combat music did not fade gradually into intermission")
	check(intermission_deck.volume_db > MusicController.PLAY_DB - 6.0 and intermission_deck.volume_db < MusicController.PLAY_DB, "intermission did not gradually approach its target volume")
	_settle(music)
	check(not arena_deck.playing and arena_deck.stream == null, "combat music did not finish its intermission fade")
	var remembered_position: float = music._positions.get(&"arena", 0.0)
	check(absf(remembered_position - 20.0) < 1.0, "wave end did not remember the arena playhead")
	for frame in 180:
		if game.choice_panel.visible:
			break
		await physics_frame
	check(game.choice_panel.mode == &"upgrade" and game.choice_panel.visible and paused, "wave did not open level-up choices")
	intermission_deck.seek(8.0)
	_check_intermission(music, intermission_deck, "level-up")
	choose_panel(game.choice_panel, 0)
	check(game.choice_panel.mode == &"chest", "wave did not open its chest choice")
	_check_intermission(music, intermission_deck, "chest choice")
	choose_panel(game.choice_panel, 0)
	check(game.weapon_enchantment_panel.visible, "wave did not open weapon upgrades")
	_check_intermission(music, intermission_deck, "weapon upgrades")
	game._on_weapon_upgrades_completed()
	check(game.in_shop and game.shop_panel.visible, "reward queue did not open the shop")
	_check_intermission(music, intermission_deck, "shop")
	game._on_shop_enchant()
	check(game.weapon_enchantment_panel.visible, "shop did not open its workbench")
	_check_intermission(music, intermission_deck, "shop workbench")
	game._on_weapon_upgrades_completed()
	game.wave.current_wave = 3
	game._on_shop_continue()
	check(music.current_cue == &"arena" and music.player.get_playback_position() >= 19.0, "arena did not resume after the shop")
	check(music.player.volume_db <= MusicController.SILENT_DB and music.outgoing == intermission_deck and intermission_deck.playing, "shop exit did not start the battle track at low gain")
	music._process(0.5)
	check(music.player.volume_db < MusicController.PLAY_DB - 20.0, "battle music became too loud immediately after leaving the shop")
	music._process(0.5)
	check(music.player.volume_db < MusicController.PLAY_DB - 10.0 and music.outgoing.playing, "shop music faded out too quickly into combat")
	music._process(1.0)
	check(music.player.volume_db > MusicController.PLAY_DB - 6.0 and music.player.volume_db < MusicController.PLAY_DB, "battle music did not rise gradually after the shop")
	_settle(music)

	for pair in [[5, &"boss"], [10, &"boss_alt"], [11, &"arena_late"], [15, &"boss"], [20, &"finale"]]:
		game.wave.current_wave = pair[0]
		game._sync_music()
		check(music.current_cue == pair[1] and music.player.playing, "missing music for wave %s" % pair[0])
		_settle(music)

	game.boss_pending = true
	game.wave.active = false
	game._sync_music()
	check(music.current_cue == &"finale_overtime", "final boss overtime must raise the musical intensity")
	game._spawn_enemy(WaveController.FINAL_BOSS)
	game.boss.health -= 10.0
	game._process(8.1)
	var saved: Dictionary = session.load_run()
	check(bool(saved.get("boss_pending", false)) and not saved.get("enemies", []).is_empty(), "boss overtime was not autosaved")
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	music = game.music
	check(music.current_cue == &"finale_overtime" and music.player.playing and game.boss_pending, "continued run did not restore final boss overtime music")
	_settle(music)
	var boss_deck := music.player
	var boss_track := boss_deck.stream
	game._begin_loot_collection()
	check(music.current_cue == &"victory" and music.player.playing, "instant loot collection did not start victory music")
	check(boss_deck.playing and music.outgoing == boss_deck, "victory cut the outgoing battle track early")
	_settle(music)
	check(not boss_deck.playing or boss_deck.stream != boss_track, "boss music survived into the victory screen")
	game._on_endless_requested()
	check(music.current_cue == &"intermission", "continuing past victory should restore the intermission music")
	for pair in [[21, &"endless"], [25, &"finale"], [26, &"endless_alt"], [29, &"endless_alt"], [30, &"endless_double"], [31, &"endless"], [36, &"endless_alt"]]:
		music.play_wave(pair[0], &"palace")
		check(music.current_cue == pair[1], "missing Endless music for wave %s" % pair[0])
	game._on_player_died()
	_settle(music)
	check(music.current_cue == &"" and not music.player.playing and not music.outgoing.playing, "defeat should fade out both players")

	for path: String in MusicController.CUES.values():
		var track := load(path) as AudioStreamOggVorbis
		check(track != null and track.loop and track.get_length() - track.loop_offset > 20.0, "invalid soundtrack loop: %s" % path)
	session.clear_run()
	finish_checks()


func _settle(music: MusicController) -> void:
	music._process(MusicController.FADE_DURATION)


func _check_intermission(music: MusicController, deck: AudioStreamPlayer, screen: String) -> void:
	check(music.current_cue == &"intermission" and music.player == deck and deck.playing and deck.get_playback_position() >= 7.5 and not music.outgoing.playing, "intermission music interrupted at %s" % screen)
