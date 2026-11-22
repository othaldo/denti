extends "res://tests/support/test_runtime.gd"

## Class relics: two per class, offered only to their class (four choices after
## a milestone boss), and the effect of every class relic on its class verb.

var game: Node2D
var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)

func _run() -> void:
	_catalog()
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://class_relics_test.json"
	session.clear_run()
	session.pending_start_class_id = &"good_old_molar"
	session.pending_start_weapon_id = &"turbo_drill"
	session.pending_talent_run = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 4: await process_frame
	game.wave.set_process(false)
	game.wave.active = true
	_check(game.player.relics == game.relics, "player cannot see the relic inventory")
	await _molar()
	await _assassin()
	await _fairy()
	await _ember()
	await _rinser()
	await _frost()
	_snapshot()
	game.queue_free()
	await process_frame
	session.clear_run()
	if failures.is_empty(): print("class relics ok")
	finish(1 if not failures.is_empty() else 0)

func _catalog() -> void:
	_check(RelicCatalog.OFFER_COUNT == 4, "milestone bosses should offer four relics")
	for class_id in ClassCatalog.MASTERY_CLASSES:
		var profile := ClassCatalog.by_id(class_id)
		var own: Array[StringName] = []
		for relic in RelicCatalog.CATALOG:
			if relic.class_id == profile.id: own.append(relic.id)
		_check(own.size() == 2, "class should have two relics: %s %s" % [profile.id, own])
		for sample in 40:
			seed(sample)
			var choices := RelicCatalog.choices([], [], profile.id)
			_check(choices.size() == RelicCatalog.OFFER_COUNT, "class received fewer than four relics: " + str(profile.id))
			var has_own := false
			for id in choices:
				var relic := RelicCatalog.by_id(StringName(id))
				_check(RelicCatalog.offered_to(relic, profile.id), "foreign class relic offered to " + str(profile.id) + ": " + id)
				if relic.class_id == profile.id: has_own = true
			_check(has_own, "no own class relic among the choices of " + str(profile.id))
		# Once both class relics are owned the offer falls back to general relics.
		var owned: Array[String] = []
		for id in own: owned.append(str(id))
		for id in RelicCatalog.choices(owned, [], profile.id):
			_check(RelicCatalog.by_id(StringName(id)).class_id == &"", "owned class relic or foreign relic offered again")
	for relic in RelicCatalog.CATALOG:
		_check(relic.class_id == &"" or ClassCatalog.by_id(relic.class_id).id == relic.class_id, "relic names an unknown class: " + str(relic.id))
		_check(not relic.display_name.is_empty() and not relic.description.is_empty() and DentiUIIcons.relic_icon(relic) != null, "relic presentation incomplete: " + str(relic.id))
	for relic in RelicCatalog.CATALOG.slice(0, 6):
		_check(relic.class_id == &"", "general relic became class bound: " + str(relic.id))

func _enemy(offset: Vector2, health: float = 10000.0) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.health = health
	enemy.max_health = maxf(health, 10000.0)
	enemy.damage_reduction = 0
	return enemy

func _clear() -> void:
	for enemy in game.get_node("Enemies").get_children(): enemy.queue_free()
	for drop in game.get_node("Loot").get_children(): drop.queue_free()
	game.relics.owned.clear()
	await process_frame

func _play(id: StringName) -> void:
	game.player.stats.class_data = ClassCatalog.by_id(id)
	game.player.class_combat.profile = game.player.stats.class_data
	game.player.class_combat.powers = {}
	game.player.reset_skill_modules()
	game.player.molar_skills.reset_wave()
	game.player.assassin_skills.reset_wave()

func _molar() -> void:
	_play(&"good_old_molar")
	var molar: MolarSkills = game.player.molar_skills
	var drill := WeaponCatalog.by_id(&"turbo_drill")
	var scaler := WeaponCatalog.by_id(&"plaque_scaler")
	var target := _enemy(Vector2(60, 0))
	molar.on_weapon_hit(target, drill, 100.0)
	molar.on_weapon_hit(target, scaler, 100.0)
	_check(target.health == 10000.0, "Wurzelgeflecht acted without the relic")
	game.relics.acquire(&"molar_root_weave")
	molar.on_weapon_hit(target, drill, 100.0)
	molar.on_weapon_hit(target, drill, 100.0)
	_check(target.health == 10000.0, "the same weapon twice wove a root strike")
	molar.advance(0.2)
	molar.on_weapon_hit(target, scaler, 100.0)
	_check(is_equal_approx(target.health, 10000.0 - 40.0), "two weapons did not weave a 40 %% strike: %s" % target.health)
	game.relics.acquire(&"molar_crown_echo")
	molar.on_shield_blocked()
	_check(molar.echo_cooldown > 0.0, "a blocked shield hit did not make the weapons attack")
	var cooldown := molar.echo_cooldown
	molar.on_shield_blocked()
	_check(molar.echo_cooldown == cooldown, "Kronen-Echo ignored its cooldown")
	await _clear()

func _assassin() -> void:
	_play(&"assassin")
	var skills: AssassinSkills = game.player.assassin_skills
	var target := _enemy(Vector2(60, 0))
	var neighbor := _enemy(Vector2(100, 20))
	var poison: Array[Dictionary] = [{"id": "poison", "damage": 40.0}]
	target.take_damage(0, null, false, &"", poison)
	game.relics.acquire(&"assassin_midnight_blade")
	skills.on_dash_started()
	skills.on_weapon_hit(target, WeaponCatalog.by_id(&"turbo_drill"), 10.0)
	_check(neighbor.affix_effects.budget(&"poison") > 0.0, "Mitternachtsklinge did not spread the poison")
	var spread := neighbor.affix_effects.budget(&"poison")
	skills.on_weapon_hit(target, WeaponCatalog.by_id(&"turbo_drill"), 10.0)
	_check(neighbor.affix_effects.budget(&"poison") == spread, "a second hit after one dash spread poison again")
	skills.expose(target, 1.0)
	_check(game.player.module_damage_bonus(target, WeaponCatalog.by_id(&"turbo_drill")) == 0.0, "Nachtschatten acted without the relic")
	game.relics.acquire(&"assassin_nightshade")
	_check(game.player.module_damage_bonus(target, WeaponCatalog.by_id(&"turbo_drill")) == AssassinSkills.NIGHTSHADE_BONUS, "poison field gave no weapon damage bonus")
	skills.advance(1.1)
	_check(game.player.module_damage_bonus(target, WeaponCatalog.by_id(&"turbo_drill")) == 0.0, "Nachtschatten outlasted the field")
	await _clear()

func _fairy() -> void:
	_play(&"tooth_fairy")
	var fairy: FairySkills = game.player.skill_module(&"tooth_fairy")
	var target := _enemy(Vector2(120, 0))
	var neighbor := _enemy(Vector2(150, 20))
	game.relics.acquire(&"fairy_crescent")
	fairy._hit(target, game.player.global_position, 1.0, true)
	_check(neighbor.health < 10000.0, "a critical shard did not burst")
	var before := neighbor.health
	fairy._hit(target, game.player.global_position, 1.0, false)
	_check(game.player.stats.last_roll_critical or neighbor.health == before, "a normal shard burst")
	game._spawn_loot(game.player.global_position + Vector2(260, 0), &"coin", 1)
	var drop: Loot = game.get_node("Loot").get_child(-1)
	game.player.dash.remaining = 0.2
	fairy.advance(0.0)
	_check(not drop.wave_collecting, "Traumfänger acted without the relic")
	game.relics.acquire(&"fairy_dreamcatcher")
	fairy.advance(0.0)
	_check(drop.wave_collecting, "dashing did not draw the loot")
	game.player.dash.remaining = 0.0
	await _clear()

func _ember() -> void:
	_play(&"ember")
	var ember: EmberSkills = game.player.skill_module(&"ember")
	for index in 3: _enemy(Vector2(40 + index * 10, 0), 1.0)
	game.relics.acquire(&"ember_volcano_heart")
	ember.erupt(1.0, true)
	_check(is_equal_approx(ember.heat, 3 * EmberSkills.VOLCANO_HEAT), "nova kills did not refill heat: %s" % ember.heat)
	await _clear()
	var target := _enemy(Vector2(40, 0))
	ember.on_weapon_hit(target, WeaponCatalog.by_id(&"turbo_drill"), 50.0)
	_check(target.affix_effects.budget(&"fire") == 0.0, "Glutzange burned without the relic")
	game.relics.acquire(&"ember_tongs")
	ember.overheat = 0.0
	ember.on_weapon_hit(target, WeaponCatalog.by_id(&"turbo_drill"), 50.0)
	_check(target.affix_effects.budget(&"fire") == 0.0, "Glutzange burned outside the overheat")
	ember.overheat = 1.0
	ember.on_weapon_hit(target, WeaponCatalog.by_id(&"turbo_drill"), 50.0)
	_check(target.affix_effects.budget(&"fire") > 0.0, "overheated hits did not burn")
	await _clear()

func _rinser() -> void:
	_play(&"rinser")
	var rinser: RinserSkills = game.player.skill_module(&"rinser")
	var origin: Vector2 = game.player.global_position
	var target := _enemy(Vector2(300, 0))
	var other := _enemy(Vector2(340, 30))
	target.apply_wet(3.0)
	other.apply_wet(3.0)
	_check(not rinser.conducts(target), "wet enemies off the trail conducted without the relic")
	game.relics.acquire(&"rinser_tap_water")
	rinser.arc_cooldown = 0.0
	rinser.on_weapon_hit(target, WeaponCatalog.by_id(&"water_jet"), 100.0)
	_check(other.health < 10000.0, "the current did not jump between wet enemies")
	rinser.trail = [{"at": origin + Vector2(0, 200), "time": 4.0, "age": 0.0}]
	var drifter := _enemy(Vector2(0, 50))
	var gap := drifter.global_position.distance_to(origin + Vector2(0, 200))
	game.relics.acquire(&"rinser_whirlpool")
	rinser._whirl()
	_check(drifter.global_position.distance_to(origin + Vector2(0, 200)) < gap - 30.0, "the whirlpool did not draw enemies to the trail")
	await _clear()

func _frost() -> void:
	_play(&"frost_warden")
	var frost: FrostSkills = game.player.skill_module(&"frost_warden")
	var boss := _enemy(Vector2(100, 0))
	frost._glacier(boss)
	_check(frost.glacier.is_empty(), "Gletscherherz acted without the relic")
	game.relics.acquire(&"frost_glacier_heart")
	frost._glacier(boss)
	_check(frost.damage_bonus(boss, WeaponCatalog.by_id(&"turbo_drill")) == FrostSkills.GLACIER_BONUS and boss.chill_time > 0.0, "broken wall did not expose the boss")
	frost.glacier.clear()
	frost._glacier(boss)
	_check(frost.glacier.is_empty(), "Gletscherherz ignored its cooldown")
	var brittle := _enemy(Vector2(-100, 0))
	var near := _enemy(Vector2(-140, 20))
	var far := _enemy(Vector2(-400, 0))
	frost.brittle[brittle.get_instance_id()] = 2.0
	game.relics.acquire(&"frost_ice_flower")
	frost.on_enemy_died(brittle)
	_check(frost.brittle.has(near.get_instance_id()) and not frost.brittle.has(far.get_instance_id()), "Eisblume did not pass brittleness to the neighbours")
	await _clear()

func _snapshot() -> void:
	game.relics.acquire(&"frost_ice_flower")
	game.relics.acquire(&"sun_mark")
	var restored := RelicInventory.new()
	restored.restore(game.relics.save_data())
	_check(restored.owned == game.relics.owned, "class relics lost on resume")
	restored.free()
