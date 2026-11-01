extends "res://tests/support/test_runtime.gd"

var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _run() -> void:
	# Desktop system fonts must not hide glyphs missing from an exported game.
	var primary_font := DentiUIStyle.FONT
	var symbol_font := DentiUIStyle.SYMBOL_FONT
	primary_font.allow_system_fallback = false
	symbol_font.allow_system_fallback = false
	for theme in [DentiUIStyle.make_theme(), MenuStyle.make_theme()]:
		_check_bundled_glyphs(theme.default_font, "ÄÖÜäöüß 58 % → 60 % · MAX")
		_check_bundled_arrow(theme.default_font)
	var stats := new_stats()
	var cases: Array = [
		["zahnflutsch", 0.30, 1, "30 % → 33 % · max. 60 %"],
		["zahnflutsch", 0.57, 1, "57 % → 60 % · MAX"],
		["zahnflutsch", 0.58, 4, "58 % → 60 % · MAX"],
		["zahnflutsch", 0.70, 4, "60 % → 60 % · MAX"],
		["zahnflutsch", -0.05, 1, "0 % → 0 % · max. 60 %"],
		["glanz", 0.25, 1, "25 % → 30 % · max. 65 %"],
		["glanz", 0.64, 4, "64 % → 65 % · MAX"],
		["glanz", 0.65, 1, "65 % → 65 % · MAX"],
		["wurzelkraft", 0.0, 1, "100 → 125 · max. 500"],
		["wurzelkraft", -10.0, 1, "100 → 115 · max. 500"],
		["wurzelkraft", 385.0, 4, "485 → 500 · MAX"],
		["wurzelkraft", 440.0, 1, "500 → 500 · MAX"],
		["bisskraft", -10.0, 2, "-10 % → -2 %"],
		["haerte", 7.5, 2, "7.5 → 9.5"],
		["schmelz", 120.0, 2, "120 HP → 155 HP"],
		["putzeifer", 20.0, 2, "20 % → 30 %"],
		["bewegung", -3.0, 2, "-3 % → 3 %"],
		["speichel", 3.0, 2, "3 → 5"],
		["nahschaden", 4.0, 2, "4 → 8"],
		["fernschaden", 6.0, 3, "6 → 9"],
		["zahnglueck", 20.0, 2, "20 → 40"],
	]
	for entry: Array in cases:
		var upgrade := (load("res://data/upgrades/%s.tres" % entry[0]) as UpgradeData).with_tier(entry[2])
		stats.set(upgrade.stat, entry[1])
		upgrade.with_stat_context(stats)
		var before := stats.to_save_data()
		var rng_state := stats.dodge_rng.state
		var preview := DentiAttributes.upgrade_preview_text(stats, DentiAttributes.from_key(upgrade.stat), upgrade.amount)
		_check(preview == entry[3], "wrong preview for %s: %s" % [entry[0], preview])
		_check_bundled_glyphs(DentiUIStyle.make_theme().default_font, preview)
		_check(stats.to_save_data() == before and stats.dodge_rng.state == rng_state, "preview changed the real build")
	await _test_reward_flow()
	if failures == 0:
		print("PASS upgrade previews: values, caps, raw penalties, queued choices, rerolls and resume")
	finish(0 if failures == 0 else 1)


func _check_bundled_glyphs(font: Font, text: String) -> void:
	var text_server := TextServerManager.get_primary_interface()
	for index in text.length():
		var code := text.unicode_at(index)
		if code <= 32:
			continue
		var supported := false
		for rid in font.get_rids():
			if text_server.font_has_char(rid, code):
				supported = true
				break
		_check(supported, "preview lacks a bundled glyph for U+%04X: %s" % [code, text])


func _check_bundled_arrow(font: Font) -> void:
	var line := TextLine.new()
	line.add_string("\u2192", font, 16)
	var glyphs := TextServerManager.get_primary_interface().shaped_text_get_glyphs(line.get_rid())
	var symbols := font.fallbacks[0] as FontVariation
	_check(symbols != null and symbols.base_font == DentiUIStyle.SYMBOL_FONT and glyphs.size() == 1 and glyphs[0].index != 0 and glyphs[0].font_rid in symbols.get_rids(), "arrow was not shaped from the bundled symbol font")


func _test_reward_flow() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://upgrade_preview_run.json"
	session.resume_requested = false
	session.selected_story_mode = false
	session.reduced_ui_motion = true
	session.pending_start_weapon_id = &"magic_toothbrush"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.wave.active = false
	game.wave.set_process(false)
	paused = true
	game.player.stats.dodge_chance = 0.58
	game.player.stats.crit_chance = 0.64
	game.player.stats.dash_recovery_bonus = 385.0
	game.rewards.pending_levels = 2
	game.rewards.step = PostWaveRewards.Step.LEVELS
	game.level = 3
	var choices: Array[UpgradeData] = []
	for id in ["zahnflutsch", "glanz", "wurzelkraft", "schmelz"]:
		choices.append(load("res://data/upgrades/%s.tres" % id).with_tier(4).with_stat_context(game.player.stats))
	game.choice_panel.show_upgrades(choices, game.player.stats)
	for button in game.choice_panel.buttons:
		var card := button as RewardCard
		_check_bundled_glyphs(card.preview_label.get_theme_font("font"), card.preview_label.text)
		_check_bundled_arrow(card.preview_label.get_theme_font("font"))
	_check((game.choice_panel.buttons[0] as RewardCard).preview_label.text.replace("\n", " ") == "58 % → 60 % · MAX", "real card hides the cap-reaching value")
	game._save_run()
	game.free()
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	_check((game.choice_panel.buttons[0] as RewardCard).preview_label.text.replace("\n", " ") == "58 % → 60 % · MAX", "resume lost live stat context")
	_check((game.choice_panel.buttons[2] as RewardCard).preview_label.text.replace("\n", " ") == "485 → 500 · MAX", "resume showed the stamina bonus instead of total capacity")
	if "--capture" in OS.get_cmdline_user_args():
		var directory := ProjectSettings.globalize_path("res://.godot/upgrade-preview")
		DirAccess.make_dir_recursive_absolute(directory)
		for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(568, 320)]:
			root.content_scale_size = session.mobile_base_size(extent) if extent.x < 700 else Vector2i(1280, 720)
			root.size = extent
			for frame in 12: await process_frame
			root.get_texture().get_image().save_png(directory.path_join("levelup_%dx%d.png" % [extent.x, extent.y]))
	choose_panel(game.choice_panel, 0)
	_check(is_equal_approx(game.player.stats.effective_dodge_chance(), 0.60), "choosing the card differs from its preview")
	_check(game.rewards.pending_levels == 1, "preview interfered with queued choices")
	_check_live_cards(game)
	game.coins = 1000
	game._on_level_reroll()
	_check_live_cards(game)
	game.choice_panel.show_chest(ShopController.by_id(&"metal_crown"), 7)
	_check(not (game.choice_panel.buttons[0] as RewardCard).preview_label.visible, "chest reused a stale level-up preview")
	game.free()
	paused = false
	session.clear_run()


func _check_live_cards(game: Node2D) -> void:
	for index in game.choice_panel.current_upgrades.size():
		var upgrade: UpgradeData = game.choice_panel.current_upgrades[index]
		var expected := DentiAttributes.upgrade_preview_text(game.player.stats, DentiAttributes.from_key(upgrade.stat), upgrade.amount)
		var card := game.choice_panel.buttons[index] as RewardCard
		_check(card.preview_label.visible and card.preview_label.text.replace("\n", " ") == expected, "new choice uses stale values: " + str(upgrade.stat))
