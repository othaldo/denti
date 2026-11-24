extends "res://tests/support/test_runtime.gd"

var game: Node2D
## Enemy offsets are measured from this root anchor, where the weapon aims from.
var origin := Vector2.ZERO


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://test_floss_cut.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	paused = true
	game.player.stats.crit_chance = 0
	for id in [&"floss_garrote", &"floss_whip"]:
		_clear_enemies()
		var weapon := _equip(id)
		var double: bool = id == &"floss_garrote"
		check(not weapon.sprite.visible and weapon.floss_cut != null, "old rigid floss assembly still renders")
		check(weapon.floss_cut.strands.size() == (2 if double else 1), "wrong number of connected strands")
		var near := _enemy(Vector2(55, 0))
		var middle := _enemy(Vector2(115, 0))
		var distant := _enemy(Vector2(weapon.data.attack_range - 5, 0))
		var side := _enemy(Vector2(120, 100))
		var behind := _enemy(Vector2(-100, 0))
		var grips := _grips(weapon)
		weapon._begin_attack([near])
		weapon._physics_process(weapon.attack_duration * 0.2)
		check(near.health == 10000 and distant.health == 10000, "floss caused damage during windup")
		weapon._physics_process(weapon.attack_duration)
		check(near.health < 10000 and middle.health < 10000 and distant.health < 10000, "forward floss missed enemies along its path")
		check(side.health == 10000 and behind.health == 10000, "forward shot still uses an invisible front fan or roundabout attack")
		check(near.bleed_stacks == 1 and middle.bleed_stacks == 1 and distant.bleed_stacks == 1, "two strands duplicated damage/bleeding, or one target was missed")
		check(_grips(weapon) == grips, "grips moved away from their root positions during a shot")
		check(not game.element_impacts.events.is_empty(), "plain floss has no visible blood impact")
		if double:
			check(distant.global_position.x > game.player.global_position.x + origin.x + weapon.data.attack_range - 5, "double floss lost its outward knockback")
		# Both painted grips stay put throughout the complete cast in every aim direction.
		for density in [1.0, WeaponLayout.density_scale(6)]:
			weapon.visual_density = density
			for direction in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN, Vector2(1, 1).normalized()]:
				weapon.aim = direction
				for phase in [-1.0, 0.0, 0.15, 0.3, 0.5, 0.7, 0.9]:
					weapon.attack_time = 0 if phase < 0 else weapon.attack_duration * (1 - phase)
					weapon.update_visual()
					check(_grips(weapon) == grips, "aim or animation phase dislodged a grip")
					_check_connections(weapon)
		# Moving Denti carries the grips, never dragging them toward the enemy.
		var before := weapon.floss_cut.left.global_position
		game.player.global_position += Vector2(14, -8)
		weapon.update_visual()
		check(weapon.floss_cut.left.global_position.is_equal_approx(before + Vector2(14, -8)), "grip did not follow Denti")
		game.player.global_position -= Vector2(14, -8)
		# Save after a near hit but before the distant target: restore must not double-hit.
		_clear_enemies()
		weapon = _equip(id)
		near = _enemy(Vector2(55, 0))
		distant = _enemy(Vector2(weapon.data.attack_range - 5, 0))
		weapon._begin_attack([near])
		weapon._physics_process(weapon.attack_duration * 0.5)
		var after_near := near.health
		check(after_near < 10000 and distant.health == 10000, "floss dealt its distant damage before reaching that target")
		var curve_before := weapon.floss_cut.points
		var saved: Dictionary = RunSnapshot.capture(game)
		RunSnapshot.restore(game, saved)
		weapon = game.player.loadout.equipped()[0]
		weapon.set_physics_process(false)
		check(weapon.floss_cut.points == curve_before, "resume changed the extending strand")
		weapon._physics_process(weapon.attack_time)
		check(game.get_node("Enemies").get_child(0).health == after_near, "resume repeated a prior strand hit")
		check(game.get_node("Enemies").get_child(1).health < 10000, "resume lost the farther hit")
		# Retraction is visual only, even when a new enemy steps into the rope.
		_clear_enemies()
		weapon.attack_time = weapon.attack_duration * (1 - 0.8)
		var recovery_target := _enemy(Vector2(120, 0))
		weapon._physics_process(weapon.attack_time)
		check(recovery_target.health == 10000, "retracting floss dealt a second attack")
		# Seven forms use their own handle artwork, with exactly one/two live strands.
		for element in [&"", &"fire", &"ice", &"poison", &"electric", &"bleed", &"wet"]:
			var data := WeaponCatalog.by_id(id)
			var affixes: Array[Dictionary] = []
			if element != &"": affixes = WeaponUpgrades.advance([], element, data, 4)
			game.player.loadout.restore([{"id": str(id), "tier": 4, "affixes": affixes}])
			weapon = game.player.loadout.equipped()[0]
			weapon.set_physics_process(false)
			var tag := "normal" if element == &"" else str(element)
			check(weapon.floss_cut.left.texture.resource_path.ends_with("/%s_left_grip.png" % tag), "element uses stale handle artwork")
			check((weapon.floss_cut.right != null) == double, "single whip acquired a second handle")
			if double:
				check(weapon.floss_cut.right.texture.resource_path.ends_with("/%s_right_grip.png" % tag), "element uses stale second handle")
			check(weapon.floss_cut.strands.size() == (2 if double else 1), "skin swap changed strand count")
	session.clear_run()
	paused = false
	print("PASS floss: fixed grips, one/two connected forward strands, near/far groups, no side/rear hits, once per attack, knockback, recovery, resume, six elements and two densities")
	finish_checks()


func _equip(id: StringName) -> WeaponInstance:
	game.player.loadout.restore([{"id": str(id), "tier": 1}])
	var weapon: WeaponInstance = game.player.loadout.equipped()[0]
	weapon.set_physics_process(false)
	origin = weapon.home_position
	return weapon


func _grips(weapon: WeaponInstance) -> PackedVector2Array:
	var points := PackedVector2Array([weapon.floss_cut.left.position])
	if weapon.floss_cut.right != null: points.append(weapon.floss_cut.right.position)
	return points


func _check_connections(weapon: WeaponInstance) -> void:
	for index in weapon.floss_cut.strands.size():
		var grip := weapon.floss_cut.left if index == 0 else weapon.floss_cut.right
		var anchor := weapon.data.grip_anchor if index == 0 else Vector2(1 - weapon.data.grip_anchor.x, weapon.data.grip_anchor.y)
		var tip := weapon.data.floss_left_tip if index == 0 else weapon.data.floss_right_tip
		var at := grip.to_global((tip - anchor) * grip.texture.get_size())
		var drawn := weapon.to_global(weapon.floss_cut.strands[index][0])
		check(at.distance_to(drawn) < 0.01, "animated strand detached from its painted eyelet")


func _enemy(offset: Vector2) -> Enemy:
	game._create_enemy(WaveController.PLAQUE, game.player.global_position + origin + offset)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.health = 10000
	enemy.max_health = 10000
	enemy.set_physics_process(false)
	return enemy


func _clear_enemies() -> void:
	for enemy in game.get_node("Enemies").get_children(): enemy.free()
	game.element_impacts.clear()


