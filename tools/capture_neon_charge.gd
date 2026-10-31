extends "res://tests/support/test_runtime.gd"
## Native renderer capture of the isolated study, with deterministic animation.

const OUTPUT := "res://.godot/neon_charge_preview"
const SCENE := preload("res://scenes/dev/neon_charge_preview.tscn")

func _initialize() -> void: call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(0, true)
	var study: Node2D = SCENE.instantiate()
	root.add_child(study)
	current_scene = study
	study.set_process(false)
	# Exercise the preview controls before producing an animation for review.
	study.seek(0.2)
	study._set_stopped(true)
	study._process(0.25)
	assert(is_equal_approx(study.clock_seconds, 0.2), "Pause did not freeze the preview clock")
	study._set_stopped(false)
	study.slow = true
	study._process(0.4)
	assert(is_equal_approx(study.clock_seconds, 0.34), "Slow motion did not slow the same clock")
	study.slider.value = 0.5
	assert(study.stopped and is_equal_approx(study.progress, 0.5), "Scrubbing did not pause at the selected charge")
	study.slow = false
	study._set_stopped(false)
	# Easing only moves the fill front; the shared release deadline stays fixed.
	for mode in 3:
		study.curve_picker.select(mode)
		study.curve_picker.item_selected.emit(mode)
		var previous := 0.0
		for tick in 101:
			var fraction := float(tick) / 100
			var fill: float = study.fill_fraction(fraction, mode, study.strength)
			assert(fill >= previous and fill >= 0 and fill <= 1, "Easing must fill monotonically")
			previous = fill
		assert(is_equal_approx(previous, 1.0), "Easing must finish at the release deadline")
		study.seek(study.warning_seconds - 0.001)
		assert(is_equal_approx(study.enemies[0].position.x, study.enemies[1].position.x))
		assert(study.lanes[1].effect.get_shader_parameter("release_flash") == 0.0)
		study.seek(study.warning_seconds)
		assert(study.lanes[1].effect.get_shader_parameter("release_flash") == 1.0)
		study.seek(study.warning_seconds + 0.1)
		assert(is_equal_approx(study.enemies[0].position.x, study.enemies[1].position.x))
	study.curve_picker.select(1)
	study.curve_picker.item_selected.emit(1)
	study.strength_control.value = 3.0
	assert(is_equal_approx(study.fill_fraction(0.5, study.curve, study.strength), 0.125))
	study.strength_control.value = 2.2
	study.duration_control.value = 1.4
	assert(is_equal_approx(study.warning_seconds, 1.4) and is_zero_approx(study.clock_seconds))
	study.duration_control.value = 2.2
	study.seek(study.warning_seconds * 0.9)
	var pose: Transform2D = study.enemies[1].sprite.transform
	study._set_stopped(true)
	study._process(0.5)
	assert(study.enemies[1].sprite.transform.is_equal_approx(pose), "Paused actor pose kept moving")
	study._set_stopped(false)
	study.seek(study.warning_seconds + study.CHARGE_SECONDS + 0.4)
	assert(not study.lanes[1].visible, "Finished wake still submits an invisible full lane")
	study.seek(0)
	assert(study.lanes[1].visible and study.enemies[1].sprite.scale.is_equal_approx(study.enemies[1].base_scale), "New warning did not reset its pose/effect")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.path_join("frames")))
	for frame in 8: await process_frame
	for sample in [["early", 0.15], ["middle", 0.50], ["late", 0.85], ["release", 1.02]]:
		study.seek(study.warning_seconds * sample[1])
		await _capture(OUTPUT.path_join(sample[0] + ".png"))
	study.seek(study.warning_seconds + 0.25)
	await _capture(OUTPUT.path_join("moving.png"))
	study.seek(study.warning_seconds + study.CHARGE_SECONDS + 0.08)
	await _capture(OUTPUT.path_join("settle.png"))
	study.curve_picker.select(2)
	study.curve_picker.item_selected.emit(2)
	study.seek(study.warning_seconds * 0.70)
	await _capture(OUTPUT.path_join("smooth.png"))
	study.curve_picker.select(1)
	study.curve_picker.item_selected.emit(1)
	if not "--stills-only" in OS.get_cmdline_user_args():
		for frame in ceili(study.period() * 30):
			study.seek(float(frame) / 30)
			await _capture(OUTPUT.path_join("frames/%03d.png" % frame))
	print("Native neon charge preview -> ", OUTPUT)
	finish()

func _capture(path: String) -> void:
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
