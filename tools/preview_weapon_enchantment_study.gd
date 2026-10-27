extends SceneTree
## Run with -- --interactive to explore the study; otherwise capture and verify it.

const STUDY := preload("res://tools/weapon_enchantment_study.gd")
const OUTPUT := "res://docs/screenshots/weapon_enchantment_study/"
var study: Control


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	# No gameplay scene is loaded and no run/progression store is read or written.
	AudioServer.set_bus_mute(0, true)
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	study = STUDY.new()
	root.add_child(study)
	current_scene = study
	if "--interactive" in OS.get_cmdline_user_args():
		study.completed.connect(func() -> void: quit(0))
		return
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	await _capture("overview_1280x720.png")
	# Exercise GUI hit testing: upgrading must affect this weapon alone.
	var before: Array = study.models.duplicate(true)
	await _click(study.upgrade_buttons[0])
	assert(study.models[0].effects[0].level == 5 and study.remaining == 2)
	for index in range(1, study.models.size()):
		assert(study.models[index] == before[index])
	await _capture("upgraded_1280x720.png")
	await _click(study.back_button)
	assert(study.models == before and study.remaining == 3)
	await _click(study.upgrade_buttons[2])
	await _click(study.effect_buttons[2]) # Gift: third existing catalogue entry.
	assert(study.selected_effect == &"poison")
	await _capture("picker_1280x720.png")
	await _click(study.finish_button)
	assert(study.models[0].effects.size() == 3)
	assert(study.models[0].effects[2] == {"id": &"poison", "level": 1})
	assert(study.remaining == 2)
	await _click(study.back_button)
	assert(study.models == before and study.remaining == 3)
	await _click(study.weapon_buttons[2])
	assert(study.upgrade_buttons[0].disabled) # Existing 10/10 effect.
	study.upgrade(0)
	assert(study.remaining == 3)
	study.select_weapon(0)
	await _settle()
	for count in 3:
		await _click(study.upgrade_buttons[0])
	assert(study.remaining == 0 and study.upgrade_buttons[0].disabled)
	assert(study.upgrade_buttons[2].disabled)
	study.upgrade(0)
	assert(study.remaining == 0)
	for count in 3:
		await _click(study.back_button)
	assert(study.models == before and study.remaining == 3)
	for extent in [Vector2i(1040, 600), Vector2i(360, 640), Vector2i(320, 568), Vector2i(568, 320), Vector2i(720, 1280)]:
		root.content_scale_size = extent
		root.size = extent
		DisplayServer.window_set_size(extent)
		await _capture("overview_%dx%d.png" % [extent.x, extent.y])
		assert(study.body.size.x <= study.stage.body_scroll.size.x + 1)
		var footer_bounds: Rect2 = study.stage.panel.get_global_rect()
		assert(footer_bounds.encloses(study.finish_button.get_global_rect()))
		assert(study.stage.body_scroll.get_h_scroll_bar().max_value <= study.stage.body_scroll.size.x + 1)
		if extent == Vector2i(360, 640):
			study.open_picker(2)
			await _settle()
			study.selected_effect = &"poison"
			study._refresh()
			await _capture("picker_360x640.png")
			study._back()
			await _settle()
	root.content_scale_size = Vector2i(1280, 720)
	root.size = Vector2i(1280, 720)
	DisplayServer.window_set_size(root.size)
	await _settle()
	# Six single-root weapons, including two identical kinds, keep distinct targets.
	study.models.assign([
		{"id": &"turbo_drill", "tier": 2, "effects": [{"id": &"bleed", "level": 3}]},
		{"id": &"turbo_drill", "tier": 2, "effects": [{"id": &"fire", "level": 2}]},
		{"id": &"enamel_mirror", "tier": 2, "effects": []},
		{"id": &"toothpick_spear", "tier": 2, "effects": []},
		{"id": &"plaque_scaler", "tier": 2, "effects": []},
		{"id": &"interdental_brush", "tier": 2, "effects": []},
	])
	study._refresh()
	await _capture("six_weapons_1280x720.png")
	await _click(study.weapon_buttons[1])
	await _click(study.upgrade_buttons[0])
	assert(study.models[0].effects[0].level == 3)
	assert(study.models[1].effects[0].level == 3 and study.remaining == 2)
	print("Enchantment study: native clicks, isolated weapon upgrades, activation at 1/10, undo, max rank, budget, six weapons and five responsive sizes passed.")
	study.queue_free()
	await process_frame
	await process_frame
	quit(0)


func _settle() -> void:
	for frame in 8: await process_frame


func _capture(filename: String) -> void:
	await _settle()
	_check_text_bounds(study.body)
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(OUTPUT + filename)


func _check_text_bounds(parent: Control) -> void:
	for child in parent.get_children():
		if child is Label:
			if not Rect2(Vector2.ZERO, parent.size).grow(1).encloses(child.get_rect()):
				push_error("Text outside its UI surface: " + child.text)
				quit(1)
				return
		if child is Control: _check_text_bounds(child)


func _click(button: Button) -> void:
	var center := button.get_global_rect().get_center()
	for down in [true, false]:
		var event := InputEventMouseButton.new()
		event.button_index = MOUSE_BUTTON_LEFT
		event.position = center
		event.pressed = down
		root.push_input(event, true)
		await process_frame
	await _settle()
