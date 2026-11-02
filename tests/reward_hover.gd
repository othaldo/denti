extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []


func _initialize() -> void:
	_run.call_deferred()


func _check(value: bool, message: String) -> void:
	if not value:
		failures.append(message)
		push_error(message)


func _settle() -> void:
	for frame in 12:
		await process_frame


func _pointer(position: Vector2) -> void:
	var event := InputEventMouseMotion.new()
	event.position = position
	event.relative = Vector2(20, 20)
	root.push_input(event, true)
	await _settle()


func _keyboard() -> void:
	for down in [true, false]:
		var event := InputEventKey.new()
		event.keycode = KEY_RIGHT
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await _settle()


func _capture(name: String) -> void:
	if not "--capture" in OS.get_cmdline_user_args():
		return
	await RenderingServer.frame_post_draw
	var directory := ProjectSettings.globalize_path("res://.godot/reward-hover")
	DirAccess.make_dir_recursive_absolute(directory)
	root.get_texture().get_image().save_png(directory.path_join(name + ".png"))


func _run() -> void:
	var session := root.get_node("GameSession")
	session.reduced_ui_motion = true
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1280, 720)
	root.content_scale_size = root.size
	var panel: ChoicePanel = load("res://scenes/ui/choice_panel.tscn").instantiate()
	root.add_child(panel)
	current_scene = panel
	var upgrades: Array[UpgradeData] = []
	for tier in range(1, 5):
		upgrades.append(load("res://data/upgrades/bisskraft.tres").with_tier(tier))
	panel.show_upgrades(upgrades)
	await _pointer(Vector2(2, 2))
	var expected: Array[StyleBoxFlat] = []
	for card in panel.buttons:
		expected.append(card.get_theme_stylebox("hover").duplicate() as StyleBoxFlat)
	await _pointer(panel.buttons[2].get_global_rect().get_center())
	await _capture("fresh_hover")
	for cycle in 2:
		# Reuse the same cards for another reward, then reroll with keyboard focus.
		var previous: Array[UpgradeData] = []
		for tier in [4, 3, 1, 2]:
			previous.append(upgrades[tier - 1])
		panel.show_upgrades(previous)
		await _keyboard()
		panel.show_upgrades(upgrades)
		await _settle()
		panel.stage.refresh_focus()
		_check(root.get_node("GameInput").navigation_active, "keyboard did not enable reward navigation")
		for card in panel.buttons:
			_check(card.get_theme_stylebox("hover") == card.get_theme_stylebox("normal"), "parked pointer highlights a second keyboard choice")
		for index in panel.buttons.size():
			var card := panel.buttons[index]
			await _pointer(card.get_global_rect().get_center())
			var hover := card.get_theme_stylebox("hover") as StyleBoxFlat
			_check(card.is_hovered(), "mouse did not reach reward card %d" % index)
			_check(hover.bg_color.is_equal_approx(expected[index].bg_color) and hover.border_color.is_equal_approx(expected[index].border_color), "reward hover kept an old rarity in cycle %d, tier %d" % [cycle, index + 1])
			_check(card.rarity_label.text == DentiRarity.name_for(index + 1), "reward rarity caption changed on hover")
			if cycle == 1 and index == 2:
				await _capture("reused_hover")
	if failures.is_empty():
		print("Reward hover preserves all rarities after rerolls and repeated keyboard/mouse switches")
	finish(0 if failures.is_empty() else 1)
