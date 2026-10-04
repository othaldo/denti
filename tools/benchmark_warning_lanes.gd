extends SceneTree

class Preview extends Node2D:
	var entries: Array[Enemy] = []
	var atlas_fill := false
	var total_us := 0
	var frames := 0
	func _process(_delta: float) -> void:
		queue_redraw()
	func _draw() -> void:
		var start := Time.get_ticks_usec()
		for enemy in entries:
			var base := enemy.transform
			draw_set_transform_matrix(base)
			if atlas_fill:
				enemy.draw_attack_visuals(self, base)
			else:
				var lane_color := Color(0.50, 0.88, 0.14, 0.9)
				var progress := 1.0 - clampf(enemy.special_timer / maxf(enemy.data.warning_time, 0.01), 0.0, 1.0)
				var tint := enemy.modulate * enemy.self_modulate
				var direction := enemy.special_direction.normalized()
				var side := direction.orthogonal() * (enemy.data.lane_projectile_spacing * float(enemy.data.lane_projectile_count - 1) * 0.5 + 21.0)
				var end := direction * 550.0
				draw_colored_polygon(PackedVector2Array([-side, end - side, end + side, side]), Color(lane_color, 0.10 + progress * 0.12) * tint)
				CombatDrawCache.line(self, -side, end - side, lane_color, 3.0, base, tint)
				CombatDrawCache.line(self, side, end + side, lane_color, 3.0, base, tint)
				CombatDrawCache.arc(self, Vector2.ZERO, enemy.data.radius + 8, -PI / 2, -PI / 2 + TAU * progress, 32, lane_color, 4, base, tint)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		total_us += Time.get_ticks_usec() - start
		frames += 1

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Run warning benchmark with native rendering enabled")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	CombatDrawCache.prepare()
	var preview := Preview.new()
	for index in 60:
		var enemy := Enemy.new()
		enemy.configure(WaveController.ACID_SPITTER, null, 17)
		enemy.position = Vector2(100 + index % 10 * 100, 90 + index / 10 * 100)
		enemy.special_direction = Vector2.RIGHT
		enemy.special_phase = Enemy.SpecialPhase.WARNING
		enemy.special_timer = enemy.data.warning_time * 0.5
		preview.entries.append(enemy)
	root.add_child(preview)
	if "--verify" in OS.get_cmdline_user_args():
		await _verify(preview)
		for enemy in preview.entries:
			enemy.free()
		preview.free()
		return
	for atlas_fill in [false, true, false, true]:
		preview.atlas_fill = atlas_fill
		for frame in 100:
			await process_frame
		preview.total_us = 0
		preview.frames = 0
		var start := Time.get_ticks_usec()
		for frame in 600:
			await process_frame
		print("atlas_fill=%s wall_ms=%.3f draw_ms=%.3f calls=%d" % [atlas_fill, float(Time.get_ticks_usec() - start) / 600000.0, float(preview.total_us) / maxi(preview.frames, 1) / 1000.0, Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)])
	for enemy in preview.entries:
		enemy.free()
	preview.free()
	quit()

func _capture(preview: Preview, atlas_fill: bool) -> Image:
	preview.atlas_fill = atlas_fill
	preview.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _verify(preview: Preview) -> void:
	for progress in [0.05, 0.5, 0.95]:
		for transform in [Transform2D.IDENTITY, Transform2D(0.3, Vector2(0.7, 1.2), 0.15, Vector2.ZERO), Transform2D(-0.2, Vector2(-1.0, 0.8), 0.0, Vector2.ZERO)]:
			for index in preview.entries.size():
				var enemy := preview.entries[index]
				var at := enemy.position
				enemy.transform = transform
				enemy.position = at
				enemy.special_direction = Vector2.from_angle(0.03 * index)
				enemy.special_timer = enemy.data.warning_time * (1.0 - progress)
				enemy.modulate = Color(1.1, 0.9, 0.8, 0.8)
			var before := await _capture(preview, false)
			var after := await _capture(preview, true)
			var left := before.get_data()
			var right := after.get_data()
			var difference := 0
			for index in left.size():
				difference += absi(int(left[index]) - int(right[index]))
			var mean := float(difference) / left.size() / 255.0
			print("Lane pixel comparison progress %.2f transform %s: %.8f" % [progress, transform, mean])
			before.save_png("res://.godot/lane_reference.png")
			after.save_png("res://.godot/lane_atlas.png")
			if mean > 0.002:
				push_error("Lane raster differs from the polygon reference")
				quit(1)
				return
	print("Lane native pixel comparison passed")
	quit()
