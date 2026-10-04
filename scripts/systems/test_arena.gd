class_name TestArena
extends Node

var game: Node2D
var data: TestArenaData
var information: Label
var started_us: int = -1
var frames: int = 0
var minimum_fps: float = INF
var last_sample_us: int = -1
var sample_frames: int = 0
var previous_frame_us: int = -1
var maximum_frame_ms: float = 0.0
var slow_frames: int = 0

func _ready() -> void:
	seed(data.random_seed)
	var loadout: Array[Dictionary] = []
	for id in data.weapons:
		loadout.append({"id": str(id), "tier": data.weapon_tier})
	game.player.loadout.restore(loadout)
	for id in data.items:
		var item := ShopController.by_id(id)
		if item != null:
			game.items.acquire(item)
	game.player.stats.damage_bonus = 100
	game.player.stats.ranged_damage = 35
	game.player.stats.attack_speed = 80
	game.player.stats.crit_chance = 0.35
	game.player.stats.max_health = 100000
	game.player.stats.health = 100000
	game.wave.current_wave = data.wave_number
	game.wave.remaining = 600
	game.wave.active = true
	game.wave.set_process(false)
	game.rewards.begin_wave()
	game.telemetry.begin_wave(data.wave_number)
	game.items.on_wave_start()
	var at: Vector2 = game.player.global_position
	for number in data.enemy_count:
		_spawn(data.enemies[number % data.enemies.size()], at + Vector2.RIGHT.rotated(number * TAU / data.enemy_count) * (280 + number % 5 * 40))
	if data.boss != null:
		_spawn(data.boss, at + Vector2(300, 0))
	for number in data.loot_count:
		game._spawn_loot(at + Vector2(-750 + number % 60 * 25, -400 + number / 60 * 40), &"xp" if number % 2 == 0 else &"coin", 1)
	var canvas := CanvasLayer.new()
	canvas.layer = 5
	add_child(canvas)
	information = Label.new()
	information.position = Vector2(24, 156)
	information.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DentiUIStyle.style_hud_text(information, DentiUIStyle.INK, 14, 3, DentiUIStyle.BACKGROUND)
	canvas.add_child(information)
	game.hud.fps_panel.visible = true
	game._sync_music()
	game._refresh_hud()
	information.text = "TEST · %s\nMessung startet …" % data.display_name
	get_tree().paused = false
	process_priority = 2

func _spawn(enemy_data: EnemyData, at: Vector2) -> void:
	game._create_enemy(enemy_data, at)
	var enemy: Enemy = game.get_node("Enemies").get_child(-1)
	# Keep density stable while attacks, mark detonations and projectiles run normally.
	enemy.health = data.enemy_health
	enemy.max_health = data.enemy_health

func _notification(what: int) -> void:
	if what in [NOTIFICATION_PAUSED, NOTIFICATION_APPLICATION_FOCUS_OUT, NOTIFICATION_APPLICATION_FOCUS_IN]:
		last_sample_us = -1
		sample_frames = 0
		started_us = -1
		frames = 0
		minimum_fps = INF
		previous_frame_us = -1
		maximum_frame_ms = 0.0
		slow_frames = 0

func _process(_delta: float) -> void:
	# Native wall time avoids interpreting capped game delta as FPS on slow phones.
	var now := Time.get_ticks_usec()
	if previous_frame_us >= 0:
		var frame_ms := float(now - previous_frame_us) / 1000.0
		maximum_frame_ms = maxf(maximum_frame_ms, frame_ms)
		if frame_ms > 25.0:
			slow_frames += 1
	previous_frame_us = now
	if started_us < 0:
		started_us = now
		last_sample_us = now
		return
	frames += 1
	sample_frames += 1
	if now - last_sample_us < 1000000:
		return
	var fps := float(sample_frames) * 1000000.0 / (now - last_sample_us)
	minimum_fps = minf(minimum_fps, fps)
	var average := float(frames) * 1000000.0 / (now - started_us)
	var shots: int = game.get_node("Projectiles").get_child_count() + game.get_node("EnemyProjectiles").get_child_count()
	information.text = "TEST · %s\nGegner %d · Geschosse %d · Beute %d\nFPS Ø %.1f · Minimum %.1f · %s\nFrame max %.1f ms · >25 ms: %d" % [data.display_name, game.get_node("Enemies").get_child_count(), shots, game.get_node("Loot").get_child_count(), average, minimum_fps, str(ProjectSettings.get_setting("denti/build", "dev")), maximum_frame_ms, slow_frames]
	game.hud.timer_label.text = "TEST"
	last_sample_us = now
	sample_frames = 0
