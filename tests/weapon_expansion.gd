extends SceneTree

var game: Node2D


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_weapon_expansion.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	game.player.stats.crit_chance = 0.0
	if WeaponCatalog.ALL.size() != 18 or WeaponCatalog.STARTERS.size() != 3:
		_fail("catalog or starter count changed incorrectly")
		return
	for index in range(8, 18):
		var data := WeaponCatalog.ALL[index]
		var offer := ShopController.by_id(data.id)
		if offer == null or offer.weapon_data != data or offer.price != data.price or not data.sprite is AtlasTexture:
			_fail("missing shop or atlas integration: " + str(data.id))
			return
		var atlas := data.sprite as AtlasTexture
		if not atlas.filter_clip or not Rect2(Vector2.ZERO, atlas.atlas.get_size()).encloses(atlas.region):
			_fail("invalid atlas region: " + str(data.id))
			return
		for tier in range(1, 5):
			game.player.loadout.restore([{"id": str(data.id), "tier": tier, "invested_coins": 42}])
			var saved_loadout: Array[Dictionary] = game.player.loadout.save_data()
			game.player.loadout.restore(saved_loadout)
			if game.player.loadout.equipped()[0].tier != tier or game.player.loadout.refund_for(0) != 21:
				_fail("tier or economy failed round trip")
				return
			var card := OfferCard.new()
			root.add_child(card)
			card.show_offer(ShopController.weapon_offer(offer, tier), 100)
			if card.icon_rect.texture != data.sprite or data.damage_at_tier(tier) <= 0.0 or data.interval_at_tier(tier) <= 0.0:
				_fail("tier stats or shop sprite missing")
				return
			card.free()
	_clear()
	var front := _enemy(Vector2(100, 0))
	var along := _enemy(Vector2(180, 0))
	var side := _enemy(Vector2(0, 100))
	var behind := _enemy(Vector2(-100, 0))
	var spear := _equip(&"toothpick_spear")
	_attack(spear)
	if front.health >= 10000.0 or along.health >= 10000.0 or side.health != 10000.0 or behind.health != 10000.0:
		_fail("spear did not restrict hits to its forward line")
		return
	_clear()
	front = _enemy(Vector2(100, 0))
	along = _enemy(Vector2(450, 0))
	side = _enemy(Vector2(0, 150))
	var uv := _equip(&"uv_lamp")
	uv._physics_process(0.01)
	if front.health >= 10000.0 or along.health >= 10000.0 or side.health != 10000.0:
		_fail("UV did not pierce along the whole beam")
		return
	_clear()
	front = _enemy(Vector2(80, 0))
	side = _enemy(Vector2(55, 65))
	behind = _enemy(Vector2(-80, 0))
	var garrote := _equip(&"floss_garrote")
	_attack(garrote)
	if front.bleed_stacks != 1 or side.bleed_stacks != 1 or behind.health != 10000.0:
		_fail("garrote front arc or bleed failed")
		return
	_clear()
	front = _enemy(Vector2(80, 0))
	side = _enemy(Vector2(115, 25))
	behind = _enemy(Vector2(-80, 0))
	var turbine := _equip(&"water_turbine")
	var original: Vector2 = front.global_position
	turbine._physics_process(0.01)
	if front.wet_time != 3.0 or side.wet_time != 3.0 or behind.wet_time > 0.0 or front.global_position.x <= original.x:
		_fail("water cone, wet, or knockback failed")
		return
	_clear()
	front = _enemy(Vector2(80, 0))
	var spray := _equip(&"fluoride_sprayer")
	spray._physics_process(0.01)
	var brush := WeaponCatalog.by_id(&"magic_toothbrush")
	var metal := WeaponCatalog.by_id(&"amalgam_slingshot")
	if front.exposure_time != 2.0 or not is_equal_approx(brush.damage_against(front, 100.0), 120.0) or not is_equal_approx(metal.damage_against(front, 100.0), 100.0):
		_fail("spray exposure should only increase enamel damage")
		return
	spray.cooldown = 0.0
	spray._physics_process(0.01)
	if not is_equal_approx(brush.damage_against(front, 100.0), 120.0):
		_fail("exposure stacked beyond its cap")
		return
	var snapshot := RunSnapshot.capture(game)
	if snapshot["enemies"][0]["exposure_time"] != 2.0:
		_fail("exposure was not captured for resume")
		return
	_clear()
	RunSnapshot.restore(game, snapshot)
	front = game.get_node("Enemies").get_child(0)
	if front.exposure_time != 2.0 or not is_equal_approx(front.enamel_exposure, 0.2):
		_fail("resume lost exposure")
		return
	front._physics_process(2.01)
	if front.exposure_time > 0.0 or not is_equal_approx(brush.damage_against(front, 100.0), 100.0):
		_fail("exposure did not expire")
		return
	_clear()
	front = _enemy(Vector2(50, 0))
	var grinder := _equip(&"cavity_grinder")
	var health_before := front.health
	_attack(grinder)
	var first_hit := health_before - front.health
	for index in 15:
		grinder.cooldown = 0.0
		_attack(grinder)
	snapshot = RunSnapshot.capture(game)
	_clear()
	RunSnapshot.restore(game, snapshot)
	front = game.get_node("Enemies").get_child(0)
	front.set_physics_process(false)
	front.health = 10000.0
	front.max_health = 10000.0
	grinder = game.player.loadout.equipped()[0]
	grinder.set_physics_process(false)
	if grinder.focus_hits != 16 or grinder.focus_target_id != front.get_instance_id() or grinder.focus_time <= 0.0 or grinder.cooldown <= 0.0:
		_fail("resume lost focus target, counter, or cooldown")
		return
	health_before = front.health
	grinder.cooldown = 0.0
	_attack(grinder)
	if not is_equal_approx((health_before - front.health) / first_hit, 1.5):
		_fail("grinder focus did not cap at 50 percent")
		return
	var fresh := _enemy(Vector2(30, 0))
	# Both remain in range; the fresh enemy is now nearer the weapon's own hand.
	front.global_position = game.player.global_position + Vector2(-50, 0)
	grinder.cooldown = 0.0
	_attack(grinder)
	if not is_equal_approx(10000.0 - fresh.health, first_hit):
		_fail("grinder focus leaked to a new target")
		return
	_clear()
	front = _enemy(Vector2(50, 0))
	var polisher := _equip(&"prophylaxis_polisher")
	for index in 3:
		polisher.cooldown = 0.0
		_attack(polisher)
	if not game.player.stats.last_roll_critical:
		_fail("third polishing hit was not guaranteed critical")
		return
	_clear()
	front = _enemy(Vector2(40, 0))
	var interdental := _equip(&"interdental_brush")
	_attack(interdental)
	if front.bleed_stacks != 1:
		_fail("interdental brush did not apply bleed")
		return
	_clear()
	front = _enemy(Vector2(100, 0))
	side = _enemy(Vector2(100, 70))
	var rocket: WeaponProjectile = load("res://scenes/game/weapon_projectile.tscn").instantiate()
	game.get_node("Projectiles").add_child(rocket)
	rocket.launch(game.player.global_position, Vector2.RIGHT, 58.0, WeaponCatalog.by_id(&"fluoride_rocket"), game.items)
	rocket._physics_process(0.5)
	if front.health >= 10000.0 or side.health >= 10000.0 or rocket.impact_time <= 0.0:
		_fail("rocket tunneled past targets or missed its splash")
		return
	_clear()
	front = _enemy(Vector2(100, 0))
	var ball: WeaponProjectile = load("res://scenes/game/weapon_projectile.tscn").instantiate()
	game.get_node("Projectiles").add_child(ball)
	ball.launch(game.player.global_position + Vector2(100, 0), Vector2.RIGHT, 24.0, metal, game.items)
	original = front.global_position
	ball._explode()
	if front.health >= 10000.0 or front.global_position == original:
		_fail("amalgam splash did not apply knockback")
		return
	game._open_shop()
	game.player.loadout.restore([])
	game.coins = 100
	game.shop.offers[0] = ShopController.weapon_offer(ShopController.by_id(&"fluoride_rocket"), 3)
	game._on_shop_buy(0)
	if game.player.loadout.equipped()[0].tier != 3 or game.player.loadout.used_slots() != 2:
		_fail("new weapon shop purchase failed")
		return
	game._save_run()
	if session.load_run()["weapons"][0]["id"] != "fluoride_rocket":
		_fail("new weapon identity was not saved")
		return
	session.clear_run()
	paused = false
	game.free()
	print("Denti weapon expansion test passed")
	call_deferred("quit", 0)


func _enemy(offset: Vector2) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.health = 10000.0
	enemy.max_health = 10000.0
	enemy.set_physics_process(false)
	enemy.set_process(false)
	return enemy


func _equip(id: StringName) -> WeaponInstance:
	game.player.loadout.restore([{"id": str(id), "tier": 1}])
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	weapon.set_physics_process(false)
	return weapon


func _clear() -> void:
	for enemy in game.get_node("Enemies").get_children():
		enemy.free()
	for projectile in game.get_node("Projectiles").get_children():
		projectile.free()
	game.player.loadout.restore([])


func _fail(message: String) -> void:
	root.get_node("GameSession").clear_run()
	paused = false
	push_error(message)
	quit(1)


func _attack(weapon: WeaponInstance) -> void:
	weapon._physics_process(0.01)
	if WeaponMotion.is_contact(weapon.data):
		weapon._physics_process(weapon.attack_duration)
