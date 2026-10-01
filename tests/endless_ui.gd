extends SceneTree

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: ChoicePanel = load("res://scenes/ui/choice_panel.tscn").instantiate()
	root.add_child(panel)
	var recap := {"wave_reached": 20, "final_level": 40, "difficulty_id": "normal", "base_victory": true, "endless_enabled": false, "telemetry": {"elapsed": 1100, "kills": 2000, "coins_collected": 1500, "total_damage": 1000000, "weapon_damage": {"magic_toothbrush": 1000000}}}
	for extent in [Vector2i(320, 568), Vector2i(360, 640), Vector2i(568, 320), Vector2i(640, 360), Vector2i(800, 600), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		for frame in 4:
			await process_frame
		for state in [0, 1, 2]:
			recap.endless_enabled = state == 1
			recap.base_victory = state != 2
			recap.wave_reached = 40 if state == 1 else 20
			panel.show_end(state == 0, 1000, recap)
			for frame in 5:
				await process_frame
			if panel.buttons[3].visible != (state == 0) or panel.level_actions.visible:
				_fail("endless continuation offered in the wrong outcome")
				return
			var bounds := Rect2(Vector2.ZERO, Vector2(extent))
			var dialog := panel.dialog_panel.get_global_rect()
			if not bounds.encloses(dialog):
				_fail("endless end dialog exceeds %s: %s" % [extent, dialog])
				return
			for control in [panel.title_label, panel.subtitle_label] + panel.buttons:
				if control.visible and (not dialog.encloses(control.get_global_rect()) or control.size.y < control.get_minimum_size().y):
					_fail("endless end content clipped at %s" % extent)
					return
	panel.free()
	print("Denti endless UI test passed")
	quit(0)

func _fail(message: String) -> void:
	push_error(message)
	quit(1)
