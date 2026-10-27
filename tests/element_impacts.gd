extends "res://tests/support/test_runtime.gd"

var game: Node2D
var failures := 0


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://test_element_impacts.json"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	paused = true
	var batch: ElementImpactBatch = game.element_impacts
	game.items.effect_context.cooldowns["enchantment_electric"] = 100.0
	_check(batch.get_index() < game.get_node("Enemies").get_index(), "stains cover enemy warnings")
	_check(batch.burst_layer.get_index() > game.get_node("Enemies").get_index() and batch.burst_layer.get_index() < game.get_node("EnemyProjectiles").get_index(), "bursts cover hostile projectiles or sit below enemy bodies")
	var hostile: Node2D = preload("res://scenes/enemies/acid_projectile.tscn").instantiate()
	_check(batch.burst_layer.z_index == 3 and batch.burst_layer.z_index < hostile.z_index, "impact z-order obscures hostile projectiles")
	hostile.free()
	_check(batch.ATLAS.get_image().has_mipmaps(), "impact atlas lacks mipmaps")
	for id in WeaponElementVisuals.ELEMENTS:
		game._clear_arena(false)
		await process_frame
		batch.clear()
		var enemy := _enemy(game.player.global_position + Vector2(100, 0))
		var data := WeaponCatalog.by_id(&"magic_toothbrush")
		var affixes := WeaponUpgrades.advance([], id, data, 4)
		var shot := game.get_node("Projectiles").acquire(data, 1) as WeaponProjectile
		shot.launch(enemy.global_position - Vector2(70, 0), Vector2.RIGHT, 10, data, game.items, false, 1, affixes)
		shot._physics_process(0.2)
		_check(batch.events.size() == 1 and batch.events[0].profile.element == id and enemy.health < 10000, "projectile has no matching world impact: " + str(id))
		var impact_at: Vector2 = batch.events[0].at
		enemy.global_position += Vector2(120, 0)
		shot.retire()
		batch._physics_process(WeaponProjectile.IMPACT_DURATION + 0.02)
		_check(not batch.events.is_empty() and batch.events[0].at == impact_at, "impact followed its enemy or vanished with the projectile")
		if not enemy.affix_effects.pending.is_empty():
			batch.clear()
			enemy.affix_effects.advance(enemy, 0.25)
			_check(batch.events.is_empty(), "DoT tick replays a full impact")
		# A real swept melee strike uses exactly the same hit feedback path.
		batch.clear()
		game.player.loadout.restore([{"id": "toothpick_spear", "tier": 4, "affixes": affixes}])
		var melee: WeaponInstance = game.player.loadout.equipped()[0]
		melee.set_physics_process(false)
		enemy.global_position = game.player.global_position + Vector2(95, 0)
		game.get_node("Enemies").update(enemy)
		melee._begin_attack([enemy])
		melee._physics_process(melee.attack_duration)
		_check(batch.events.size() == 1 and batch.events[0].profile.element == id, "melee lacks elemental impact: " + str(id))
		# Splash emits one full-size explosion, not one burst per damaged enemy.
		batch.clear()
		var mortar := WeaponCatalog.by_id(&"mouthwash_mortar")
		var blast_affixes := WeaponUpgrades.advance([], id, mortar, 4)
		enemy.global_position = game.player.global_position + Vector2(300, 0)
		game.get_node("Enemies").update(enemy)
		var neighbor := _enemy(enemy.global_position + Vector2(30, 0))
		var bomb := game.get_node("Projectiles").acquire(mortar, 4) as WeaponProjectile
		bomb.launch(enemy.global_position, Vector2.RIGHT, 10, mortar, game.items, false, 4, blast_affixes)
		bomb._explode()
		_check(batch.events.size() == 1 and batch.events[0].area and is_equal_approx(batch.events[0].radius, mortar.splash_at_tier(4)), "splash feedback duplicates per target or ignores blast radius")
		_check(neighbor.health < 10000, "splash feedback changed actual area damage")
		var health := neighbor.health
		batch._physics_process(2.0)
		_check(batch.events.is_empty() and neighbor.health == health, "visual puddle damages targets or never expires")
		batch.clear()
		# Repeated hits are coalesced; no visual allocation changes combat RNG.
		seed(123)
		var expected_random := randf()
		seed(123)
		for hit in 100:
			batch.emit_impact(id, Vector2(400, 400), Vector2.RIGHT, 30)
		_check(batch.events.size() == 1 and randf() == expected_random, "dense hits bypass coalescing or alter combat randomness")
		batch.clear()
	# Caps, rejected values, reset and resume never retain references to targets.
	for hit in 400: batch.emit_impact(&"bleed", Vector2(hit * 30, 500), Vector2.RIGHT, 40)
	_check(batch.events.size() == ElementImpactBatch.MAX_EVENTS and batch.get_child_count() == 0, "impact budget creates per-hit nodes or grows unbounded")
	_check(not batch.emit_impact(&"holy", Vector2.ZERO, Vector2.RIGHT, 30) and not batch.emit_impact(&"fire", Vector2.INF, Vector2.RIGHT, 30), "invalid cosmetic event accepted")
	var saved: Dictionary = RunSnapshot.capture(game)
	RunSnapshot.restore(game, saved)
	_check(batch.events.is_empty(), "resume retained transient impacts")
	batch.emit_impact(&"wet", Vector2(500, 500), Vector2.RIGHT, 40)
	game._clear_combat()
	_check(batch.events.is_empty(), "wave cleanup left floor impacts")
	session.clear_run()
	paused = false
	print("PASS elemental impacts: six real projectile/melee/splash hits, independent life, correct radius, cosmetic-only damage, batching, limits, layer order, RNG isolation and resume")
	finish(1 if failures > 0 else 0)


func _enemy(at: Vector2) -> Enemy:
	game._create_enemy(preload("res://data/enemies/bacteria.tres"), at)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.health = 10000
	enemy.max_health = 10000
	enemy.set_physics_process(false)
	return enemy


func _check(ok: bool, message: String) -> void:
	if not ok:
		failures += 1
		push_error(message)
