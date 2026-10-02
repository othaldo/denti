class_name DentiUIMotion
extends RefCounted

# UI feedback never owns progression or locks input. It also runs in pause menus.
static func enabled(control: Node) -> bool:
	var session := control.get_node_or_null("/root/GameSession")
	return session == null or not session.reduced_ui_motion


static func bind_button(button: BaseButton) -> void:
	if button.has_meta("denti_feedback"):
		return
	button.set_meta("denti_feedback", true)
	button.mouse_entered.connect(func() -> void:
		if not button.disabled:
			cue(button, false)
	)
	button.focus_entered.connect(func() -> void:
		if not button.disabled:
			cue(button, false)
	)
	button.pressed.connect(func() -> void:
		if button.disabled:
			return
		cue(button, true)
		pulse(button)
	)


static func cue(control: Node, clicked: bool) -> void:
	var session := control.get_node_or_null("/root/GameSession")
	if session != null:
		session.play_ui_cue(clicked)


static func pulse(control: Control) -> void:
	if not enabled(control) or not control.is_inside_tree():
		return
	_cancel(control)
	control.pivot_offset = control.size * 0.5
	control.scale = Vector2.ONE * 0.97
	var tween := control.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	control.set_meta("denti_tween", tween)
	tween.tween_property(control, "scale", Vector2.ONE, 0.16).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)
	control.add_to_group("denti_ui_motion")


static func reveal(control: Control) -> void:
	_cancel(control)
	control.modulate.a = 1.0
	if not enabled(control) or not control.is_inside_tree():
		return
	control.modulate.a = 0.55
	var tween := control.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS)
	control.set_meta("denti_tween", tween)
	tween.tween_property(control, "modulate:a", 1.0, 0.18)
	control.add_to_group("denti_ui_motion")


static func hover_art(control: Control, hovered: bool) -> void:
	_cancel(control)
	control.pivot_offset = control.size * 0.5
	if not enabled(control):
		control.scale = Vector2.ONE
		control.rotation = 0.0
		return
	var tween := control.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	control.set_meta("denti_tween", tween)
	tween.tween_property(control, "scale", Vector2.ONE * (1.055 if hovered else 1.0), 0.14)
	tween.tween_property(control, "rotation", -0.035 if hovered else 0.0, 0.14)
	control.add_to_group("denti_ui_motion")


static func reset(control: Control) -> void:
	_cancel(control)
	if control.has_meta("denti_flying"):
		control.queue_free()
		return
	control.scale = Vector2.ONE
	control.rotation = 0.0
	control.modulate.a = 1.0


static func fly(parent: Control, texture: Texture2D, from: Rect2, target: Rect2) -> void:
	if not enabled(parent) or texture == null:
		return
	var image := TextureRect.new()
	image.texture = texture
	image.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	image.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
	image.mouse_filter = Control.MOUSE_FILTER_IGNORE
	image.size = Vector2(64, 64)
	image.pivot_offset = image.size * 0.5
	image.position = from.get_center() - parent.global_position - image.size * 0.5
	parent.add_child(image)
	var destination := target.get_center() - parent.global_position - image.size * 0.5
	var tween := image.create_tween().set_pause_mode(Tween.TWEEN_PAUSE_PROCESS).set_parallel()
	image.set_meta("denti_tween", tween)
	image.set_meta("denti_flying", true)
	image.add_to_group("denti_ui_motion")
	tween.tween_property(image, "position", destination, 0.36).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(image, "scale", Vector2.ONE * 0.5, 0.36)
	tween.chain().tween_callback(image.queue_free)


static func _cancel(control: Control) -> void:
	if not control.has_meta("denti_tween"):
		return
	var previous: Tween = control.get_meta("denti_tween", null)
	if previous != null and previous.is_valid():
		previous.kill()
