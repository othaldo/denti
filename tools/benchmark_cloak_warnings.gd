extends SceneTree
## Native renderer only. Compare the preceding ring path to prepared quads.

class Probe extends Node2D:
	var amount := 1
	var atlas := false
	var total_us := 0
	var frames := 0
	func _process(_delta: float) -> void: queue_redraw()
	func _draw() -> void:
		var start := Time.get_ticks_usec()
		for index in amount:
			draw_set_transform(Vector2(70 + index % 10 * 120, 65 + index / 10 * 110), 0, Vector2.ONE * 0.14)
			if atlas:
				WarningEffects.ring(self, Vector2.ZERO, 130, 290, 0.5, false, false)
			else:
				# Exact command structure of the previous CloakStrikeArea ring.
				for segment in 64:
					var a := Vector2.RIGHT.rotated(TAU * segment / 64.0)
					var b := Vector2.RIGHT.rotated(TAU * (segment + 1) / 64.0)
					draw_colored_polygon(PackedVector2Array([a * 130, a * 290, b * 290, b * 130]), Color(0.85, 0.24, 0.14, 0.16))
				draw_arc(Vector2.ZERO, 130, 0, TAU, 96, Color(1, 0.63, 0.19, 0.95), 3, true)
				draw_arc(Vector2.ZERO, 290, 0, TAU, 128, Color(1, 0.63, 0.19, 0.95), 3, true)
				draw_arc(Vector2.ZERO, 122, -PI / 2, PI / 2, 96, Color(1, 0.9, 0.65, 0.9), 3, true)
		draw_set_transform_matrix(Transform2D.IDENTITY)
		total_us += Time.get_ticks_usec() - start
		frames += 1

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	if DisplayServer.get_name() == "headless":
		push_error("Use native rendering for this comparison")
		quit(1)
		return
	DisplayServer.window_set_vsync_mode(DisplayServer.VSYNC_DISABLED)
	Engine.max_fps = 0
	var probe := Probe.new()
	root.add_child(probe)
	var results: Array[Dictionary] = []
	for amount in ([1, 2, 60] if "--stress" in OS.get_cmdline_user_args() else [1, 2]):
		probe.amount = amount
		for atlas in [false, true, false, true]:
			probe.atlas = atlas
			for frame in 40: await process_frame
			probe.total_us = 0
			probe.frames = 0
			var start := Time.get_ticks_usec()
			for frame in 300: await process_frame
			var row := {"rings": amount, "atlas": atlas, "frame_ms": snappedf((Time.get_ticks_usec() - start) / 300000.0, 0.001), "draw_ms": snappedf(probe.total_us / float(maxi(probe.frames, 1)) / 1000.0, 0.001), "draw_calls": Performance.get_monitor(Performance.RENDER_TOTAL_DRAW_CALLS_IN_FRAME)}
			results.append(row)
			print(JSON.stringify(row))
	var file := FileAccess.open("res://docs/warning_ring_measurements.json", FileAccess.WRITE)
	file.store_string(JSON.stringify({"method": "Native Compatibility, VSync off, RTX 4070, 40 warmup + 300 samples each, alternating twice. Previous procedural ring versus new atlas style. Isolated rendering, not full-game/mobile FPS.", "results": results}, "\t") + "\n")
	probe.free()
	quit()
