extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	var previous_motion: bool = session.reduced_ui_motion
	session.reduced_ui_motion = false
	var badge := HUDPendingLevels.new()
	root.add_child(badge)
	badge.show_count(0)
	_check(not badge.visible, "zero pending levels show a pill")
	badge.show_count(1)
	var single_width := badge.size.x
	_check(is_equal_approx(badge.flash_remaining, 0.3), "earned level has no 300ms cue")
	badge.advance(0.1)
	var elapsed := badge.flash_remaining
	badge.show_count(1)
	_check(is_equal_approx(badge.flash_remaining, elapsed), "normal HUD polling restarts the cue")
	badge.advance(0.21)
	_check(badge.flash_remaining == 0, "gain cue keeps looping")
	badge.show_count(5)
	badge.show_count(3)
	_check(badge.flash_remaining == 0, "consuming a reward triggers a gain cue")
	badge.show_count(100)
	_check(badge.size.x > single_width, "pill does not expand for a longer count")
	_check(badge.label.text == "99+" and badge.count == 100, "display cap modifies the real pending count")
	badge.show_count(101)
	_check(badge.flash_remaining > 0, "gains above the display cap lose their feedback")
	badge.show_count(0)
	_check(not badge.visible and badge.flash_remaining == 0, "empty queue leaves feedback behind")
	var restored := HUDPendingLevels.new()
	root.add_child(restored)
	restored.show_count(5)
	_check(restored.flash_remaining == 0, "initial saved count is treated as a new gain")
	badge.show_count(1)
	paused = true
	badge._process(0.1)
	_check(is_equal_approx(badge.flash_remaining, 0.3), "pause advances the combat cue")
	session.reduced_ui_motion = true
	badge._process(0.1)
	_check(badge.flash_remaining == 0, "reduced motion does not stop an active cue")
	badge.show_count(5)
	_check(badge.flash_remaining == 0, "reduced motion still animates gains")
	_check(badge.size.x < 40, "single-digit count retains unnecessary empty width")
	var geometry := badge.get_rect()
	badge.set_reward_focus(true)
	_check(badge.get_rect() == geometry and badge.scale == Vector2.ONE, "reward emphasis changes layout")
	paused = false
	session.reduced_ui_motion = previous_motion
	if failures.is_empty():
		print("Pending level pill: cap, gain-only feedback, pause and reduced motion passed")
	finish(0 if failures.is_empty() else 1)
