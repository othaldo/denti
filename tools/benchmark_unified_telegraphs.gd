extends "res://tests/support/test_runtime.gd"
const LEGACY := preload("res://tools/support/legacy_warning_effects.gd")
class Probe extends Node2D:
	var amount := 20
	var unified := false
	var clock := 0.0
	var submit_us := 0
	var submissions := 0
	func _process(_delta: float) -> void:
		clock += 1.0 / 60.0
		queue_redraw()
	func _draw() -> void:
		var begin := Time.get_ticks_usec()
		for index in amount:
			var at := Vector2(180 + index % 8 * 120, 150 + (index / 8) % 4 * 115)
			var progress := 0.15 + fposmod(clock * 0.22 + index * 0.137, 0.83)
			var color := Color(1, 0.4, 0.23, 0.75)
			match index % 5:
				0:
					var end := at + Vector2.from_angle(index * 0.31) * 420
					if unified: WarningEffects.charge(self, Vector2.ZERO, end - at, 45, 380, color, progress, Transform2D(0, at))
					else: LEGACY.charge(self, Vector2.ZERO, end - at, 45, 380, color, progress, Transform2D(0, at))
				1:
					if unified: WarningEffects.ring(self, at, 130.0 / 290.0 * 185, 185, progress, false, false)
					else: LEGACY.ring(self, at, 130.0 / 290.0 * 185, 185, progress, false, false)
				2:
					if unified: WarningEffects.sector(self, at, Vector2.from_angle(index * 0.7), 240, deg_to_rad(40), progress, false, false)
					else: LEGACY.sector(self, at, Vector2.from_angle(index * 0.7), 240, deg_to_rad(40), progress, false, false)
				3:
					if unified: WarningEffects.timer(self, at, 100, progress, color)
					else: LEGACY.timer(self, at, 100, progress, color)
				4:
					if unified: WarningEffects.lane(self, at - Vector2(120, 0), at + Vector2(220, 80), 28, color, progress)
					else: LEGACY.lane(self, at - Vector2(120, 0), at + Vector2(220, 80), 28, color, progress, Transform2D.IDENTITY, PackedFloat32Array())
		submit_us += Time.get_ticks_usec() - begin
		submissions += 1
func _initialize() -> void: call_deferred("_run")
func _run() -> void:
	if DisplayServer.get_name() == "headless": finish(1); return
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	root.content_scale_size = Vector2i(1280, 720)
	var floor := DentiArena.new()
	floor.z_index = -100
	root.add_child(floor)
	var old := Probe.new()
	var modern := Probe.new()
	modern.unified = true
	root.add_child(old)
	root.add_child(modern)
	var results: Array[Dictionary] = []
	for size in [Vector2i(1280, 720), Vector2i(2560, 1440)]:
		root.size = size
		for amount in [1, 20, 60]:
			old.amount = amount
			modern.amount = amount
			for mode in ["atlas", "unified", "unified", "atlas"]:
				old.visible = mode == "atlas"
				modern.visible = mode == "unified"
				old.set_process(old.visible)
				modern.set_process(modern.visible)
				var probe := modern if modern.visible else old
				probe.submit_us = 0
				probe.submissions = 0
				var samples: Array[float] = []
				var draw_calls := 0.0
				var previous := Time.get_ticks_usec()
				for frame in 280:
					await process_frame
					var now := Time.get_ticks_usec()
					if frame >= 80:
						samples.append((now - previous) / 1000.0)
						draw_calls += Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)
					previous = now
				var mean := 0.0
				for sample in samples: mean += sample
				samples.sort()
				var row := {"size": str(size), "warnings": amount, "mode": mode, "frame_ms_mean": mean / samples.size(), "frame_ms_p95": samples[floori(samples.size() * 0.95)], "draw_calls": draw_calls / samples.size(), "submit_ms_mean": probe.submit_us / float(maxi(probe.submissions, 1)) / 1000}
				results.append(row)
				print(JSON.stringify(row))
	var file := FileAccess.open("res://docs/unified_telegraph_measurements.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"adapter": RenderingServer.get_video_adapter_name(), "method": "Native Compatibility, VSync off, 1280x720 logical area. Same mixed charge/ring/sector/timer/lane fixtures. Previous atlas renderer includes the earlier analytic timer/charge masks. 80 warmup + 200 sample frames, atlas/unified/unified/atlas. Wall frame time and complete isolated scene calls; not isolated GPU or full-game/browser/mobile FPS.", "results": results}, "	") + "
")
	finish()
