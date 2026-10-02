extends SceneTree

var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)

func _seed_for(stats: PlayerStats, evade: bool) -> void:
	var probe := RandomNumberGenerator.new()
	for value in 1000:
		probe.seed = value
		if (probe.randf() < stats.effective_dodge_chance()) == evade:
			stats.dodge_rng.seed = value
			return
	_check(false, "could not find deterministic incoming-hit roll")

func _run() -> void:
	var plain := PlayerStats.new()
	_check(plain.dodge_chance == 0.0 and plain.effective_dodge_chance() == 0.0, "base Denti gained free evasion")
	plain.apply_upgrade(&"dodge_chance", 0.8)
	plain.apply_upgrade(&"dodge_chance", -0.1)
	_check(is_equal_approx(plain.dodge_chance, 0.7) and plain.effective_dodge_chance() == 0.6, "cap discarded the raw bonus")
	plain.apply_upgrade(&"dodge_chance", -0.3)
	_check(is_equal_approx(plain.effective_dodge_chance(), 0.4), "later penalty did not apply to the raw bonus")
	plain.dodge_chance = -0.2
	_check(plain.effective_dodge_chance() == 0.0 and plain.take_damage(10.0) == 10.0, "negative dodge changed incoming damage")
	plain.dodge_chance = 5.0
	plain.dodge_rng.seed = 7654
	var probe := RandomNumberGenerator.new()
	probe.seed = 7654
	var expected := 0
	var observed := 0
	for index in 2000:
		plain.health = 100.0
		if probe.randf() < 0.60:
			expected += 1
		if plain.take_damage(10.0) == 0.0:
			observed += 1
	_check(observed == expected and observed > 0 and observed < 2000, "rolls bypassed the 60 percent cap")
	_check(plain.take_damage(10.0, false) == 10.0, "non-dodgeable damage was avoided")
	plain.load_save_data({"stat_model_version": 3, "damage_bonus": 42.0})
	_check(plain.dodge_chance == 0.0 and plain.damage_bonus == 42.0, "old save inherited dodge or lost damage")
	plain.free()
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_dodge.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	paused = true
	var player: Player = game.player
	var stats: PlayerStats = player.stats
	stats.dodge_chance = 0.6
	stats.health = 80.0
	stats.shield_charges = 1
	_seed_for(stats, true)
	var before_rng := stats.dodge_rng.state
	player.hurt_time = 0.2
	player.take_hit(30.0)
	_check(stats.dodge_rng.state == before_rng and stats.shield_charges == 1, "hurt i-frames rolled dodge or consumed shield")
	player.hurt_time = 0.0
	player.take_hit(30.0)
	_check(stats.health == 80.0 and stats.shield_charges == 1 and player.hurt_time == 0.0, "dodge lost HP, shield, or started red hurt feedback")
	_check(player.dodge_time == Player.DODGE_IFRAMES and player.expressions.current_face == DentiExpressions.Face.DODGE, "actual dodge did not trigger protection and wink")
	_check(game.telemetry.dodges == 1 and game.telemetry.damage_taken == 0.0, "dodge counted as received damage")
	before_rng = stats.dodge_rng.state
	player.take_hit(30.0)
	_check(stats.dodge_rng.state == before_rng and game.telemetry.dodges == 1, "same-frame hits retriggered dodge procs")
	player.dodge_time = 0.0
	_seed_for(stats, false)
	player.take_hit(30.0)
	_check(stats.health == 80.0 and stats.shield_charges == 0, "failed dodge did not fall back to shield")
	_seed_for(stats, false)
	player.take_hit(30.0)
	_check(stats.health == 50.0 and player.hurt_time > 0.0 and game.telemetry.damage_taken == 30.0, "failed dodge bypassed normal damage feedback")
	player.hurt_time = 0.0
	player.expressions.reaction_remaining = 0.0
	stats.dodge_chance = 0.0
	for index in 3:
		_check(game.items.acquire(ShopController.by_id(&"dodge_3")), "cannot acquire healing dodge stack")
	_check(game.items.acquire(ShopController.by_id(&"dodge_4")), "cannot mix shield variant")
	_check(not game.items.acquire(ShopController.by_id(&"dodge_1")), "mixed dodge variants bypass family limit")
	_check(is_equal_approx(stats.dodge_chance, 0.43), "dodge item bonuses not additive")
	_seed_for(stats, true)
	player.take_hit(30.0)
	_check(stats.health == 53.0 and game.items.dodge_guard_progress == 1, "actual dodge did not heal per copy or progress shield")
	player.dodge_time = 0.0
	_seed_for(stats, true)
	player.take_hit(30.0)
	_check(stats.health == 53.0 and game.items.dodge_guard_progress == 2, "healing cooldown failed or guard progress was lost")
	game._open_shop()
	game._save_run()
	var saved_chance := stats.dodge_chance
	var saved_dodges: int = game.telemetry.dodges
	game.free()
	session.resume_requested = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	player = game.player
	stats = player.stats
	_check(is_equal_approx(stats.dodge_chance, saved_chance) and game.items.family_count(&"dodge") == 4, "resume lost or reapplied dodge bonuses")
	_check(player.dodge_time == Player.DODGE_IFRAMES and game.items.dodge_guard_progress == 2 and float(game.items.cooldowns.get("dodge_heal", 0.0)) > 0.0, "resume reset protection, proc progress or cooldown")
	_check(game.telemetry.dodges == saved_dodges and game.shop_panel.stats_label.text.contains("Zahnflutsch 43 %"), "resume lost telemetry or live dodge display")
	player.dodge_time = 0.0
	_seed_for(stats, true)
	player.take_hit(30.0)
	_check(stats.shield_charges == 1 and game.items.dodge_guard_progress == 0, "third dodge did not grant exactly one shield")
	for index in 5:
		player.dodge_time = 0.0
		_seed_for(stats, true)
		player.take_hit(30.0)
	_check(stats.shield_charges == 1 and game.items.dodge_guard_progress == 0, "guard cooldown banked or generated more shields")
	game.items._process(8.1)
	player.dodge_time = 0.0
	_seed_for(stats, true)
	player.take_hit(30.0)
	_check(stats.health == 56.0 and game.items.dodge_guard_progress == 1, "expired healing/shield cooldowns did not recover")
	game.coins = 10000
	var mythic := ShopController.by_id(&"mythic_dodge").duplicate() as ShopOfferData
	game.shop.offers[0] = mythic
	game._update_shop_panel()
	game.shop_panel.offer_buttons[0].buy_button.pressed.emit()
	_check(is_equal_approx(stats.dodge_chance, 0.58) and game.shop_panel.stats_label.text.contains("Zahnflutsch 58 %"), "mythic purchase did not update live stats")
	_check(not game.items.can_acquire(mythic) and mythic.stat_changes.size() == 1 and mythic.effect_kind == &"", "mythic is not a unique pure bonus")
	stats.apply_upgrade(&"dodge_chance", 0.12)
	_check(game.shop_panel.stats_label.text.contains("Zahnflutsch 60 % (max.)"), "shop shows uncapped dodge")
	var icon := DentiUIIcons.stat(10) as AtlasTexture
	_check(icon.atlas == DentiUIIcons.DODGE_ATLAS and icon.get_size() == Vector2(512, 512), "dodge attribute lacks dedicated painted icon")
	_check(game.UPGRADES.back().stat == &"dodge_chance" and game.UPGRADES.back().with_tier(4).effect_text() == "+12 % Zahnflutsch", "dodge level-up has wrong stat or percent units")
	var debug_menu: DebugCheatMenu = game.get_node("DebugCheatMenu")
	debug_menu.open_menu()
	_check(is_equal_approx(debug_menu.stats["dodge_chance"].value, 70.0), "debug menu displays a fraction instead of percent")
	debug_menu.stats["dodge_chance"].value = 37.0
	debug_menu._apply_stats()
	_check(is_equal_approx(stats.dodge_chance, 0.37), "debug menu saved 37 percent as 37.0")
	debug_menu.close_menu()
	var total_dodges: int = game.telemetry.dodges
	game.telemetry.begin_wave(2)
	_check(game.telemetry.wave_dodges == 0 and game.telemetry.dodges == total_dodges, "new wave reset total dodges or retained wave counter")
	game.free()
	paused = false
	session.clear_run()
	if failures == 0:
		print("PASS dodge")
	quit(0 if failures == 0 else 1)
