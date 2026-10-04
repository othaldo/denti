extends SceneTree


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_combat_feedback_run.json"
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel._on_choice_pressed(0)
	game.wave.active = false
	var enemy_data: EnemyData = WaveController.PLAQUE.duplicate()
	enemy_data.max_health = 500.0
	game._spawn_enemy(enemy_data)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	enemy.global_position = game.player.global_position + Vector2(100.0, 0.0)
	enemy.set_simulation_enabled(false)
	for frame in 3:
		await physics_frame
	if not _has_sound(game.sound, SoundController.SHOOT):
		_fail("toothbrush shot has no sound")
		return
	var hit_number: DamageNumber
	for frame in 40:
		await physics_frame
		if game.get_node("DamageNumbers").get_child_count() > 0:
			hit_number = game.get_node("DamageNumbers").get_child(0)
			break
	if hit_number == null or enemy.health >= enemy.max_health or int(hit_number.text) < 1:
		_fail("hitting an enemy did not show damage")
		return
	if not _has_sound(game.sound, SoundController.HIT):
		_fail("enemy hit has no sound")
		return
	var health_before: float = game.player.stats.health
	var numbers_before: int = game.get_node("DamageNumbers").get_child_count()
	game.player.take_hit(8.0)
	if game.player.stats.health >= health_before or game.get_node("DamageNumbers").get_child_count() != numbers_before + 1:
		_fail("player hit did not show health loss")
		return
	var hurt_number: DamageNumber = game.get_node("DamageNumbers").get_child(-1)
	if not hurt_number.text.begins_with("-") or not _has_sound(game.sound, SoundController.HURT):
		_fail("player hit has no red number or sound")
		return
	game.player.loadout.acquire(WeaponCatalog.by_id(&"floss_whip"))
	await _wait_for_attack(game.sound, SoundController.FLOSS)
	if not _has_sound(game.sound, SoundController.FLOSS):
		_fail("floss attack has no sound")
		return
	game.player.loadout.acquire(WeaponCatalog.by_id(&"turbo_drill"))
	await _wait_for_attack(game.sound, SoundController.DRILL)
	if not _has_sound(game.sound, SoundController.DRILL):
		_fail("drill attack has no sound")
		return
	game._spawn_enemy(WaveController.ACID_SPITTER)
	var acid_enemy: Enemy = game.get_node("Enemies").get_child(-1)
	acid_enemy.set_simulation_enabled(false)
	acid_enemy.special_direction = Vector2.RIGHT
	acid_enemy._activate_special()
	if not _has_sound(game.sound, SoundController.ACID):
		_fail("acid projectile has no launch sound")
		return
	game._on_loot_collected(&"coin", 1)
	if not _has_sound(game.sound, SoundController.PICKUP):
		_fail("loot pickup has no sound")
		return
	enemy.take_damage(9999.0)
	if not _has_sound(game.sound, SoundController.DOWN):
		_fail("enemy defeat has no sound")
		return
	session.clear_run()
	print("Denti combat feedback test passed")
	quit(0)


func _wait_for_attack(sound: SoundController, effect: AudioStreamWAV) -> void:
	for frame in 90:
		await physics_frame
		if _has_sound(sound, effect):
			return


func _has_sound(sound: SoundController, effect: AudioStreamWAV) -> bool:
	for voice in sound.voices:
		if voice.stream == effect and voice.playing:
			return true
	return false


func _fail(message: String) -> void:
	root.get_node("GameSession").clear_run()
	push_error(message)
	quit(1)
