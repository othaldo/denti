extends "res://tests/support/test_runtime.gd"
## Real shared draw functions, old atlas vs analytic masks, with native timings.

const LEGACY := preload("res://tools/support/legacy_warning_effects.gd")
const AA := preload("res://scripts/vfx/warning_antialias.gd")
const LANE := preload("res://scripts/vfx/neon_charge_preview_lane.gd")
const OUTPUT := "res://.godot/warning_quality"

class Probe extends Node2D:
	var amount := 1
	var clock := 0.0
	var frozen := false
	var draw_us := 0
	var draws := 0
	var diagnostic := false
	func _process(delta: float) -> void:
		if not frozen: clock += delta
		queue_redraw()
	func _draw() -> void:
		var begin := Time.get_ticks_usec()
		if diagnostic:
			# Enlarged 80px ring, angled 64px front, a small ring and untouched art.
			LEGACY.timer(self, Vector2(270, 230), 170, 0.73, Color(1, 0.62, 0.24))
			LEGACY.charge(self, Vector2.ZERO, Vector2(405, -135), 76, 420, Color(1, 0.43, 0.2, 0.9), 0.8, Transform2D(0, Vector2(70, 570)))
			LEGACY.timer(self, Vector2(110, 680), 25, 0.6, Color(1, 0.62, 0.24))
			draw_texture_rect_region(AttackEffects.ATLAS, Rect2(210, 620, 110, 110), AttackEffects.region(AttackEffects.Shape.FLASH, 0), Color(0.7, 0.8, 1, 0.8))
			draw_circle(Vector2(400, 680), 24, Color(0.2, 0.5, 0.8, 0.7), true, -1, true)
		else:
			for index in amount:
				var at := Vector2(220 + index % 8 * 115, 190 + (index / 8) % 4 * 105)
				var progress := 0.18 + fposmod(clock * 0.22 + index * 0.13, 0.80)
				if index % 2 == 0:
					LEGACY.timer(self, at, 30 + index % 5 * 26, progress, Color(1, 0.62, 0.24, 0.8))
				else:
					var origin := at - Vector2(170, 0)
					var end := at + Vector2.from_angle(index * 0.31) * 320 - origin
					LEGACY.charge(self, Vector2.ZERO, end, 23 + index % 4 * 16, 400, Color(1, 0.43, 0.2, 0.65), progress, Transform2D(0, origin))
		draw_us += Time.get_ticks_usec() - begin
		draws += 1

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Native rendering is required")
		finish(1)
		return
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.size = Vector2i(1120, 800)
	root.content_scale_size = root.size
	var floor := DentiArena.new()
	floor.z_index = -100
	root.add_child(floor)
	var old_material := CanvasItemMaterial.new()
	var probe := Probe.new()
	root.add_child(probe)
	AA.apply_to(probe)
	var new_material := probe.material
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	if "--capture" in OS.get_cmdline_user_args():
		probe.diagnostic = true
		probe.frozen = true
		probe.position = Vector2(0, 30)
		probe.material = old_material
		var right := Probe.new()
		right.diagnostic = true
		right.frozen = true
		right.position = Vector2(560, 30)
		right.material = new_material
		root.add_child(right)
		for column in 2:
			var title := Label.new()
			title.text = "Textur vergrößert" if column == 0 else "Kontur direkt berechnet"
			title.position = Vector2(30 + column * 560, 35)
			title.add_theme_font_size_override("font_size", 26)
			title.add_theme_color_override("font_color", Color("fff1ce"))
			title.add_theme_color_override("font_shadow_color", Color("25212d"))
			title.add_theme_constant_override("shadow_offset_y", 2)
			root.add_child(title)
		for scale_factor in [1, 2]:
			root.size = Vector2i(1120, 800) * scale_factor
			for frame in 10: await process_frame
			await RenderingServer.frame_post_draw
			root.get_texture().get_image().save_png(OUTPUT.path_join("edges_%dx.png" % scale_factor))
		root.size = Vector2i(1120, 800)
		for frame in 5: await process_frame
		await RenderingServer.frame_post_draw
		var before := root.get_texture().get_image()
		probe.material = new_material
		probe.queue_redraw()
		for frame in 5: await process_frame
		await RenderingServer.frame_post_draw
		var after := root.get_texture().get_image()
		for rect in [Rect2i(210, 650, 110, 110), Rect2i(370, 680, 60, 60)]:
			assert(before.get_region(rect).get_data() == after.get_region(rect).get_data(), "Analytic material altered unrelated atlas art or primitive tint")
		print("PASS native warning quality: unrelated art/primitive pixels preserved at identical coordinates")
		finish()
		return
	var modern := Node2D.new()
	root.add_child(modern)
	var lanes: Array[NeonChargePreviewLane] = []
	for index in 60:
		var lane: NeonChargePreviewLane = LANE.new()
		lane.cinematic = true
		modern.add_child(lane)
		var at := Vector2(180 + index % 8 * 110, 150 + (index / 8) % 4 * 105)
		lane.configure(at, at + Vector2.from_angle(index * 0.31) * 400, 35)
		lane.set_release(-1, 0.65)
		lanes.append(lane)
	var results: Array[Dictionary] = []
	for size in [Vector2i(1280, 720), Vector2i(2560, 1440)]:
		root.size = size
		root.content_scale_size = Vector2i(1280, 720)
		for amount in [1, 20, 60]:
			probe.amount = amount
			for index in lanes.size(): lanes[index].visible = index < amount
			for mode in ["raster", "analytic", "modern", "analytic", "raster"]:
				probe.visible = mode != "modern"
				modern.visible = mode == "modern"
				probe.material = new_material if mode == "analytic" else old_material
				var samples: Array[float] = []
				var calls := 0.0
				var previous := Time.get_ticks_usec()
				probe.draw_us = 0
				probe.draws = 0
				for frame in 280:
					if mode == "modern":
						for index in amount:
							var t := fposmod(frame / 60.0 + index * 0.13, 2.2)
							lanes[index].sample(t / 2.2, pow(t / 2.2, 2.2), t)
					await process_frame
					var now := Time.get_ticks_usec()
					if frame >= 80:
						samples.append(float(now - previous) / 1000.0)
						calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
					previous = now
				var total := 0.0
				for sample in samples: total += sample
				samples.sort()
				var row := {"size": str(size), "warnings": amount, "mode": mode, "frame_ms_mean": total / samples.size(), "frame_ms_p95": samples[floori(samples.size() * 0.95)], "draw_calls": calls / samples.size(), "draw_submit_ms": probe.draw_us / float(maxi(probe.draws, 1)) / 1000.0 if mode != "modern" else 0.0}
				results.append(row)
				print(JSON.stringify(row))
	var file := FileAccess.open("res://docs/warning_quality_measurements.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"adapter": RenderingServer.get_video_adapter_name(), "method": "Native Compatibility, VSync off; 80 warmup + 200 measured frames. Raster/analytic repeated in reverse order. Frame wall time including submission, not isolated GPU time or full-game/mobile FPS. Same 1280x720 logical viewport at both pixel resolutions. Modern is a separate all-lanes stress load, not an equivalent replacement benchmark.", "results": results}, "\t") + "\n")
	finish()
