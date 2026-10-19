extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _shield_distance(point: Vector2) -> float:
	var image := HUDShieldAura.DISTANCE.get_image()
	var pixel := Vector2i((point + Vector2.ONE * 0.25) * Vector2(image.get_size()) / 1.5)
	var packed := image.get_pixelv(pixel)
	return ((packed.r * 256.0 + packed.g) / 257.0 - 0.5) * 0.5

func _run() -> void:
	_check(_shield_distance(Vector2(0.5, 0.4)) < 0, "smooth shield distance data leaves a hole in the crown")
	_check(_shield_distance(Vector2(0.0, 0.0)) > 0 and _shield_distance(Vector2(0.5, 0.95)) > 0, "smooth shield distance data fills the background or root notch")
	var vessel := HUDToothVessel.new()
	root.add_child(vessel)
	vessel.set_process(false)
	vessel.size = Vector2(120, 140)
	vessel.show_value(100, 100, "100 / 100")
	_check(vessel.displayed_ratio == 1 and vessel.trailing_ratio == 1, "full health did not initialize fully filled")
	var rect := vessel.glass.get_rect()
	_check(rect.size.x == rect.size.y, "square tooth source is distorted by unequal horizontal and vertical scale")
	vessel.set_compact(true)
	_check(vessel.glass.size.x == vessel.glass.size.y, "compact tooth distorts source proportions")
	vessel.set_compact(false)
	vessel.show_value(35, 100, "35 / 100")
	_check(vessel.value == 35 and vessel.label.text == "35" and vessel.maximum_label.text == "/ 100", "animation delayed authoritative life information")
	_check(vessel.glass.get_rect().encloses(vessel.label.get_rect()) and vessel.glass.get_rect().encloses(vessel.maximum_label.get_rect()), "life numbers are outside the tooth crown")
	_check(vessel.label.get_theme_font_size("font_size") == 18 and vessel.maximum_label.get_theme_font_size("font_size") >= 12, "life number hierarchy is missing")
	vessel.advance(0.05)
	_check(vessel.displayed_ratio < 1 and vessel.displayed_ratio > 0.35 and vessel.trailing_ratio > vessel.displayed_ratio, "damage lacks a short animated drop and delayed trace")
	for frame in 180:
		vessel.advance(1.0 / 60.0)
	_check(absf(vessel.displayed_ratio - 0.35) < 0.001 and absf(vessel.trailing_ratio - 0.35) < 0.001, "liquid did not converge to actual life")
	_check(vessel.glass.get_rect() == rect, "damage changed vessel geometry")
	vessel.show_shield(1)
	_check(vessel.shield_aura.visible and vessel.shield_aura.charges == 1 and vessel.displayed_ratio < 0.36, "shield shell changed health or did not cover one charge")
	vessel.show_shield(5)
	_check(vessel.shield_aura.charges == 5 and vessel.glass.get_rect() == rect, "shield reserves distort the tooth itself")
	paused = true
	var before := vessel.phase
	vessel._process(1.0)
	_check(vessel.phase == before, "paused combat continued liquid animation")
	var session: Node = root.get_node("GameSession")
	session.reduced_ui_motion = true
	vessel.show_value(80, 100, "80 / 100")
	vessel._process(0.1)
	_check(vessel.phase == before and vessel.displayed_ratio == 0.8 and vessel.trailing_ratio == 0.8 and vessel.liquid.get_shader_parameter("motion") == 0.0, "reduced motion did not disable waves, bubbles and interpolation")
	_check(vessel.shield_aura.veil.get_shader_parameter("motion") == 0.0, "shield shimmer ignores reduced motion")
	session.reduced_ui_motion = false
	paused = false
	vessel._process(0.1)
	_check(vessel.phase > before and vessel.liquid.get_shader_parameter("motion") == 1.0, "animation did not resume")
	vessel.show_value(-5, 100, "0 / 100")
	for frame in 180:
		vessel.advance(1.0 / 60.0)
	_check(vessel.displayed_ratio < 0.0001 and vessel.displayed_ratio >= 0, "empty vessel has an invalid fill")
	var second := HUDToothVessel.new()
	root.add_child(second)
	second.show_value(50, 100, "50 / 100")
	_check(second.liquid != vessel.liquid and second.displayed_ratio == 0.5, "two vessels share mutable animation state")
	_check(second.shield_aura.charges == 0 and not second.shield_aura.visible, "shield preview leaks between tooth instances")
	var stamina := HUDToothVessel.new(DashButton.FRAME_PATH)
	root.add_child(stamina)
	stamina.show_value(40, 100, "40 / 100")
	_check(stamina.glass.texture.resource_path == DashButton.FRAME_PATH and second.glass.texture.resource_path == HUDToothVessel.FRAME_PATH, "stamina artwork replaced the health vessel")
	_check(stamina._outline != second._outline and stamina.displayed_ratio == 0.4, "resource frame caches share the wrong contour or fill")
	vessel.show_shield(0)
	_check(not vessel.shield_aura.visible, "last consumed shield leaves an aura behind")
	_check(vessel.mouse_filter == Control.MOUSE_FILTER_IGNORE and vessel.label.mouse_filter == Control.MOUSE_FILTER_IGNORE, "vessel intercepts movement")
	if failures.is_empty():
		print("Tooth vessel damage, healing, animation, pause and reduced motion passed")
	finish(0 if failures.is_empty() else 1)
