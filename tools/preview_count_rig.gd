extends "res://tests/support/test_runtime.gd"
## Native rig workbench; --capture saves stills, --animate also records one loop.

const OUTPUT := "res://.godot/count_rig_preview"
var rigs: Array[CountCloakRig] = []
var stage: Node2D
var slider: HSlider
var playing := true

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	root.get_node("SceneTransitions").enabled = false
	AudioServer.set_bus_mute(AudioServer.get_bus_index(&"Master"), true)
	root.content_scale_size = Vector2i(1024, 720)
	root.size = root.content_scale_size
	DisplayServer.window_set_size(root.size)
	stage = Node2D.new()
	root.add_child(stage)
	current_scene = stage
	var background := ColorRect.new()
	background.color = Color("241c2d")
	background.size = Vector2(1024, 720)
	stage.add_child(background)
	_label("Graf C · Knochenanimation", Vector2(30, 20), 28, Color("f8eedc"))
	_label("Körper und Gesicht bleiben formstabil. Der Stoff folgt über eigene Gelenke.", Vector2(32, 61), 16, Color("d6c3d9"))
	for index in 2:
		var panel := ColorRect.new()
		panel.color = Color("b4afa9")
		panel.position = Vector2(24 + index * 500, 110)
		panel.size = Vector2(476, 407)
		stage.add_child(panel)
		var rig: CountCloakRig = load("res://scenes/enemies/count_cloak_rig.tscn").instantiate()
		rig.position = Vector2(260 + index * 500, 480)
		rig.scale = Vector2.ONE * 2.25
		stage.add_child(rig)
		rig.debug_bones = index == 1
		rigs.append(rig)
	_label("BEWEGUNG", Vector2(40, 122), 14, Color("35263a"))
	_label("SKELETT + STOFFNETZ", Vector2(540, 122), 14, Color("35263a"))
	var small: CountCloakRig = load("res://scenes/enemies/count_cloak_rig.tscn").instantiate()
	small.position = Vector2(160, 665)
	small.scale = Vector2.ONE * 0.78
	stage.add_child(small)
	rigs.append(small)
	_label("Spielmaßstab", Vector2(280, 590), 17, Color("f8eedc"))
	_label("Ein Rig · keine wechselnden Ganzkörperbilder", Vector2(280, 620), 15, Color("d6c3d9"))
	var button := Button.new()
	button.text = "Anhalten"
	button.position = Vector2(715, 550)
	button.size = Vector2(130, 42)
	stage.add_child(button)
	button.pressed.connect(func():
		playing = not playing
		button.text = "Anhalten" if playing else "Abspielen"
		for rig in rigs:
			if playing: rig.animator.play()
			else: rig.animator.pause()
	)
	slider = HSlider.new()
	slider.position = Vector2(715, 615)
	slider.size = Vector2(285, 32)
	slider.max_value = CountRigMotion.DURATION
	slider.step = 0.01
	stage.add_child(slider)
	slider.value_changed.connect(func(value: float):
		playing = false
		button.text = "Abspielen"
		for rig in rigs: rig.sample(value)
	)
	var debug_button := CheckButton.new()
	debug_button.text = "Knochen rechts"
	debug_button.button_pressed = true
	debug_button.position = Vector2(850, 550)
	stage.add_child(debug_button)
	debug_button.toggled.connect(func(enabled: bool): rigs[1].debug_bones = enabled)
	for rig in rigs: rig.play_combo()
	if "--capture" not in OS.get_cmdline_user_args() and "--animate" not in OS.get_cmdline_user_args():
		return
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT))
	for pose in [["rest", 0.0], ["open", 0.98], ["left", 1.12], ["right", 2.02]]:
		for rig in rigs: rig.sample(float(pose[1]))
		await _capture(OUTPUT.path_join(String(pose[0]) + ".png"))
	if "--animate" in OS.get_cmdline_user_args():
		DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(OUTPUT.path_join("frames")))
		for frame in 102:
			for rig in rigs: rig.sample(float(frame) / 30.0)
			await _capture(OUTPUT.path_join("frames/%03d.png" % frame))
	finish()

func _label(text: String, at: Vector2, font_size: int, color: Color) -> void:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", color)
	stage.add_child(label)

func _capture(path: String) -> void:
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(path)
