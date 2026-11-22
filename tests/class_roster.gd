extends "res://tests/support/test_runtime.gd"

## Zahnfee, Glutzahn, Spültechniker and Frostwächter: class data, trees, the
## verb of every class, its skills and snapshot round trips.

var game: Node2D
var failures := 0

func _initialize() -> void:
	call_deferred("_run")

func _check(value: bool, message: String) -> void:
	if not value:
		failures += 1
		push_error(message)

func _near(a: float, b: float, message: String) -> void:
	_check(is_equal_approx(a, b), "%s: %s != %s" % [message, a, b])

func _enemy(offset: Vector2, data: EnemyData = WaveController.PLAQUE) -> Enemy:
	game._create_enemy(data, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.set_simulation_enabled(false)
	enemy.health = 10000
	enemy.max_health = 10000
	enemy.damage_reduction = 0
	return enemy

func _clear_enemies() -> void:
	for enemy in game.get_node("Enemies").get_children(): enemy.queue_free()
	for drop in game.get_node("Loot").get_children(): drop.queue_free()
	await process_frame

func _use(id: StringName, powers: Dictionary) -> ClassSkillModule:
	game.player.stats.class_data = ClassCatalog.by_id(id)
	game.player.class_combat.profile = game.player.stats.class_data
	game.player.class_combat.powers = powers
	var module: ClassSkillModule = game.player.skill_module(id)
	module.reset_wave()
	return module

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://class_roster_test.json"
	session.clear_run()
	_data()
	session.pending_start_class_id = &"good_old_molar"
	session.pending_start_weapon_id = &"turbo_drill"
	session.pending_talent_run = true
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	for frame in 4: await process_frame
	game.wave.set_process(false)
	game.player.loadout.acquire(WeaponCatalog.by_id(&"turbo_drill"))
	_looks()
	await _fairy()
	await _ember()
	await _rinser()
	await _frost()
	_snapshots()
	session.clear_run()
	print("PASS class roster: data, verbs, skills and snapshots of four classes" if failures == 0 else "FAIL class roster")
	finish(1 if failures > 0 else 0)

func _data() -> void:
	_check(ClassCatalog.profiles.size() >= 6, "roster classes missing from the catalog")
	for profile in ClassCatalog.profiles:
		var tree := profile.talent_tree
		_check(profile.valid() and tree != null and tree.valid() and tree.capacity() >= 100, "class data or tree invalid: " + str(profile.id))
		_check(not profile.tagline.is_empty() and profile.play_style.size() >= 2 and profile.portrait != null, "class selection text missing: " + str(profile.id))
		if profile.id in [&"tooth_fairy", &"ember", &"rinser", &"frost_warden"]:
			_check(profile.portrait != null and profile.portrait.resource_path == "res://assets/classes/%s_portrait.png" % profile.id, "class portrait missing: " + str(profile.id))
		var skills := 0
		for node in tree.nodes:
			if not node.is_attribute():
				_check(DentiUIIcons.talent(node.icon_index) != null, "talent icon missing: " + str(node.id))
			if node.is_skill(): skills += 1
			if node.is_modifier(): _check(_leads_to_skill(tree, node), "modifier without skill: " + str(node.id))
			if node.description.contains("px"): _check(false, "pixel size in player text: " + str(node.id))
		_check(skills == 3, "class needs three skills: " + str(profile.id))
		for branch in TalentNodeData.BRANCHES:
			var early := false
			for node in tree.branch_nodes(branch):
				if node.free_attribute and node.row <= 2: early = true
			_check(early, "branch without early free root: %s %d" % [profile.id, branch])
	_check(ClassSkillModule.valid_state({"a": [1, 2.5], "b": {"c": 3}}) and not ClassSkillModule.valid_state({"a": NAN}), "generic module state validation")

## A modifier's arrow chain must end at its branch skill.
func _leads_to_skill(tree: TalentTreeData, node: TalentNodeData) -> bool:
	var current := tree.by_id(node.parent)
	while current != null:
		if current.is_skill(): return true
		current = tree.by_id(current.parent)
	return false

## The combat sprite shows the chosen class at the base body's height.
func _looks() -> void:
	var player: Player = game.player
	var base_texture := player.base_body_texture
	var base_height := float(Player._used_rect(base_texture).size.y) * player.base_body_scale.y
	_check(player.sprite.texture == base_texture and player.expressions.visible, "Good Old Molar lost the expressive base Denti")
	for profile in ClassCatalog.profiles:
		if profile.combat_sprite == null: continue
		player.stats.class_data = profile
		player.apply_class_look()
		var height := float(Player._used_rect(profile.combat_sprite).size.y) * player.sprite_base_scale.y
		_check(player.sprite.texture == profile.combat_sprite and not player.expressions.visible, "class look not shown: " + str(profile.id))
		_check(absf(height - base_height) < 0.5, "class look changes Denti's size: " + str(profile.id))
	player.stats.class_data = ClassCatalog.DEFAULT
	player.apply_class_look()
	_check(player.sprite.texture == base_texture and player.expressions.visible and player.sprite.offset == Vector2.ZERO, "base look not restored")

func _fairy() -> void:
	var fairy: FairySkills = _use(&"tooth_fairy", {"skill_stardust": 1.0, "skill_pillow": 1.0, "pillow_feather": 1.0, "skill_bounty": 1.0})
	_check(game.player.items.pickup_range() < Loot.MAGNET_DISTANCE, "Zahnfee kept the full loot magnet")
	var target := _enemy(Vector2(120, 0))
	fairy.on_loot_collected(&"xp", 1, null)
	_check(target.health < 10000, "collected loot did not fire a light shard")
	for pickup in FairySkills.PILLOW_FAST: fairy.tokens = FairySkills.SHARD_RATE; fairy.on_loot_collected(&"xp", 1, null)
	_check(game.player.stats.shield_charges >= 1, "Zahnkissen did not grant a shield")
	var health := target.health
	fairy.stardust()
	_check(target.health < health, "Feenstaub missed an enemy")
	var elite_data := WaveController.PLAQUE.duplicate()
	elite_data.is_elite = true
	var elite := _enemy(Vector2(-80, 0), elite_data)
	var loot := game.get_node("Loot").get_child_count()
	fairy.on_weapon_hit(elite, WeaponCatalog.by_id(&"turbo_drill"), 10.0)
	fairy.on_weapon_hit(elite, WeaponCatalog.by_id(&"turbo_drill"), 10.0)
	_check(game.get_node("Loot").get_child_count() == loot + 1, "Kopfgeld coin missing or not rate-limited")
	fairy.tokens = 0.0
	health = target.health
	fairy.on_loot_collected(&"xp", 1, null)
	_check(target.health == health, "light shards ignore their rate limit")
	await _clear_enemies()

func _ember() -> void:
	var ember: EmberSkills = _use(&"ember", {"skill_core": 1.0})
	var near := _enemy(Vector2(60, 0))
	var other := _enemy(Vector2(-60, 0))
	_check(ember.damage_bonus(near, WeaponCatalog.by_id(&"uv_lamp")) < 0.0 and ember.damage_bonus(near, WeaponCatalog.by_id(&"turbo_drill")) == 0.0, "Glutzahn ranged penalty")
	ember.add_heat(EmberSkills.MAX_HEAT)
	_check(near.health < 10000 and other.health < 10000, "full heat did not erupt on nearby enemies")
	_check(ember.overheat > 0.0 and ember.heat == 0.0 and ember.weapon_interval_factor(game.player.loadout.equipped()[0]) > 1.0, "eruption did not overheat")
	_check(ember.cores.size() == 1, "Glutkern did not leave burning ground")
	ember.add_heat(50.0)
	_near(ember.heat, 0.0, "heat built up during overheat")
	game.player.class_combat.powers = {"skill_vent": 1.0, "vent_valve": 1.0}
	ember.reset_wave()
	ember.heat = 60.0
	var health := near.health
	ember.on_dash_started()
	_check(near.health < health and ember.overheat == 0.0, "Druckablass did not vent early without overheat")
	await _clear_enemies()

func _rinser() -> void:
	var rinser: RinserSkills = _use(&"rinser", {"skill_flood": 1.0, "skill_shower": 1.0})
	var origin: Vector2 = game.player.global_position
	for step in 6:
		game.player.global_position = origin + Vector2(step * 30, 0)
		rinser.advance(0.05)
	_check(rinser.trail.size() >= 5, "walking did not leave a rinse trail")
	var first := _enemy(Vector2(-90, 0))
	var second := _enemy(Vector2(-30, 10))
	rinser.wet_tick = 0.0
	rinser.advance(0.01)
	_check(first.wet_time > 0.0 and rinser.on_trail_enemy(first) and rinser.on_trail_enemy(second), "enemies on the trail are not wet")
	rinser.on_weapon_hit(first, WeaponCatalog.by_id(&"turbo_drill"), 20.0)
	_check(second.health < 10000, "a hit on the trail did not arc to another enemy on it")
	var health := first.health
	game.player.dash.direction = Vector2.RIGHT
	rinser.on_dash_started()
	_check(first.health < health, "the dash did not surge the trail")
	game.player.stats.health = game.player.stats.max_health * 0.2
	var hp: float = game.player.stats.health
	rinser.advance(0.01)
	_check(game.player.stats.health > hp and rinser.shower_cooldown > 0.0, "Notdusche did not trigger at low health")
	game.player.stats.health = game.player.stats.max_health
	# Kurzschluss: walking a closed loop pulses everything inside.
	game.player.class_combat.powers = {"skill_short": 1.0}
	rinser.reset_wave()
	var centre: Vector2 = origin + Vector2(300, 0)
	var inside := _enemy(centre - game.player.global_position)
	for step in 14:
		game.player.global_position = centre + Vector2.from_angle(step * TAU / 12.0) * 90.0
		rinser.advance(0.15)
	_check(not rinser.loop.is_empty() or inside.health < 10000, "closing a loop did not start Kurzschluss")
	for tick in 3: rinser.advance(0.5)
	_check(inside.health < 10000, "Kurzschluss did not hit an enemy inside the loop")
	game.player.global_position = origin
	await _clear_enemies()

func _frost() -> void:
	var frost: FrostSkills = _use(&"frost_warden", {"skill_shatter": 1.0, "skill_icearmor": 1.0})
	var origin: Vector2 = game.player.global_position
	frost.dash_start = origin + Vector2(100, -100)
	var shields: int = game.player.stats.shield_charges
	frost.on_dash_ended(origin, origin + Vector2(100, 100))
	_check(frost.walls.size() == 1 and game.player.stats.shield_charges == mini(shields + 1, 5), "dash did not raise an ice wall with Eispanzer")
	var blocked := _enemy(Vector2(102, 0))
	frost.advance(0.05)
	var gap := absf(blocked.global_position.x - (origin.x + 100))
	_check(gap >= FrostSkills.WALL_HALF and blocked.chill_time > 0.0, "ice wall did not hold back and chill an enemy")
	for tick in 12:
		blocked.global_position.x = origin.x + 100 + 2
		frost.advance(0.1)
	_check(frost.brittle.has(blocked.get_instance_id()), "enemy at the wall did not become brittle")
	var health := blocked.health
	frost.on_weapon_hit(blocked, WeaponCatalog.by_id(&"turbo_drill"), 20.0)
	_check(blocked.health < health and not frost.brittle.has(blocked.get_instance_id()), "Zerschmettern did not consume brittleness")
	var boss := _enemy(Vector2(100, 40), WaveController.BOSS)
	frost.advance(0.05)
	frost.advance(0.05)
	_check(frost.walls.is_empty(), "a boss did not break the ice wall")
	boss.queue_free()
	await _clear_enemies()
	# Frostwelle: an expiring wall bursts into shards that pierce, chill and embrittle.
	frost = _use(&"frost_warden", {"skill_frostwave": 1.0})
	frost.walls.append({"a": origin + Vector2(0, -120), "b": origin + Vector2(0, 120), "time": 0.01})
	var near := _enemy(Vector2(-30, 27))
	var far := _enemy(Vector2(400, 0))
	var near_health := near.health
	frost.advance(0.02)
	var count := frost.shards.size()
	_check(count >= FrostSkills.SHARD_MIN and count <= FrostSkills.SHARD_MAX, "expiring wall did not burst into shards: %d" % count)
	for tick in 30: frost.advance(1.0 / 60.0)
	_check(near.health < near_health and near.chill_time > 0.0 and frost.brittle.has(near.get_instance_id()), "a shard did not hit, chill and embrittle a nearby enemy")
	_check(far.health == 10000.0 and frost.shards.is_empty(), "shards flew beyond their range: %s %d" % [far.health, frost.shards.size()])
	frost = _use(&"frost_warden", {"skill_frostwave": 1.0, "wave_avalanche": 1.0})
	frost.walls.append({"a": origin + Vector2(0, -120), "b": origin + Vector2(0, 120), "time": 0.01})
	frost.advance(0.02)
	_check(frost.shards.size() == count * 2, "Lawine did not double the shards")
	await _clear_enemies()

func _snapshots() -> void:
	var states: Dictionary = game.player.save_skill_modules()
	_check(ClassSkillModule.valid_state(states), "module snapshot invalid")
	game.player.restore_skill_modules(states)
	_check(game.player.save_skill_modules() == states, "module state changed on restore")
	var full := RunSnapshot.capture(game)
	_check(ClassCombatEffects.valid(full.class_combat), "class combat snapshot rejected")
