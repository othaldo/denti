extends SceneTree

var game: Node2D

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_weapon_motion.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	paused = true
	game.wave.active = false
	game.player.stats.crit_chance = 0.0
	for data in WeaponCatalog.ALL:
		if data.tip_anchor == data.grip_anchor or data.visual_size <= 0:
			_fail("missing emission/contact anchor: " + str(data.id))
			return
	for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
		_clear()
		var enemy := _enemy(direction * 200)
		var gun := _equip(&"water_jet")
		gun._physics_process(0.01)
		var bullet: WeaponProjectile = game.get_node("Projectiles").get_child(-1)
		if bullet.global_position.distance_to(gun.muzzle_position()) > 0.01 or bullet.global_position.distance_to(game.player.global_position) < 30:
			_fail("water fired from Denti instead of its nozzle")
			return
		if bullet.direction.dot(bullet.global_position.direction_to(enemy.global_position)) < 0.999:
			_fail("barrel emission did not point at the target")
			return
		if absf(direction.x) > 0.5 and (gun.sprite.scale.y < 0) != (direction.x < 0):
			_fail("gun did not mirror when crossing to the left side")
			return
	_clear()
	var target := _enemy(Vector2(-180, 0))
	var sling := _equip(&"amalgam_slingshot")
	sling._physics_process(0.01)
	var bullet: WeaponProjectile = game.get_node("Projectiles").get_child(-1)
	if absf(sling.sprite.rotation) > 0.01 or sling.sprite.scale.y <= 0 or bullet.global_position.distance_to(sling.muzzle_position()) > 0.01:
		_fail("slingshot handle did not stay upright or fired from the wrong place")
		return
	_clear()
	target = _enemy(Vector2(100, 0))
	var spear := _equip(&"toothpick_spear")
	var health := target.health
	spear._physics_process(0.01)
	if target.health != health:
		_fail("melee damage happened before the windup/contact")
		return
	target.global_position = game.player.global_position + Vector2(0, 140)
	spear._physics_process(spear.attack_duration)
	if target.health != health:
		_fail("dodging during the windup did not avoid the spear")
		return
	_clear()
	target = _enemy(Vector2(100, 0))
	var far := _enemy(Vector2(180, 0))
	var behind := _enemy(Vector2(-100, 0))
	spear = _equip(&"toothpick_spear")
	spear._physics_process(0.01)
	# Save while winding up; then restore and cross the entire active stroke in one frame.
	var snapshot := RunSnapshot.capture(game)
	_clear()
	RunSnapshot.restore(game, snapshot)
	paused = true
	spear = game.player.loadout.equipped()[0]
	spear.set_physics_process(false)
	target = game.get_node("Enemies").get_child(0)
	far = game.get_node("Enemies").get_child(1)
	behind = game.get_node("Enemies").get_child(2)
	var restored_health := target.health
	spear._physics_process(spear.attack_duration * 0.55)
	if target.health >= restored_health or far.health >= restored_health or behind.health != restored_health:
		_fail("restored swept thrust missed its line or hit behind Denti")
		return
	var after_contact := target.health
	snapshot = RunSnapshot.capture(game)
	_clear()
	RunSnapshot.restore(game, snapshot)
	paused = true
	spear = game.player.loadout.equipped()[0]
	spear.set_physics_process(false)
	target = game.get_node("Enemies").get_child(0)
	spear._physics_process(spear.attack_time)
	if target.health != after_contact:
		_fail("resume hit an enemy twice in the same stroke")
		return
	_clear()
	target = _enemy(Vector2(85, 0))
	var slash := _equip(&"plaque_scaler")
	slash._physics_process(0.01)
	var initial := slash.sprite.rotation
	slash._physics_process(slash.attack_duration * 0.65)
	var cut_health := target.health
	if cut_health >= health or target.bleed_stacks != 1 or absf(angle_difference(initial, slash.sprite.rotation)) < 0.25:
		_fail("slash did not animate into a physical bleeding hit")
		return
	slash._physics_process(slash.attack_time)
	if target.health != cut_health or target.bleed_stacks != 1:
		_fail("one slash hit repeatedly during the contact window")
		return
	for id in [&"cavity_grinder", &"prophylaxis_polisher"]:
		_clear()
		_enemy(Vector2(50, 0))
		var tool := _equip(id)
		tool._physics_process(0.01)
		if tool.working_head == null or tool.working_head.face.texture == null:
			_fail("working head is missing: " + str(id))
			return
		var rotation := tool.working_head.spin_angle
		tool._physics_process(0.02)
		if tool.working_head.spin_angle == rotation:
			_fail("working head did not spin during the attack")
			return
	# Compact art must retain real contact at close range and the range boundary,
	# in every direction/tier, including the shrink applied to six-weapon builds.
	game.player.attack_performed.disconnect(game.sound.play_attack)
	for id in [&"turbo_drill", &"plaque_scaler", &"floss_whip", &"interdental_brush", &"floss_garrote", &"toothpick_spear", &"cavity_grinder", &"prophylaxis_polisher"]:
		for tier in range(1, 5):
			var data := WeaponCatalog.by_id(id)
			for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
				for distance in [45.0, data.range_at_tier(tier)]:
					_clear()
					var compact_target := _enemy(direction * distance)
					var compact := _equip(id)
					compact.tier = tier
					compact.visual_density = WeaponLayout.density_scale(6)
					compact._physics_process(0.001)
					if compact_target.health != 10000:
						_fail("compact weapon dealt damage before contact: " + str(id))
						return
					compact._physics_process(compact.attack_duration)
					if compact_target.health >= 10000:
						_fail("compact contact missed: %s tier %d direction %s distance %.0f" % [id, tier, direction, distance])
						return
	session.clear_run()
	paused = false
	game.free()
	print("Denti weapon motion test passed")
	quit(0)

func _equip(id: StringName) -> WeaponInstance:
	game.player.loadout.restore([{"id": str(id), "tier": 1}])
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	weapon.set_physics_process(false)
	return weapon

func _enemy(offset: Vector2) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.health = 10000
	enemy.max_health = 10000
	enemy.set_physics_process(false)
	return enemy

func _clear() -> void:
	for enemy in game.get_node("Enemies").get_children():
		enemy.free()
	for projectile in game.get_node("Projectiles").get_children():
		projectile.free()
	game.player.loadout.restore([])

func _fail(message: String) -> void:
	push_error(message)
	paused = false
	quit(1)
