class_name DashButton
extends Button

const FRAME_PATH := "res://assets/ui/stamina_vessel_frame.png"
var player: Player:
	set(value):
		player = value
		if is_instance_valid(vessel): refresh()
var touch_mode := false
var vessel: HUDToothVessel
var caption: Label

func _init() -> void:
	custom_minimum_size = Vector2(80, 80)
	focus_mode = Control.FOCUS_NONE
	action_mode = BaseButton.ACTION_MODE_BUTTON_PRESS
	# The generated vessel is the visible control. No stock button/arc is drawn.
	for state in ["normal", "hover", "pressed", "disabled", "focus"]:
		add_theme_stylebox_override(state, StyleBoxEmpty.new())
	vessel = HUDToothVessel.new(FRAME_PATH)
	vessel.liquid.set_shader_parameter("liquid_dark", Vector3(0.015, 0.20, 0.25))
	vessel.liquid.set_shader_parameter("liquid_light", Vector3(0.12, 0.88, 0.76))
	vessel.liquid.set_shader_parameter("shimmer_tint", Vector3(0.035, 0.16, 0.16))
	vessel.liquid.set_shader_parameter("surface_tint", Vector3(0.30, 0.65, 0.48))
	vessel.liquid.set_shader_parameter("bubble_tint", Vector3(0.14, 0.38, 0.32))
	vessel.liquid.set_shader_parameter("trail_tint", Vector3(0.04, 0.35, 0.31))
	add_child(vessel)
	caption = vessel.maximum_label
	resized.connect(_layout)
	pressed.connect(func() -> void:
		if is_instance_valid(player): player.try_dash())

func _layout() -> void:
	var side := minf(size.x, size.y)
	vessel.position = Vector2((size.x - side) * 0.5, 0)
	vessel.size = Vector2(side, side)
	vessel.artwork_size = side
	vessel.set_compact(side < 108)

func _process(_delta: float) -> void:
	refresh()

func refresh() -> void:
	if not is_instance_valid(player) or not is_instance_valid(player.stats): return
	var dash := player.dash
	var full := dash.charge >= dash.capacity - 0.00001
	vessel.show_value(dash.charge, dash.capacity, "%d / %d" % [roundi(dash.capacity) if full else floori(dash.charge), roundi(dash.capacity)])
	# Spending stamina updates immediately; continuous refill supplies the
	# animation. Keep health-only damage lag/flash out of the stamina vessel.
	vessel.displayed_ratio = dash.charge / dash.capacity
	vessel.trailing_ratio = vessel.displayed_ratio
	vessel.impact = 0.0
	vessel._upload()
	caption.text = "%.1f s" % dash.cooldown if dash.charge >= dash.config.cost and dash.cooldown > 0 else "/ %d" % roundi(dash.capacity)
	tooltip_text = "Wurzelkraft · Wurzelsprung (%s)\n%d / %d · %d pro Dash · %.2f/s · voll in %.0f s\n%.1f s Cooldown · Freier Weg nötig. Du bleibst verwundbar." % ["Tippen" if touch_mode else "Shift", roundi(dash.charge), roundi(dash.capacity), roundi(dash.config.cost), dash.config.recharge_per_second(dash.capacity), dash.config.refill_duration, dash.cooldown]
