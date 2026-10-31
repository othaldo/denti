extends "res://tests/support/test_runtime.gd"
var failures := 0
class Probe extends Node2D:
	var shape := 0
	var enabled := true
	var base := Transform2D.IDENTITY
	func _draw() -> void:
		if not enabled: return
		match shape:
			0: WarningEffects.circle(self, Vector2(256, 256), 100, 0.7, Color.WHITE, base)
			1: WarningEffects.ring(self, Vector2(256, 256), 60, 100, 0.7, false, false, base, Color.WHITE)
			2: WarningEffects.sector(self, Vector2(200, 256), Vector2.RIGHT, 150, 0.55, 0.7, false, false, base, Color.WHITE)
			3: WarningEffects.capsule(self, Vector2(100, 256), Vector2(350, 256), 36, Color.WHITE, 0.7, base)
			4: WarningEffects.rectangle(self, Rect2(160, 160, 160, 190), 0.7, Color.WHITE, base, WarningEffects.BATCH.Phase.WARNING, true)
			5: WarningEffects.timer(self, Vector2(256, 256), 100, 0.25, Color.WHITE, base)
			6: WarningEffects.sector(self, Vector2(256, 256), Vector2.RIGHT, 150, 2.1, 0.7, false, false, base, Color.WHITE)
func _initialize() -> void: call_deferred("_run")
func _check(value: bool, message: String) -> void:
	if not value: failures += 1; push_error(message)
func _image(view: SubViewport) -> Image:
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	return view.get_texture().get_image()
func _alpha(im: Image, at: Vector2) -> float:
	return im.get_pixelv(Vector2i(at.round())).a
func _run() -> void:
	if DisplayServer.get_name() == "headless": finish(1); return
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var view := SubViewport.new()
	view.size = Vector2i(512, 512)
	view.transparent_bg = true
	view.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	root.add_child(view)
	var probe := Probe.new()
	view.add_child(probe)
	for shape in 7:
		probe.shape = shape
		probe.queue_redraw()
		var im := await _image(view)
		match shape:
			0:
				_check(_alpha(im, Vector2(356, 256)) > 0.4 and _alpha(im, Vector2(375, 256)) == 0, "circle boundary drifted or leaked")
			1:
				_check(_alpha(im, Vector2(256, 256)) == 0 and _alpha(im, Vector2(296, 256)) == 0, "ring fills its safe core")
				for radius in [60, 100]:
					for axis in [Vector2.RIGHT, Vector2.LEFT, Vector2.UP, Vector2.DOWN]:
						_check(_alpha(im, Vector2(256, 256) + axis * radius) > 0.4, "ring contour misses a damage boundary")
			2:
				_check(_alpha(im, Vector2(350, 256)) > 0.4 and _alpha(im, Vector2(175, 256)) == 0, "sector reach/origin is wrong")
				for angle in [-0.55, 0.55]: _check(_alpha(im, Vector2(200, 256) + Vector2.from_angle(angle) * 90) > 0.4, "sector angle differs from collision")
			3:
				for point in [Vector2(64, 256), Vector2(386, 256), Vector2(220, 220), Vector2(220, 292)]: _check(_alpha(im, point) > 0.4, "capsule end or side misses its collision boundary")
				_check(_alpha(im, Vector2(40, 256)) == 0 and _alpha(im, Vector2(220, 310)) == 0, "capsule warning leaks outside collision")
			4:
				_check(_alpha(im, Vector2(160, 230)) > 0.4 and _alpha(im, Vector2(320, 230)) > 0.4 and _alpha(im, Vector2(140, 230)) == 0, "vertical rectangle changed footprint")
			5:
				_check(_alpha(im, Vector2(256, 156)) > 0.4 and _alpha(im, Vector2(356, 256)) > 0.4, "timer must start at top and run clockwise")
				_check(_alpha(im, Vector2(256, 256)) == 0 and _alpha(im, Vector2(256, 356)) == 0 and _alpha(im, Vector2(156, 256)) == 0, "timer paints a fictitious damage area")
			6:
				_check(_alpha(im, Vector2(176, 256)) == 0, "wide sector filled the safe wedge behind it")
				for angle in [-2.1, 2.1]: _check(_alpha(im, Vector2(256, 256) + Vector2.from_angle(angle) * 90) > 0.4, "wide sector boundary is wrong")
	probe.shape = 1
	probe.queue_redraw()
	var frozen := await _image(view)
	var again := await _image(view)
	_check(frozen.get_data() == again.get_data(), "frozen warning animates without a simulation clock")
	probe.enabled = false
	probe.queue_redraw()
	var blank := await _image(view)
	_check(blank.is_invisible(), "empty redraw leaves a stale warning visible")
	probe.enabled = true
	var transform := Transform2D(0.32, Vector2(0.8, 1.15), -0.1, Vector2(100, -80))
	probe.transform = transform
	probe.queue_redraw()
	var local := await _image(view)
	probe.transform = Transform2D.IDENTITY
	probe.base = transform
	probe.queue_redraw()
	var batched := await _image(view)
	var error := 0.0
	var maximum := 0.0
	for y in 512:
		for x in 512:
			var difference := absf(local.get_pixel(x, y).a - batched.get_pixel(x, y).a)
			error += difference
			maximum = maxf(maximum, difference)
	_check(error / (512 * 512) < 0.0001 and maximum < 0.04, "local/shared transforms differ in native pixels")
	view.free()
	if failures == 0: print("PASS native telegraphs: seven raster masks, safe cores, bounds, wide angles, timer direction, pause, clear and local/shared transforms")
	finish(0 if failures == 0 else 1)
