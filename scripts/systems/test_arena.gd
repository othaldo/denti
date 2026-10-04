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
var diagnostics: CombatDiagnostics
var copy_button: Button
var diagnostic_layout: VBoxContainer
var latest_fps := 0.0
var latest_draw_calls := 0.0
var frame_histogram := PackedInt32Array()
var histogram_count := 0

func _ready() -> void:
	diagnostics = game.get_node_or_null("CombatDiagnostics") as CombatDiagnostics
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
	if diagnostics != null:
		frame_histogram.resize(2048)
		var layout := VBoxContainer.new()
		diagnostic_layout = layout
		layout.position = Vector2(24, 156)
		layout.size.x = maxf(game.get_viewport_rect().size.x - 48.0, 1.0)
		canvas.add_child(layout)
		canvas.remove_child(information)
		information.position = Vector2.ZERO
		information.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
		layout.add_child(information)
		game.get_viewport().size_changed.connect(_resize_diagnostics)
		copy_button = Button.new()
		copy_button.text = "Bericht kopieren"
		copy_button.size_flags_horizontal = Control.SIZE_SHRINK_BEGIN
		DentiUIStyle.style_button(copy_button)
		copy_button.pressed.connect(func() -> void: DisplayServer.clipboard_set(report_text()))
		layout.add_child(copy_button)
		_apply_diagnostic()
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
		latest_fps = 0.0
		latest_draw_calls = 0.0
		slow_frames = 0
		histogram_count = 0
		frame_histogram.fill(0)
		if is_instance_valid(diagnostics):
			diagnostics.reset()

func _process(_delta: float) -> void:
	# Native wall time avoids interpreting capped game delta as FPS on slow phones.
	var now := Time.get_ticks_usec()
	if previous_frame_us >= 0:
		var frame_ms := float(now - previous_frame_us) / 1000.0
		maximum_frame_ms = maxf(maximum_frame_ms, frame_ms)
		if frame_ms > 25.0:
			slow_frames += 1
		if diagnostics != null:
			frame_histogram[mini(floori(frame_ms), frame_histogram.size() - 1)] += 1
			histogram_count += 1
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
	latest_fps = average
	latest_draw_calls = Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
	var shots: int = game.get_node("Projectiles").get_child_count() + game.get_node("EnemyProjectiles").get_child_count()
	information.text = "TEST · %s\nGegner %d · Geschosse %d · Beute %d\nFPS Ø %.1f · Minimum %.1f · %s\nFrame max %.1f ms · >25 ms: %d" % [data.display_name, game.get_node("Enemies").get_child_count(), shots, game.get_node("Loot").get_child_count(), average, minimum_fps, str(ProjectSettings.get_setting("denti/build", "dev")), maximum_frame_ms, slow_frames]
	if diagnostics != null:
		information.text += "\nP95≈ %.0f ms · CPU≈ ms/Frame (1/10)\nGegner %.2f · Waffen %.2f\nP-Gesch %.2f · G-Gesch %.2f\nTreffer %.2f · Effekte %.2f\nBeute %.2f · Text %.2f\nZeichnen %.2f · Draw %.0f\nSave %.1f ms · Teilzeiten überlappen\nGPU-Zeit nicht gemessen" % [percentile(0.95), diagnostics.milliseconds(&"enemy_physics") + diagnostics.milliseconds(&"enemy_visuals"), diagnostics.milliseconds(&"weapons"), diagnostics.milliseconds(&"player_projectiles"), diagnostics.milliseconds(&"enemy_projectiles"), diagnostics.milliseconds(&"hits"), diagnostics.milliseconds(&"effects"), diagnostics.milliseconds(&"loot"), diagnostics.milliseconds(&"text_updates"), diagnostics.milliseconds(&"drawing"), latest_draw_calls, diagnostics.save_ms]
	game.hud.timer_label.text = "TEST"
	last_sample_us = now
	sample_frames = 0

func _resize_diagnostics() -> void:
	diagnostic_layout.size.x = maxf(game.get_viewport_rect().size.x - 48.0, 1.0)

func _apply_diagnostic() -> void:
	if data.diagnostic == TestArenaData.Diagnostic.NO_TEXT:
		game.get_node("DamageNumbers").hide()
	elif data.diagnostic == TestArenaData.Diagnostic.NO_DRAW:
		for path in ["Arena", "Enemies", "Projectiles", "EnemyProjectiles", "Loot", "Player", "Items", "Relics", "DamageNumbers"]:
			(game.get_node(path) as CanvasItem).hide()

func report_text() -> String:
	return JSON.stringify({"code": data.code, "build": str(ProjectSettings.get_setting("denti/build", "dev")), "seconds": float(Time.get_ticks_usec() - started_us) / 1000000.0 if started_us >= 0 else 0.0, "fps_average": latest_fps, "fps_minimum": minimum_fps if minimum_fps != INF else 0.0, "frame_max_ms": maximum_frame_ms, "frame_p95_ms_approx": percentile(0.95), "frame_p99_ms_approx": percentile(0.99), "slow_frames": slow_frames, "draw_calls_snapshot": latest_draw_calls, "texture_memory_bytes_snapshot": Performance.get_monitor(Performance.RENDER_TEXTURE_MEM_USED), "cpu_estimated_ms_per_frame": diagnostics.snapshot() if diagnostics != null else {}, "save_last_ms": diagnostics.save_ms if diagnostics != null else 0.0, "graphics_mode": int(game.session.graphics_mode), "enemies": game.get_node("Enemies").get_child_count(), "player_shots": game.get_node("Projectiles").get_child_count(), "enemy_shots": game.get_node("EnemyProjectiles").get_child_count(), "loot": game.get_node("Loot").get_child_count()}, "\t")

func percentile(fraction: float) -> float:
	if histogram_count == 0:
		return 0.0
	var needed := ceili(histogram_count * fraction)
	var seen := 0
	for index in frame_histogram.size():
		seen += frame_histogram[index]
		if seen >= needed:
			return float(index + 1)
	return 2048.0
