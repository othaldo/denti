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
	_test_free_nodes()
	await _test_molar_toolkit()
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
	game._on_talent_requested(&"venom_dose")
	_check(game.talents.actions.size() == 1 and not game.player.class_combat.powers.has("trail_poison"), "draft changed live class powers")
	game._on_talents_completed()
	_check(game.rewards.pending_levels == 2, "partial draft bypassed mandatory level points")
	game._on_talent_requested(&"silk_a_melee")
	var preview: PlayerStats = game.talents.preview_stats(game.player.stats, game.UPGRADES)
	var expected := preview.melee_damage
	preview.free()
	_near(game.player.stats.melee_damage, before, "draft changed live stats")
	_near(game.player.dash.charge, charge, "draft refilled dash")
	var tiers: Array[int] = game.talents.tiers.duplicate()
	game._on_talent_undo()
	_check(game.talents.actions.size() == 1 and game.talents.tiers == tiers, "Undo rerolled attribute grades")
	game._on_talent_requested(&"silk_a_melee")
	game.talent_panel._select(&"venom_dose")
	game._save_run()
	var snapshot := session.load_run() as Dictionary
	_check(not snapshot.is_empty() and snapshot.talents.actions.size() == 2, "saved draft was rejected/lost")
	var invalid := snapshot.duplicate(true)
	invalid.talents.actions.append({"kind": "stat", "id": "max_health"})
	_check(RunSaveData.normalize(invalid).is_empty(), "saved draft exceeds earned budget")
	invalid = snapshot.duplicate(true)
	invalid.talents.ranks = {"venom_nerve": 1, "venom_dose": {}}
	_check(RunSaveData.normalize(invalid).is_empty(), "malformed parent rank reached typed tree")
	# Retired Antritt/Fokus talents are refunded as pending points, not rejected.
	var retired := snapshot.duplicate(true)
	retired.talents.ranks = {"pressure": 1, "pursuit_health": 2}
	retired.talents.spent = 3
	retired.level = int(retired.level) + 3
	var migrated := RunSaveData.normalize(retired)
	_check(not migrated.is_empty() and migrated.talents.ranks.is_empty() and int(migrated.talents.spent) == 0 and migrated.talents.actions.is_empty()
		and int(migrated.rewards.pending_levels) == int(snapshot.rewards.pending_levels) + 3, "retired talents were not refunded as level points")
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
	_check(game.talents.spent == 2 and game.talents.ranks.get("venom_dose", 0) == 1 and game.rewards.pending_levels == 0 and game.choice_panel.mode == &"chest" and not game.shop_panel.visible, "commit duplicated points or skipped queued chest")
	_check(game.items.preferred_tags(game.player.loadout).has(&"poison"), "assassin lens does not guide shop/relic relevance toward poison")
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
	game._on_talent_requested(&"rush_refund")
	game._on_talents_completed()
	_check(game.talents.spent == 3 and game.player.class_combat.power("trail_refund") == 5, "second wave talent did not synchronize combat powers")
	game.shop_panel.hide()
	game.run_flow.enter(RunFlow.Phase.COMBAT)
	game.wave.active = true
	paused = true

func _dash_through(distance := 150.0) -> void:
	var cut: ClassDashCut = game.player.dash_cut
	game.player.dash.cooldown = 0
	game.player.dash.charge = maxf(game.player.dash.charge, game.player.dash.config.cost)
	_check(game.player.dash.request(Vector2.RIGHT, true), "assassin cannot dash with resource")
	cut.extend(game.player.global_position + Vector2(distance, 0))
	game.player.dash.finish()
	cut.release()

func _combat() -> void:
	var cut: ClassDashCut = game.player.dash_cut
	var first := _enemy(Vector2(50, 0))
	var second := _enemy(Vector2(110, 0))
	var weak := _enemy(Vector2(130, 6))
	weak.health = 1
	var aside := _enemy(Vector2(80, 220))
	game.player.class_combat.reset_wave()
	cut.reset_wave()
	var charge: float = game.player.dash.charge
	_check(game.player.dash.request(Vector2.RIGHT, true), "assassin cannot dash with full resource")
	_near(game.player.dash.charge, charge - 75, "dash cost is not class specific")
	_check(cut.trails.size() == 1 and cut.trails[0].state == ClassDashCut.State.DRAW, "dash did not start a cut trail")
	cut.extend(game.player.global_position + Vector2(150, 0))
	game.player.dash.finish()
	cut.release()
	cut.advance(0.1)
	_near(first.health, 10000, "trail cut before its visible delay")
	charge = game.player.dash.charge
	var expected := cut.damage_for(first)
	cut.advance(0.2)
	_near(10000 - first.health, expected, "trail did not cut an enemy on the dash path once")
	_check(second.health < 10000 and first.affix_effects.budget(&"poison") > 0 and second.affix_effects.budget(&"poison") > 0, "trail did not hit every crossed enemy or apply poison")
	_near(aside.health, 10000, "trail hit an enemy away from the dash path")
	_check(weak.health <= 0, "trail did not kill a weak crossed enemy")
	_near(game.player.dash.charge, minf(charge + cut.refund_per_kill(), game.player.dash.capacity), "trail kill did not refund root power")
	var after := first.health
	var poison := first.affix_effects.budget(&"poison")
	cut.advance(0.6)
	_near(first.health, after, "poison field dealt a second direct hit")
	_check(first.affix_effects.budget(&"poison") > poison, "poison field did not keep poisoning enemies on the lane")
	_check(cut.trails.size() == 1 and cut.trails[0].state == ClassDashCut.State.FIELD, "trail did not stay as a poison field")
	cut.advance(cut.field_duration())
	_check(cut.trails.is_empty(), "poison field never expired")
	# Refund is capped per trail, never an endless dash loop.
	var capped := {"refund": cut.refund_cap() - 5.0}
	game.player.dash.charge = 0
	cut._refund(capped)
	cut._refund(capped)
	_near(game.player.dash.charge, 5, "trail refund ignored its per-trail cap")
	# Enemies walking into the field are poisoned; Lähmende Schneise slows them.
	game.player.class_combat.powers = {"trail_nerve": 1.0}
	cut.reset_wave()
	_dash_through()
	cut.advance(0.3)
	var late := _enemy(Vector2(90, 0))
	cut.advance(0.6)
	_check(late.affix_effects.budget(&"poison") > 0 and late.affix_effects.depot.nerve_time > 0, "field did not poison/slow an enemy walking in")
	game.player.class_combat.powers = {}
	_check(cut.poison_for(late) > 0, "trail poison budget missing")
	var plain := cut.poison_for(late)
	game.player.class_combat.powers = {"trail_poison_focus": 1.0}
	_near(cut.poison_for(late), plain * 2.5, "Giftschneise poison factor")
	# Kreuzschnitt explodes where a new trail snaps across a visible one.
	game.player.class_combat.powers = {"trail_cross": 1.5}
	cut.reset_wave()
	var origin: Vector2 = game.player.global_position
	var cross_target := _enemy(Vector2(75, 40))
	_dash_through()
	cut.advance(0.3)
	game.player.global_position = origin + Vector2(75, -80)
	game.player.dash.cooldown = 0
	game.player.dash.charge = game.player.dash.capacity
	game.player.dash.request(Vector2.DOWN, true)
	cut.extend(game.player.global_position + Vector2(0, 160))
	game.player.dash.finish()
	cut.release()
	var before_cross := cross_target.health
	var burst := cut.damage_for(cross_target, 1.5)
	cut.advance(0.3)
	_check(before_cross - cross_target.health >= burst * 0.99, "crossing trails did not burst at the intersection")
	game.player.global_position = origin
	# Limit: the oldest trail is replaced.
	game.player.class_combat.powers = {}
	cut.reset_wave()
	for index in 3: _dash_through()
	_check(cut.trails.size() == 2, "active trails exceed the class limit")
	# Resume keeps an armed trail.
	cut.reset_wave()
	_dash_through()
	var snapshot := RunSnapshot.capture(game)
	var state: Dictionary = snapshot.class_combat.duplicate(true)
	_check(state.trails.size() == 1 and int(state.trails[0].state) == ClassDashCut.State.ARMED, "armed trail missing from snapshot")
	var bad := snapshot.duplicate(true)
	bad.class_combat.trails = [{"a": [0, 0], "b": [1], "state": 1}]
	_check(RunSaveData.normalize(bad).is_empty(), "malformed trail reached runtime")
	game._clear_combat()
	await process_frame
	RunSnapshot.restore(game, snapshot)
	paused = true
	_check(RunSnapshot.capture(game).class_combat == state, "trail state changed on restore")
	cut = game.player.dash_cut
	# The assassin passes through bodies while dashing: no damage, no shield spent.
	game.player.hurt_time = 0
	game.player.stats.dodge_chance = 0
	var health: float = game.player.stats.health
	var shields: int = game.player.stats.shield_charges
	var no_status: Array[Dictionary] = []
	_near(game.player.take_contact_hit(10, no_status, true), 0, "assassin took contact damage while dashing")
	_check(game.player.stats.health == health and game.player.stats.shield_charges == shields, "dash pass-through spent health or shields")
	game.player.take_contact_hit(10, no_status, false)
	_check(game.player.stats.health < health, "assassin became immune to contact outside the dash")
	# Boss phase guards also block trail damage.
	cut.reset_wave()
	var boss := _enemy(Vector2(80, 0), WaveController.BOSS)
	boss.boss_phase_timer = 1
	var boss_health := boss.health
	_dash_through()
	cut.advance(0.3)
	_near(boss.health, boss_health, "trail bypassed boss phase guard")
	boss.queue_free()
	cut.reset_wave()
	# Trail kills dropped loot; the paused legacy flow must start from a clean arena.
	game._clear_combat()
	for drop in game.get_node("Loot").get_children(): drop.queue_free()
	await process_frame

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
	for extent in [Vector2i(320, 568), Vector2i(568, 320), Vector2i(1280, 720), Vector2i(3840, 1600)]:
		root.content_scale_size = extent
		root.size = extent
		await _settle()
		var view: TalentPanel = game.talent_panel
		var screen := Rect2(Vector2.ZERO, Vector2(extent))
		_check(screen.encloses(view.done_button.get_global_rect()) and screen.encloses(view.undo_button.get_global_rect()), "talent footer is outside viewport at %s" % extent)
		_check(not view.stage.title_label.get_global_rect().intersects(view.stage.progress_label.get_global_rect()), "talent title overlaps points")
		_check(not view.stage.body_scroll.get_v_scroll_bar().visible, "talent tree needs scrolling at %s" % extent)
		var body := view.stage.body_scroll.get_global_rect().grow(1)
		_check(body.encloses(view.details.get_global_rect()), "talent details leave the stage at %s" % extent)
		var shown: Array[Rect2] = []
		for node: TalentNodeData in game.player.stats.class_data.talent_tree.nodes:
			var cell := view.view.button(node.id)
			if not cell.visible: continue
			var rect := cell.get_global_rect()
			_check(body.encloses(rect) and rect.size.x >= 32, "talent node outside stage or too small at %s: %s" % [extent, node.id])
			_check(not rect.intersects(view.details.get_global_rect()), "talent node under details at %s: %s" % [extent, node.id])
			for other in shown: _check(not rect.intersects(other), "talent nodes overlap at %s: %s" % [extent, node.id])
			shown.append(rect)
		_check(shown.size() >= 5, "too few talent nodes visible at %s" % extent)

func _test_paths() -> void:
	var stats := new_stats()
	stats.begin_class(ClassCatalog.by_id(&"assassin"))
	var assassin_tree := stats.class_data.talent_tree
	_check(assassin_tree.capacity() >= 100 and ClassCatalog.DEFAULT.talent_tree.capacity() >= 100, "talent trees cannot absorb long endless runs")
	var tree := TalentProgression.new()
	tree.enabled = true
	tree.prepare(12, 2, 0)
	_check(not tree.plan_talent(&"venom_nerve", stats, game.UPGRADES, 12), "row 2 opened without branch points")
	_check(tree.reason(&"venom_nerve", stats, game.UPGRADES, 12).contains("6"), "row gate does not name its point requirement")
	# Attribute path nodes count toward the branch gate.
	for id in [&"venom_dose", &"silk_a_melee", &"silk_a_melee"]:
		_check(tree.plan_talent(id, stats, game.UPGRADES, 12), "row 0 node refused: " + str(id))
	_check(tree.plan_talent(&"silk_edge", stats, game.UPGRADES, 12), "row 1 did not open after three branch points")
	_check(not tree.plan_talent(&"silk_wide", stats, game.UPGRADES, 12), "arrow prerequisite skipped")
	for id in [&"silk_a_bite", &"silk_a_bite", &"venom_nerve", &"care_a_health", &"rush_refund", &"rush_a_speed", &"rush_a_speed"]:
		_check(tree.plan_talent(id, stats, game.UPGRADES, 12), "legal tree path refused: " + str(id))
	_check(tree.plan_talent(&"rush_a_dodge", stats, game.UPGRADES, 12), "second branch row 1 did not open independently")
	var before_health := stats.max_health
	_check(tree.commit(stats, game.UPGRADES, 12), "valid mixed draft failed commit")
	_check(stats.max_health > before_health and stats.melee_damage > 3, "attribute path nodes did not grant rolled attributes once")
	var powers := tree.powers(assassin_tree)
	_near(float(powers.get("trail_nerve", 0)), 1, "Lähmende Schneise power")
	_near(float(powers.get("trail_damage", 0)), 8, "Scharfe Seide power")
	_check(not powers.has("melee_damage"), "attribute nodes leaked into talent powers")
	for node in assassin_tree.nodes:
		_check(node.exclusive_group == &"", "assassin tree hides an exclusive lock: " + str(node.id))
		_check(node.stat != &"ranged_damage", "contact class tree offers useless ranged attribute")
	var molar := new_stats()
	molar.begin_class(ClassCatalog.DEFAULT)
	_check(molar.class_data.combat_rules == null or not molar.class_data.combat_rules.trail_enabled, "Good Old Molar gained the assassin trail")
	var flexible := TalentProgression.new()
	flexible.enabled = true
	flexible.prepare(5, 2, 0)
	for id in [&"versatile", &"tool_a_melee", &"tool_a_ranged", &"tool_a_bite", &"tool_elements"]:
		_check(flexible.plan_talent(id, molar, game.UPGRADES, 5) if id != &"tool_elements" else not flexible.plan_talent(id, molar, game.UPGRADES, 5), "base tree gate wrong: " + str(id))
	_check(flexible.plan_talent(&"tool_a_tempo", molar, game.UPGRADES, 5), "base tree row 1 attribute refused")
	_check(flexible.commit(molar, game.UPGRADES, 5), "base tree commit failed")
	var effects := ClassCombatEffects.new()
	effects.profile = molar.class_data
	effects.powers = {"opener_bonus": 20.0}
	effects.on_dash()
	_check(effects.damage_bonus(null, WeaponCatalog.by_id(&"turbo_drill")) > 0, "Good Old Molar lost its opener talent")

func _test_free_nodes() -> void:
	# Hell safety: every branch offers a free attribute choice by row 2, so no
	# talent route can starve the build of survival or damage attributes.
	for profile in [ClassCatalog.by_id(&"assassin"), ClassCatalog.DEFAULT]:
		var tree: TalentTreeData = profile.talent_tree
		_check(tree.valid(), "shipping tree invalid: " + str(profile.id))
		for branch in TalentNodeData.BRANCHES:
			var early := false
			for node in tree.branch_nodes(branch):
				if node.free_attribute and node.row <= 2: early = true
			_check(early, "branch without early free attribute: %s %d" % [profile.id, branch])
	var stats := new_stats()
	stats.begin_class(ClassCatalog.by_id(&"assassin"))
	var tree := TalentProgression.new()
	tree.enabled = true
	tree.prepare(5, 2, 0)
	for id in [&"care_a_health", &"care_a_armor", &"care_a_regen"]:
		_check(tree.plan_talent(id, stats, game.UPGRADES, 5), "care row 0 refused: " + str(id))
	_check(not tree.free_choices(stats, game.UPGRADES).has(&"ranged_damage"), "contact class may pick ranged damage on a free node")
	_check(not tree.plan_talent(&"care_free_1", stats, game.UPGRADES, 5), "free node accepted without a chosen attribute")
	_check(not tree.plan_talent(&"care_free_1", stats, game.UPGRADES, 5, &"ranged_damage"), "free node accepted a forbidden attribute")
	_check(tree.plan_talent(&"care_free_1", stats, game.UPGRADES, 5, &"crit_chance") and tree.plan_talent(&"care_free_1", stats, game.UPGRADES, 5, &"melee_damage"), "free node refused class attributes")
	var invalid := tree.save_data()
	invalid.actions[-1].stat = "ranged_damage"
	_check(not TalentProgression.valid(invalid, stats.class_data), "saved free node with forbidden attribute accepted")
	var crit := stats.crit_chance
	var melee := stats.melee_damage
	_check(tree.commit(stats, game.UPGRADES, 5), "free node draft failed commit")
	_check(stats.crit_chance > crit and stats.melee_damage > melee, "free node did not grant the chosen attributes")
	# Keystones trade one strength for another instead of adding flat power.
	var cut: ClassDashCut = game.player.dash_cut
	var saved_powers: Dictionary = game.player.class_combat.powers
	game.player.class_combat.powers = {"trail_poison_focus": 1.0}
	_near(cut.direct_factor(), 0.35, "Giftschneise direct trail factor")
	_near(cut.poison_factor(), 2.5, "Giftschneise poison factor")
	game.player.class_combat.powers = {"trail_weakness": 0.25}
	_near(cut.direct_factor(), 0.75, "Sprintfaden trail penalty")
	game.player.class_combat.powers = saved_powers
	var dash := PlayerDash.new()
	dash.config = ClassCatalog.by_id(&"assassin").dash_config()
	dash.cost_cut = 25
	_near(dash.cost(), 50, "Sprintfaden dash cost")
	dash.cost_cut = 500
	_near(dash.cost(), dash.config.cost * 0.5, "dash cost cut is not floored")

func _test_molar_toolkit() -> void:
	# Good Old Molar's loadout talents read the equipped weapons.
	var effects: ClassCombatEffects = game.player.class_combat
	var saved: Dictionary = effects.powers
	effects.opener_time = 0
	var drill := WeaponCatalog.by_id(&"turbo_drill")
	game.player.loadout.acquire(drill)
	var counts := {}
	for instance in game.player.loadout.equipped(): counts[instance.data.id] = int(counts.get(instance.data.id, 0)) + 1
	var types := counts.size()
	var copies: int = int(counts.get(drill.id, 1)) - 1
	_check(copies >= 1, "test loadout needs a duplicated drill")
	effects.powers = {"tool_variety": 3.0}
	_near(effects.damage_bonus(null, drill), 3.0 * types, "Werkzeugvielfalt per weapon type")
	effects.powers = {"tool_twin": 3.0}
	_near(effects.damage_bonus(null, drill), 3.0 * copies, "Gleiches Werkzeug per extra copy")
	effects.powers = {"tool_twin": 3.0, "tool_spec_key": 1.0}
	_near(effects.damage_bonus(null, drill), 6.0 * copies - 8.0 * (types - 1), "Fachidiot keystone trade-off")
	effects.powers = {"tool_variety": 3.0, "tool_mix_key": 1.0}
	_near(effects.damage_bonus(null, drill), 6.0 * types - 10.0 * copies, "Bunter Koffer keystone trade-off")
	# Rückstoßpuls shoves enemies away at the end of a dash.
	effects.powers = {"dash_pulse": 70.0}
	var near := _enemy(Vector2(60, 0))
	var before: float = near.global_position.distance_to(game.player.global_position)
	game.player._dash_pulse()
	_check(near.global_position.distance_to(game.player.global_position) >= before + 60.0 * (1.0 - near.data.knockback_resistance) - 0.01, "Rückstoßpuls did not shove a nearby enemy")
	effects.powers = {}
	var far_before := near.global_position
	game.player._dash_pulse()
	_check(near.global_position == far_before, "dash pulse without talent moved enemies")
	near.queue_free()
	effects.powers = saved
	await process_frame

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
	for frame in 180:
		await process_frame
		if game.choice_panel.visible or game.talent_panel.visible: break
	_check(game.choice_panel.mode == &"upgrade" and game.choice_panel.visible and not game.talent_panel.visible, "legacy pending levels lost stat-card flow")
