extends SceneTree

class LocalWarning extends Node2D:
	var enemy: Enemy
	func _draw() -> void:
		enemy.draw_attack_visuals(self)

class Preview extends Node2D:
	var entries: Array[Enemy] = []
	var atlas_fill := false
	var total_us := 0
	var frames := 0
	var verify_local := false
	var faded_raster := false
	var use_density := false
	var density := WarningVisualDensity.new()
	func _process(delta: float) -> void:
		if use_density and atlas_fill:
			density.update(delta, entries, entries.size())
		queue_redraw()
	func _draw() -> void:
		if verify_local:
			return
		var start := Time.get_ticks_usec()
		if use_density and atlas_fill:
			for enemy in entries:
				draw_set_transform_matrix(enemy.transform)
				enemy.draw_warning_fill(self, enemy.transform, density.scales.get(enemy.get_instance_id(), WarningVisualDensity.FULL_SCALES))
		for enemy in entries:
			var base := enemy.transform
			draw_set_transform_matrix(base)
			if use_density:
				enemy.draw_attack_visuals(self, base, WarningVisualDensity.NO_SCALES, not atlas_fill)
			elif atlas_fill:
				enemy.draw_attack_visuals(self, base, WarningVisualDensity.FULL_SCALES if faded_raster else WarningVisualDensity.NO_SCALES)
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
	preview.use_density = "--density" in OS.get_cmdline_user_args()
	for index in (20 if preview.use_density else 60):
		var enemy := Enemy.new()
		enemy.configure(WaveController.ACID_SPITTER, null, 17)
		enemy.position = Vector2(160, 360) if preview.use_density else Vector2(100 + index % 10 * 100, 90 + index / 10 * 100)
		enemy.special_direction = Vector2.RIGHT
		enemy.special_phase = Enemy.SpecialPhase.WARNING
		enemy.special_timer = enemy.data.warning_time * 0.5
		preview.entries.append(enemy)
	root.add_child(preview)
	if "--verify" in OS.get_cmdline_user_args() or "--verify-density" in OS.get_cmdline_user_args():
		preview.faded_raster = "--verify-density" in OS.get_cmdline_user_args()
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
	preview.atlas_fill = true
	preview.verify_local = not atlas_fill
	for child in preview.get_children():
		child.visible = preview.verify_local
		child.transform = child.enemy.transform
		child.queue_redraw()
	preview.queue_redraw()
	await process_frame
	await RenderingServer.frame_post_draw
	return root.get_texture().get_image()

func _verify(preview: Preview) -> void:
	# The art deliberately differs from the historical polygon baseline.
	# Verify identical alignment/tint through local and shared drawing paths.
	for enemy in preview.entries:
		var local := LocalWarning.new()
		local.enemy = enemy
		preview.add_child(local)
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
			print("New lane local/batch comparison progress %.2f transform %s: %.8f" % [progress, transform, mean])
			before.save_png("res://.godot/lane_reference.png")
			after.save_png("res://.godot/lane_atlas.png")
			if mean > 0.002:
				push_error("Local and batched warning transforms/tints differ")
				quit(1)
				return
	print("Textured lane native local/batch comparison passed")
	quit()
