extends "res://tests/support/test_runtime.gd"

var game: Node2D
var failures := 0
var session: Node

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _near(a: float, b: float, message: String) -> void:
	_check(is_equal_approx(a, b), "%s: %s != %s" % [message, a, b])

func _settle() -> void:
	for frame in 8: await process_frame

func _enemy(offset := Vector2(100, 0), data: EnemyData = WaveController.PLAQUE) -> Enemy:
	game._create_enemy(data, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.health = 10000
	enemy.max_health = 10000
	enemy.damage_reduction = 0
	return enemy

func _hit(enemy: Enemy) -> float:
	return WeaponAttackShapes.hit(enemy, WeaponCatalog.by_id(&"turbo_drill"), 1, 10, false, game.items, Vector2.RIGHT, [], 1, false)

func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://class_talents_test.json"
	session.clear_run()
	var profile := ClassCatalog.by_id(&"assassin")
	_check(profile != null and profile.valid() and ClassCatalog.DEFAULT.talent_tree.valid(), "shipping talent/class data invalid")
	await _selection()
	session.pending_start_class_id = &"assassin"
	session.pending_start_weapon_id = &"turbo_drill"
	session.pending_talent_run = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	_check(game.talents.enabled and game.wave.active and not game.choice_panel.visible, "prepared class run did not start talent progression")
	_check(game.player.stats.root_capacity == 4 and game.player.stats.max_health == 85 and game.player.stats.melee_damage == 3, "class starting stats were not applied once")
	_near(game.player.dash.capacity, 150, "assassin dash capacity")
	_near(game.player.dash.charge, 150, "fresh run did not fill class dash capacity")
	_check(not game.player.loadout.weapon_allowed(WeaponCatalog.by_id(&"uv_lamp")), "assassin allows ranged weapon")
	var starts := 0
	for weapon in WeaponCatalog.ALL:
		if WeaponEligibility.starter(weapon, profile, 4): starts += 1
	_check(starts >= 2 and starts < WeaponCatalog.ALL.size(), "class has no meaningful restricted start pool")
	await _reward_flow()
	await _combat()
	_test_paths()
	await _legacy()
	session.clear_run()
	print("PASS class talent budget, paths, combat windows, draft/save flow and legacy progression" if failures == 0 else "FAIL class talents")
	finish(1 if failures > 0 else 0)

func _reward_flow() -> void:
	game._award_xp(5)
	_check(game.rewards.pending_levels == 1 and game.wave.active and not paused and not game.talent_panel.visible, "level threshold interrupted combat")
	game._spawn_loot(game.player.global_position + Vector2(40, 0), &"xp", game.xp_goal)
	game.rewards.queue_chest(&"metal_crown", 4)
	game.wave.active = false
	game.wave.set_process(false)
	game._begin_loot_collection()
	for frame in 180:
		await process_frame
		if game.talent_panel.visible: break
	_check(game.talent_panel.visible and paused and game.rewards.pending_levels == 2 and not game.shop_panel.visible, "loot collection did not precede combined level-point choice")
	await _panel_layout()
	var before := game.player.stats.melee_damage as float
	var charge := game.player.dash.charge as float
	game._on_talent_requested(&"venom_opener")
	_check(game.talents.actions.size() == 1 and not game.player.class_combat.powers.has("opener_poison"), "draft changed live class powers")
	game._on_talents_completed()
	_check(game.rewards.pending_levels == 2, "partial draft bypassed mandatory level points")
	game._on_talent_stat_requested(&"melee_damage")
	var preview: PlayerStats = game.talents.preview_stats(game.player.stats, game.UPGRADES)
	var expected := preview.melee_damage
	preview.free()
	_near(game.player.stats.melee_damage, before, "draft changed live stats")
	_near(game.player.dash.charge, charge, "draft refilled dash")
	var tiers: Array[int] = game.talents.tiers.duplicate()
	game._on_talent_undo()
	_check(game.talents.actions.size() == 1 and game.talents.tiers == tiers, "Undo rerolled attribute grades")
	game._on_talent_stat_requested(&"melee_damage")
	game.talent_panel._select(&"venom_opener")
	game._save_run()
	var snapshot := session.load_run() as Dictionary
	_check(not snapshot.is_empty() and snapshot.talents.actions.size() == 2, "saved draft was rejected/lost")
	var invalid := snapshot.duplicate(true)
	invalid.talents.actions.append({"kind": "stat", "id": "max_health"})
	_check(RunSaveData.normalize(invalid).is_empty(), "saved draft exceeds earned budget")
	invalid = snapshot.duplicate(true)
	invalid.talents.ranks = {"pursuit_finish": 1, "pursuit_health": {}}
	_check(RunSaveData.normalize(invalid).is_empty(), "malformed parent rank reached typed tree")
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await _settle()
	game = current_scene
	_check(game.talent_panel.visible and game.talents.actions.size() == 2 and game.talents.tiers == tiers and game.player.stats.class_data.id == &"assassin", "scene restart lost class/draft/grades")
	_near(game.player.stats.melee_damage, before, "resume applied draft before confirmation")
	for pressed in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_F
		event.physical_keycode = KEY_F
		event.pressed = pressed
		root.push_input(event)
		await process_frame
	_near(game.player.stats.melee_damage, expected, "commit did not match capped/scaled preview")
	_check(game.talents.spent == 2 and game.talents.ranks.get("venom_opener", 0) == 1 and game.rewards.pending_levels == 0 and game.choice_panel.mode == &"chest" and not game.shop_panel.visible, "commit duplicated points or skipped queued chest")
	_check(game.items.preferred_tags(game.player.loadout).has(&"poison"), "Giftstich does not guide shop/relic relevance")
	game._on_talents_completed()
	_near(game.player.stats.melee_damage, expected, "repeat confirm duplicated stats")
	choose_panel(game.choice_panel, 1)
	_check(game.shop_panel.visible and game.rewards.step == PostWaveRewards.Step.SHOP, "reward queue did not reach shop after mandatory choices")
	game.shop_panel.hide()
	game.run_flow.enter(RunFlow.Phase.COMBAT)
	game.rewards.begin_wave()
	game.wave.active = true
	paused = false
	game._award_xp(game.xp_goal)
	game.wave.active = false
	game.wave.set_process(false)
	game._begin_loot_collection()
	await _settle()
	game._on_talent_requested(&"pressure")
	game._on_talents_completed()
	_check(game.talents.spent == 3 and game.player.class_combat.power("focus_bonus") == 4, "second wave talent did not synchronize combat powers")
	game.shop_panel.hide()
	game.run_flow.enter(RunFlow.Phase.COMBAT)
	game.wave.active = true
	paused = true

func _combat() -> void:
	var source := _enemy()
	var other := _enemy(Vector2(160, 0))
	game.player.class_combat.reset_wave()
	var charge: float = game.player.dash.charge
	_check(game.player.dash.request(Vector2.RIGHT, true), "assassin cannot dash with full resource")
	_near(game.player.dash.charge, charge - 75, "dash cost is not class specific")
	_near(_hit(source), 12, "first accepted hit after dash is not an opener")
	_check(game.player.class_combat.opener_time == 0 and source.affix_effects.depot.budget() > 0, "opener was not consumed or Giftstich needs a rare item")
	var budget := source.affix_effects.depot.budget()
	_hit(source)
	_near(source.affix_effects.depot.budget(), budget, "non-opener hits refill class poison")
	for index in 3:
		game.player.class_combat.advance(0.46)
		_hit(source)
	_check(game.player.class_combat.focus_stacks == 4, "focus does not build with timed hits")
	_near(game.player.class_combat.damage_bonus(source, WeaponCatalog.by_id(&"turbo_drill")), 16, "focus bonus is not bounded at four steps")
	_hit(other)
	_check(game.player.class_combat.focus.get_ref() == source, "cleave contact steals established focus")
	var snapshot := RunSnapshot.capture(game)
	var state: Dictionary = snapshot.class_combat.duplicate()
	game._clear_combat()
	await process_frame
	RunSnapshot.restore(game, snapshot)
	paused = true
	var restored := RunSnapshot.capture(game)
	_check(restored.class_combat == state, "focus identity/timers changed on restore")
	game.player.class_combat.advance(2.01)
	_check(game.player.class_combat.focus_stacks == 0 and game.player.class_combat.focus == null, "focus did not expire")
	game.player.hurt_time = 0
	game.player.stats.dodge_chance = 0
	var health: float = game.player.stats.health
	var no_status: Array[Dictionary] = []
	game.player.take_contact_hit(10, no_status, true)
	_near(health - game.player.stats.health, 6.5, "dash contact protection is missing or grants full invulnerability")
	var boss := _enemy(Vector2(350, 0), WaveController.BOSS)
	boss.boss_phase_timer = 1
	game.player.class_combat.on_dash()
	var remaining: float = game.player.class_combat.opener_time
	_near(_hit(boss), 0, "class opener bypassed boss phase guard")
	_near(game.player.class_combat.opener_time, remaining, "blocked hit consumed opener")

func _selection() -> void:
	RunStore.clear(session.save_path + ".setup.json")
	var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
	root.add_child(menu)
	current_scene = menu
	menu._new_game()
	menu._advance_setup()
	_check(menu.page == &"class", "class selection is not in run preparation")
	menu.setup.weapon_id = &"uv_lamp"
	menu.setup_selector.class_view.buttons[1].pressed.emit()
	_check(menu.setup.class_id == &"assassin" and menu.setup.root_capacity == 4 and menu.setup.weapon_id == &"", "class selection did not invalidate a forbidden starter")
	menu.setup_selector.class_view.buttons[0].grab_focus()
	menu.setup_selector.show_details()
	_check(menu.setup_selector.details.heading.text == "Good Old Molar" and menu.setup.class_id == &"assassin", "focused class inspection changes selection or shows the selected class instead")
	menu.setup_selector.details.dismiss()
	menu.setup_selector.confirm_selection()
	_check(menu.page == &"weapon" and menu.setup_selector.options.size() >= 2, "class confirmation did not show eligible starts")
	for weapon in menu.setup_selector.options:
		_check(&"contact" in weapon.class_roles, "class preparation offers a non-contact weapon")
	var draft := RunSetup.load_from(session.save_path + ".setup.json")
	_check(draft != null and draft.class_id == &"assassin", "preparation lost selected class")
	menu.free()
	await process_frame
	RunStore.clear(session.save_path + ".setup.json")

func _panel_layout() -> void:
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(1280, 720)]:
		root.content_scale_size = extent
		root.size = extent
		await _settle()
		var view: TalentPanel = game.talent_panel
		var screen := Rect2(Vector2.ZERO, Vector2(extent))
		_check(screen.encloses(view.done_button.get_global_rect()) and screen.encloses(view.undo_button.get_global_rect()), "talent footer is outside viewport")
		_check(not view.stage.title_label.get_global_rect().intersects(view.stage.progress_label.get_global_rect()), "talent title overlaps points")
		view.tab = "stat"
		view.refresh()
		await _settle()
		for button: Button in view.cards.values():
			var font: Font = button.get_theme_font("font")
			var width := font.get_string_size(button.text, HORIZONTAL_ALIGNMENT_LEFT, -1, button.get_theme_font_size("font_size")).x
			_check(width + 22 <= button.size.x, "attribute label clipped at %s: %s" % [extent, button.text])
		view.tab = "talent"
		view.refresh()

func _test_paths() -> void:
	var stats := new_stats()
	stats.begin_class(ClassCatalog.by_id(&"assassin"))
	var tree := TalentProgression.new()
	tree.enabled = true
	tree.prepare(9, 2, 0)
	_check(not tree.plan_talent(&"pursuit_finish", stats, game.UPGRADES, 9), "finisher skips prerequisites")
	for id in [&"pressure", &"pursuit_health", &"pursuit_health", &"pursuit_health", &"pursuit_finish", &"venom_opener", &"venom_stride", &"venom_stride", &"venom_stride"]:
		_check(tree.plan_talent(id, stats, game.UPGRADES, 9), "legal talent chain refused: " + str(id))
	_check(tree.commit(stats, game.UPGRADES, 9), "valid mixed draft failed commit")
	_near(stats.max_health, 109, "ranked HP applied more than once or preview healed live stats")
	tree.prepare(1, 11, 0)
	_check(not tree.plan_talent(&"venom_switch", stats, game.UPGRADES, 1), "mutually exclusive finishers can both be bought")
	_check(not tree.plan_stat(&"ranged_damage", stats, game.UPGRADES, 1), "contact class offered useless ranged stat")
	var molar := new_stats()
	molar.begin_class(ClassCatalog.DEFAULT)
	var flexible := TalentProgression.new()
	flexible.enabled = true
	flexible.prepare(2, 2, 0)
	_check(flexible.plan_talent(&"versatile", molar, game.UPGRADES, 2) and flexible.plan_talent(&"molar_opener", molar, game.UPGRADES, 2), "base Denti lacks its own flexible tree")
	_check(flexible.commit(molar, game.UPGRADES, 2), "base tree commit failed")
	_near(molar.melee_damage, 1, "base tree melee contribution")
	_near(molar.ranged_damage, 1, "base tree ranged contribution")
	var effects := ClassCombatEffects.new()
	effects.profile = stats.class_data
	effects.powers = {"switch_opener_bonus": 25.0}
	effects.opener_time = 0.5
	effects.opener_history = true
	var dead := _enemy(Vector2(450, 0))
	dead.health = 0
	var next := _enemy(Vector2(500, 0))
	effects.last_opener = weakref(dead)
	_near(effects.damage_bonus(next, WeaponCatalog.by_id(&"turbo_drill")), 45, "switch finisher requires keeping the previous enemy alive")
	var saved := effects.save_data({next.get_instance_id(): 0})
	var restored := ClassCombatEffects.new()
	restored.profile = stats.class_data
	restored.powers = effects.powers.duplicate()
	var enemies: Array[Node] = [next]
	restored.restore(saved, enemies)
	_near(restored.damage_bonus(next, WeaponCatalog.by_id(&"turbo_drill")), 45, "resume lost a switch after a previous enemy died")
	restored.last_opener = weakref(next)
	_near(restored.damage_bonus(next, WeaponCatalog.by_id(&"turbo_drill")), 20, "same target gained switch bonus")
	dead.queue_free()

func _legacy() -> void:
	var snapshot := RunSnapshot.capture(game)
	snapshot.erase("talents")
	snapshot.erase("class_combat")
	snapshot.player.erase("class_state")
	game._clear_combat()
	await process_frame
	RunSnapshot.restore(game, snapshot)
	paused = true
	_check(not game.talents.enabled and game.player.stats.class_data.id == &"good_old_molar", "legacy save was forced into new progression")
	game._clear_combat()
	game.rewards.begin_wave()
	game.rewards.earn_level()
	game.level += 1
	game.wave.active = false
	game._begin_loot_collection()
	await _settle()
	_check(game.choice_panel.mode == &"upgrade" and game.choice_panel.visible and not game.talent_panel.visible, "legacy pending levels lost stat-card flow")
