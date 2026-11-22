extends "res://tests/support/test_runtime.gd"

const NECRO := &"necrodent"
const STAFF := &"extraction_staff"

var game: Node2D
var session: Node
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)


func _start_game(id: StringName, weapon: StringName = &"turbo_drill") -> void:
	session.pending_start_class_id = id
	session.pending_start_weapon_id = weapon
	session.pending_talent_run = true
	game = preload("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	await process_frame
	game.wave.set_process(false)
	game.player.set_physics_process(false)


func _run() -> void:
	session = root.get_node("GameSession")
	session.save_path = "user://necrodent_run.json"
	session.progression_path = "user://necrodent_progression.cfg"
	session.report_dir = "user://necrodent_reports"
	DirAccess.remove_absolute(session.progression_path)
	session.clear_run()
	session.load_progression()
	await _check_unlock()
	await _check_combat()
	await _check_branches()
	await _check_shop()
	game.queue_free()
	await process_frame
	session.clear_run()
	DirAccess.remove_absolute(session.progression_path)
	if failures == 0: print("PASS Nekrodent: class mastery, exclusive equipment, combat, talents, shop and save/resume")
	finish(0 if failures == 0 else 1)


func _check_unlock() -> void:
	var view := ClassSelection.new()
	root.add_child(view)
	var necro_button: Button = view.buttons.back()
	var details: Array[String] = []
	view.details_requested.connect(func(title: String, body: String) -> void: details.assign([title, body]))
	necro_button.pressed.emit()
	var count: Label = necro_button.get_node("UnlockProgress/ProgressRow/Count")
	_check(count.text == "0/6" and view.selected_id == ClassCatalog.DEFAULT.id
		and details.size() == 2 and details[1].contains("Frostwächter"), "locked tile lacks status or changed selection")
	view.queue_free()
	session.record_class_victory(&"good_old_molar", &"normal", true)
	session.record_class_victory(&"assassin", &"hard", false)
	_check(session.progression_data.class_wins.is_empty(), "unqualified runs count for class unlock")
	var classes := ClassCatalog.MASTERY_CLASSES
	for index in classes.size() - 1:
		var difficulty := &"hell" if index == 1 else &"hard"
		_check(not session.record_class_victory(classes[index], difficulty, true), "Nekrodent unlocked too early")
	session.record_class_victory(classes[0], &"hell", true)
	_check(session.progression_data.class_wins.size() == 5 and not session.class_unlocked(NECRO), "duplicate win counted")
	await _start_game(classes.back())
	game.wave.current_wave = WaveController.MAX_WAVES
	game.wave.difficulty_id = &"hard"
	game._finish_run()
	session.load_progression()
	_check(session.class_unlocked(NECRO) and session.progression_data.class_wins.size() == 6, "sixth victory did not persist the unlock")
	_check(session.hell_unlocked, "class progress interfered with Hell")
	game.queue_free()
	paused = false
	await process_frame


func _enemy(offset: Vector2) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.health = 10000.0
	enemy.damage_reduction = 0.0
	return enemy


func _check_combat() -> void:
	await _start_game(NECRO)
	var player: Player = game.player
	var module: NecrodentSkills = player.skill_module(NECRO)
	var staff: WeaponInstance = player.loadout.equipped()[0]
	_check(player.stats.class_data.id == NECRO and staff.data.id == STAFF and module.teeth.size() == 1, "incorrect Nekrodent starting kit")
	_check(not player.loadout.can_acquire(WeaponCatalog.by_id(&"turbo_drill"))
		and not WeaponEligibility.allowed(staff.data, ClassCatalog.DEFAULT), "class weapon restrictions failed")
	_check(player.loadout.sell(0) == 0 and is_instance_valid(staff), "permanent staff was sold")
	var near := _enemy(Vector2(70, 0))
	var target := _enemy(Vector2(-170, 0))
	_check(not staff.force_attack(1.0) and target.health == 10000.0, "staff independently attacks")
	module.on_dash_ended(player.global_position, target.global_position)
	_check(module.marked == target, "dash did not target from its endpoint")
	for tick in 110: module.advance(1.0 / 60.0)
	_check(target.health < 10000.0 and near.health == 10000.0 and module.teeth.size() == 1, "retinue missed its command or grew mid-wave")
	module.teeth[0].recovery = 0.9
	game._save_run()
	var saved: Dictionary = session.load_run()
	_check(not saved.is_empty(), "run snapshot with teeth was rejected")
	game.queue_free()
	await process_frame
	session.resume_requested = true
	await _start_game(NECRO, &"")
	player = game.player
	module = player.skill_module(NECRO)
	_check(module.teeth.size() == 1 and absf(module.teeth[0].recovery - 0.9) < 0.05, "continue lost the resting tooth")
	_check(is_instance_valid(module.marked) and module.marked.global_position.x < player.global_position.x, "continue lost the marked target")
	module.advance(1.0)
	_check(module.teeth.size() == 1 and module.teeth[0].recovery == 0.0, "revival changed the retinue")
	module.marked.queue_free()
	await process_frame
	module.advance(0.2)
	_check(module.marked == null, "unavailable command target was retained")
	game.talents.prepare(1, 2, 0.0)
	_check(game.talents.plan_talent(&"necro_swarm_recruit", player.stats, game.UPGRADES, 1), "early tooth is unavailable")
	_check(game.talents.commit(player.stats, game.UPGRADES, 1), "could not spend a regular level point on a tooth")
	game._sync_talents()
	_check(module.teeth.size() == 1, "new tooth spawned before the next wave")
	game._start_combat_wave()
	_check(module.teeth.size() == 2, "acquired tooth did not join on the next wave")


func _check_branches() -> void:
	for enemy in game.get_node("Enemies").get_children(): enemy.queue_free()
	await process_frame
	var player: Player = game.player
	var module: NecrodentSkills = player.skill_module(NECRO)
	var close := _enemy(Vector2(62, 0))
	var far := _enemy(Vector2(-150, 0))
	player.class_combat.powers = {"necro_teeth": 1.0, "necro_swarm": 1.0}
	module.reset_wave()
	module.advance(0.01)
	_check(module.teeth[0].target != null and module.teeth[1].target != null
		and module.teeth[0].target != module.teeth[1].target, "swarm failed to spread out")
	player.class_combat.powers = {"necro_guard": 1.0}
	module.reset_wave()
	module.on_dash_ended(player.global_position, far.global_position)
	module.advance(0.01)
	_check(module.marked == far and module.teeth[0].target == close, "escort did not keep a tooth near Denti")


func _check_shop() -> void:
	game.wave.active = false
	game.wave.current_wave = 2
	game.coins = 100
	game._open_shop()
	var offer_index := -1
	for index in game.shop.offers.size():
		var offer: ShopOfferData = game.shop.offers[index]
		if offer == null or offer.weapon_data == null: continue
		_check(offer.id == STAFF and offer.weapon_tier == 1, "shop offered an unusable weapon")
		offer_index = index
	_check(offer_index >= 0, "shop did not supply a staff for fusion")
	if offer_index >= 0:
		game._on_shop_buy(offer_index)
		var weapons: Array[WeaponInstance] = game.player.loadout.equipped()
		_check(weapons.size() == 1 and weapons[0].tier == 2
			and weapons[0].data.range_at_tier(2) > weapons[0].data.range_at_tier(1), "staff fusion failed")
