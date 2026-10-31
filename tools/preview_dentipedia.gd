extends "res://tests/support/test_runtime.gd"
## Native reference pages, with session files isolated from the player's run.

const OUTPUT := "res://docs/screenshots/dentipedia_update/"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://dentipedia_preview_run.json"
	session.progression_path = "user://dentipedia_preview_progression.cfg"
	session.discovered_fusions.clear()
	session.reduced_ui_motion = true
	AudioServer.set_bus_mute(0, true)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	for extent in [Vector2i(1280, 720), Vector2i(320, 568), Vector2i(360, 640), Vector2i(568, 320)]:
		root.content_scale_size = extent
		root.size = extent
		var menu: GameMenu = load("res://scenes/ui/game_menu.tscn").instantiate()
		root.add_child(menu)
		current_scene = menu
		menu._show_dentipedia()
		for frame in 8: await process_frame
		var pedia := menu.dentipedia
		for page in [[0, "", "weapons"], [1, "", "items"], [4, "Manuelle Verzauberungsfusion", "fusion"], [4, "Wurzelsprung & Ausdauer", "dash"], [4, "Waffenpunkte & Effektplätze", "points"], [0, "Garotte", "weapon_forms"], [5, "Lebensraub", "leech"]]:
			pedia.select_category(page[0])
			pedia.search.text = page[1]
			pedia._refresh()
			if not str(page[1]).is_empty() and not pedia.selected.is_empty(): pedia._show(pedia.selected)
			for button: Button in pedia.listing.get_children():
				if str(button.get_meta("entry").title) == str(page[1]):
					button.pressed.emit()
					break
			if page[2] == "weapon_forms":
				for frame in 4: await process_frame
				var forms := pedia.detail.find_children("*", "HFlowContainer", false, false)
				var fire: Button = forms[0].get_child(1)
				for down in [true, false]:
					var click := InputEventMouseButton.new()
					click.position = fire.get_global_rect().get_center()
					click.button_index = MOUSE_BUTTON_LEFT
					click.pressed = down
					root.push_input(click, true)
			for frame in 12: await process_frame
			await RenderingServer.frame_post_draw
			var filename: String = "%s%s_%dx%d.png" % [OUTPUT, page[2], extent.x, extent.y]
			var error := root.get_texture().get_image().save_png(filename)
			if error != OK:
				push_error("Could not save Dentipedia preview: " + filename)
				finish(1)
				return
		menu.queue_free()
		await process_frame
	print("PASS native Dentipedia: visible categories, weapon/item lists, points, fusion, dash, fire forms and lifesteal; four viewports")
	finish()
