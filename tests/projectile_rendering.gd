extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_projectile_rendering.json"
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	paused = true
	game.wave.active = false
	game.player.loadout.restore([])
	var scene: PackedScene = load("res://scenes/enemies/acid_projectile.tscn")
	var projectiles: Node2D = game.get_node("EnemyProjectiles")
	var at: Vector2 = game.player.global_position + Vector2(100, 0)
	var first: AcidProjectile = scene.instantiate()
	var second: AcidProjectile = scene.instantiate()
	projectiles.add_child(first)
	projectiles.add_child(second)
	first.launch(at, Vector2.LEFT, 60, 7, game.player, EnemyProjectilePatterns.BOSS_COLOR)
	second.launch(at, Vector2.LEFT, 60, 7, game.player, EnemyProjectilePatterns.BOSS_COLOR)
	if first.body_sprite.texture != second.body_sprite.texture:
		_fail("identical bullets do not share their rendered texture")
		return
	var cache_size := EnemyProjectileVisuals.textures.size()
	var health: float = game.player.stats.health
	first._physics_process(0.5)
	if not first.global_position.is_equal_approx(at + Vector2(-30, 0)) or not is_equal_approx(first.lifetime, 1.7) or game.player.stats.health != health:
		_fail("rendering optimization changed movement, lifetime or distant hits")
		return
	if EnemyProjectileVisuals.textures.size() != cache_size or first.body_sprite.texture != second.body_sprite.texture:
		_fail("bullet animation regenerated its texture")
		return
	game.player.stats.armor = 0
	game.player.hurt_time = 0
	first.global_position = game.player.global_position
	first._physics_process(0)
	if not first.is_queued_for_deletion() or not is_equal_approx(game.player.stats.health, health - 7):
		_fail("cached bullet did not inflict its original collision damage")
		return
	first.free()
	second.lifetime = 0.001
	second._physics_process(0.01)
	if not second.is_queued_for_deletion():
		_fail("expired bullet survived")
		return
	second.free()
	EnemyProjectilePatterns.fire_space_orb(projectiles, at, Vector2.UP, 120, 9, 42, game.player)
	var orb: AcidProjectile = projectiles.get_child(-1)
	var halo_scale := orb.halo_sprite.scale
	orb._physics_process(0.1)
	if orb.halo_sprite == null or orb.halo_sprite.scale != halo_scale or orb.hit_radius != 42 or not is_equal_approx(orb.visual_radius, 29.4):
		_fail("orb warning radius changed with its pulse")
		return
	var snapshot := RunSnapshot.capture(game)
	game._save_run()
	session.resume_requested = true
	paused = false
	change_scene_to_file("res://scenes/game/game.tscn")
	await process_frame
	await process_frame
	game = current_scene
	paused = true
	var restored: AcidProjectile = game.get_node("EnemyProjectiles").get_child(0)
	var saved: Dictionary = snapshot["acid"][0]
	if restored.halo_sprite == null or restored.body_sprite.texture != EnemyProjectileVisuals.body(restored.projectile_color, restored.visual_radius) or restored.hit_radius != saved["hit_radius"] or not is_equal_approx(restored.damage, 9):
		_fail("saved orb lost its shared visual, collision radius or damage")
		return
	session.clear_run()
	paused = false
	print("Denti projectile rendering test passed")
	quit(0)


func _fail(message: String) -> void:
	push_error(message)
	paused = false
	quit(1)
