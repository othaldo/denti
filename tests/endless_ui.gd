extends "res://tests/support/test_runtime.gd"

func _initialize() -> void:
	call_deferred("_run")

func _run() -> void:
	var panel: ChoicePanel = load("res://scenes/ui/choice_panel.tscn").instantiate()
	root.add_child(panel)
	root.get_node("GameSession").reduced_ui_motion = true
	var recap := {"wave_reached": 20, "final_level": 40, "difficulty_id": "normal", "base_victory": true, "endless_enabled": false, "telemetry": {"elapsed": 1100, "kills": 2000, "coins_collected": 1500, "total_damage": 1000000, "weapon_damage": {"magic_toothbrush": 1000000}}}
	recap.weapon_mastery = {"starter_id": "turbo_drill", "earned": ["exam", "bronze", "silver"], "unlocks": ["cavity_grinder", "interdental_brush"]}
	recap.new_fusion_discoveries = ["root_breaker"]
	var notices := panel.end_notices
	for extent in [Vector2i(320, 568), Vector2i(360, 640), Vector2i(568, 320), Vector2i(640, 360), Vector2i(600, 600), Vector2i(800, 600), Vector2i(1280, 720), Vector2i(1920, 1080)]:
		root.content_scale_size = extent
		root.size = extent
		for frame in 4:
			await process_frame
		for state in [0, 1, 2]:
			recap.endless_enabled = state == 1
			recap.base_victory = state != 2
			recap.wave_reached = 40 if state == 1 else 20
			recap.hell_unlocked_now = state == 0
			recap.weapon_mastery.earned = ["exam"] if state == 2 else ["exam", "bronze", "silver"]
			panel.show_end(state == 0, 1000, recap)
			for frame in 5:
				await process_frame
			if panel.buttons[3].visible != (state == 0) or panel.level_actions.visible:
				_fail("endless continuation offered in the wrong outcome")
				return
			var primary := panel.buttons[3 if state == 0 else 0]
			if not primary.has_focus() or primary.get_theme_stylebox("normal").bg_color != DentiUIStyle.GOLD:
				_fail("run result does not focus its primary action")
				return
			if panel.subtitle_label.text.contains("freigeschaltet") or panel.subtitle_label.text.contains("Neu:"):
				_fail("run statistics repeat the rewards from the notices")
				return
			var bounds := Rect2(Vector2.ZERO, Vector2(extent))
			var dialog := panel.dialog_panel.get_global_rect()
			if not bounds.encloses(dialog):
				_fail("endless end dialog exceeds %s: %s" % [extent, dialog])
				return
			var notice_bounds := notices.get_global_rect()
			if notices.notices.get_child_count() != [7, 1, 4][state] or not bounds.encloses(notice_bounds) or dialog.intersects(notice_bounds):
				_fail("end notices missed a reward or overlap the dialog at %s: %s" % [extent, notice_bounds])
				return
			for label: Label in notices.notices.find_children("*", "Label", true, false):
				var text_width := label.get_theme_font("font").get_string_size(label.text, HORIZONTAL_ALIGNMENT_LEFT, -1, label.get_theme_font_size("font_size")).x
				if text_width > label.size.x:
					_fail("end notice text clipped at %s: %s" % [extent, label.text])
					return
			if notices.get_v_scroll_bar().visible:
				var last := notices.notices.get_child(-1) as Control
				last.grab_focus()
				await process_frame
				await process_frame
				if not last.has_focus() or not notice_bounds.encloses(last.get_global_rect()):
					_fail("focus did not reveal the last end notice at %s" % extent)
					return
			for control in [panel.title_label, panel.subtitle_label] + panel.buttons:
				if control.visible and (not dialog.encloses(control.get_global_rect()) or control.size.y < control.get_minimum_size().y):
					_fail("endless end content clipped at %s" % extent)
					return
	var previous := notices.notices.get_child(0)
	panel._show_credits()
	if notices.visible:
		_fail("end notices covered the credits")
		return
	panel._on_choice_pressed(0)
	if not notices.visible or notices.notices.get_child(0) != previous:
		_fail("return from credits replayed the end notices")
		return
	panel.show_end(false, 0)
	if notices.visible or notices.has_entries():
		_fail("end notices remained after a run without rewards")
		return
	root.get_node("GameSession").reduced_ui_motion = false
	paused = true
	panel.show_end(false, 1000, recap)
	for frame in 5: await process_frame
	if notices.notices.get_child(0).modulate.a <= 0 or notices.notices.get_child(-1).modulate.a != 0:
		_fail("paused result did not stagger the end notices")
		return
	for frame in 40: await process_frame
	if notices.notices.get_child(-1).modulate.a != 1:
		_fail("last end notice did not finish its entrance while paused")
		return
	panel.free()
	print("Denti endless UI test passed")
	finish(0)

func _fail(message: String) -> void:
	push_error(message)
	finish(1)
