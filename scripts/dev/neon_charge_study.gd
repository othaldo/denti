extends Node2D
## Standalone art prototype. No combat scene, collision, global option or run save.

const LANE := preload("res://scripts/vfx/neon_charge_preview_lane.gd")
const ACTOR := preload("res://scripts/vfx/charge_study_actor.gd")
const DENTI := preload("res://assets/denti/denti_unarmed.png")
const STUDY_SIZE := Vector2i(1120, 800)
const START_X := 220.0
const LENGTH := 640.0
const HALF_WIDTH := 48.0
const CHARGE_SECONDS := 0.65
const REST_SECONDS := 0.90
const ROW_Y := [260.0, 505.0]
enum FillCurve { LINEAR, ACCELERATE, SMOOTH }
const CURVE_NAMES := ["Linear", "Beschleunigend", "S-Kurve"]
var warning_seconds := 2.2
var curve := FillCurve.ACCELERATE
var strength := 2.2
var clock_seconds := 0.0
var stopped := false
var slow := false
var progress := 0.0
var trail_alpha := 1.0
var lanes: Array[NeonChargePreviewLane] = []
var enemies: Array[Node2D] = []
var previous_label: Label
var fill_labels: Array[Label] = []
var curve_label: Label
var phase_label: Label
var pause_button: Button
var slider: HSlider
var curve_picker: OptionButton
var strength_control: SpinBox
var duration_control: SpinBox

func _ready() -> void:
	var viewport := get_tree().root
	viewport.size = STUDY_SIZE
	viewport.content_scale_size = STUDY_SIZE
	var floor := DentiArena.new()
	floor.z_index = -100
	add_child(floor)
	for index in 2:
		var lane: NeonChargePreviewLane = LANE.new()
		lane.z_index = -1
		add_child(lane)
		lane.configure(Vector2(START_X, ROW_Y[index]), Vector2(START_X + LENGTH, ROW_Y[index]), HALF_WIDTH)
		lane.cinematic = index == 1
		lanes.append(lane)
		var enemy: Node2D
		if index == 0:
			var simple := Sprite2D.new()
			simple.texture = EnemyCatalog.SUGAR.sprite
			simple.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
			simple.scale = Vector2.ONE * 88.0 / simple.texture.get_height()
			enemy = simple
		else:
			enemy = ACTOR.new()
			enemy.setup(EnemyCatalog.SUGAR.sprite)
		enemy.z_index = 2
		add_child(enemy)
		enemies.append(enemy)
		var denti := Sprite2D.new()
		denti.texture = DENTI
		denti.scale = Vector2.ONE * 85.0 / denti.texture.get_height()
		denti.position = Vector2(760, ROW_Y[index] + 74)
		denti.z_index = 3
		add_child(denti)
	_build_ui()
	seek(0)

func _build_ui() -> void:
	var layer := CanvasLayer.new()
	layer.layer = 10
	add_child(layer)
	var ui := Control.new()
	ui.theme = DentiUIStyle.make_theme()
	layer.add_child(ui)
	var header := ColorRect.new()
	header.color = Color("25212d")
	header.size = Vector2(STUDY_SIZE.x, 102)
	header.mouse_filter = Control.MOUSE_FILTER_IGNORE
	ui.add_child(header)
	_label(ui, "Charge · Bewegung & Licht", Vector2(40, 24), 31, DentiUIStyle.INK)
	phase_label = _label(ui, "Aufladen", Vector2(890, 32), 23, DentiUIStyle.GOLD)
	previous_label = _label(ui, "Vorher", Vector2(42, 141), 25, Color("705753"))
	curve_label = _label(ui, CURVE_NAMES[curve], Vector2(42, 387), 25, Color("70512a"))
	for index in 2:
		fill_labels.append(_label(ui, "", Vector2(860, ROW_Y[index] - 111), 20, Color("705753")))
	var footer := ColorRect.new()
	footer.color = Color("25212d")
	footer.position = Vector2(0, 634)
	footer.size = Vector2(STUDY_SIZE.x, 166)
	ui.add_child(footer)
	pause_button = _button(ui, "Pause", Vector2(32, 652))
	pause_button.pressed.connect(func(): _set_stopped(not stopped))
	var slow_button := _button(ui, "Zeitlupe", Vector2(182, 652))
	slow_button.toggle_mode = true
	slow_button.toggled.connect(func(value: bool): slow = value)
	var restart := _button(ui, "Neu starten", Vector2(332, 652))
	restart.pressed.connect(func():
		_set_stopped(false)
		seek(0))
	slider = HSlider.new()
	slider.position = Vector2(550, 663)
	slider.size = Vector2(500, 28)
	slider.min_value = 0
	slider.max_value = 1
	slider.step = 0.001
	slider.tooltip_text = "Aufladung anhalten und ansehen"
	ui.add_child(slider)
	slider.value_changed.connect(func(value: float):
		_set_stopped(true)
		seek(value * warning_seconds))
	curve_picker = OptionButton.new()
	curve_picker.position = Vector2(32, 719)
	curve_picker.size = Vector2(255, 48)
	for title in CURVE_NAMES: curve_picker.add_item(title)
	curve_picker.select(curve)
	ui.add_child(curve_picker)
	curve_picker.item_selected.connect(func(index: int):
		curve = index as FillCurve
		strength_control.editable = curve == FillCurve.ACCELERATE
		seek(clock_seconds))
	_label(ui, "Anzug", Vector2(310, 730), 20, DentiUIStyle.INK)
	strength_control = _spin(ui, Vector2(400, 719), 1, 4, 0.1, strength)
	strength_control.value_changed.connect(func(value: float):
		strength = value
		seek(clock_seconds))
	_label(ui, "Dauer", Vector2(565, 730), 20, DentiUIStyle.INK)
	duration_control = _spin(ui, Vector2(650, 719), 0.6, 4, 0.1, warning_seconds)
	duration_control.suffix = "s"
	duration_control.value_changed.connect(func(value: float):
		warning_seconds = value
		seek(0))
	_label(ui, "Gleiche Warnzeit", Vector2(875, 730), 18, DentiUIStyle.GOLD)

func _spin(parent: Node, at: Vector2, low: float, high: float, increment: float, initial: float) -> SpinBox:
	var control := SpinBox.new()
	control.position = at
	control.size = Vector2(124, 48)
	control.min_value = low
	control.max_value = high
	control.step = increment
	control.value = initial
	parent.add_child(control)
	return control

func _label(parent: Node, text: String, at: Vector2, size: int, color: Color) -> Label:
	var label := Label.new()
	label.text = text
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", color)
	parent.add_child(label)
	return label

func _button(parent: Node, text: String, at: Vector2) -> Button:
	var button := Button.new()
	button.text = text
	button.position = at
	button.size = Vector2(136, 48)
	DentiUIStyle.style_button(button)
	parent.add_child(button)
	return button

func _set_stopped(value: bool) -> void:
	stopped = value
	pause_button.text = "Fortsetzen" if stopped else "Pause"

func _process(delta: float) -> void:
	if not stopped: seek(clock_seconds + delta * (0.35 if slow else 1.0))

func seek(seconds: float) -> void:
	clock_seconds = fposmod(seconds, period())
	progress = clampf(clock_seconds / warning_seconds, 0, 1)
	var release := maxf(clock_seconds - warning_seconds, 0)
	var charging := clock_seconds >= warning_seconds and release < CHARGE_SECONDS
	trail_alpha = 1.0 if clock_seconds < warning_seconds else 1.0 - smoothstep(0.18, 0.53, release)
	var flash := maxf(0, 1.0 - release / 0.18) if charging else 0.0
	var movement := clampf(release / CHARGE_SECONDS, 0, 1)
	for index in enemies.size():
		var fill := fill_fraction(progress, curve, strength)
		var alpha := 1.0 if index == 1 else trail_alpha
		lanes[index].set_release(clock_seconds - warning_seconds, CHARGE_SECONDS)
		lanes[index].sample(progress, fill, clock_seconds, flash, alpha)
		fill_labels[index].text = "%d %% gefüllt" % roundi(fill * 100)
		enemies[index].position = Vector2(START_X + LENGTH * movement, ROW_Y[index])
		if index == 0:
			enemies[index].rotation = -0.10 if charging else sin(clock_seconds * 4) * progress * 0.025
		else:
			enemies[index].sample(progress, clock_seconds - warning_seconds, CHARGE_SECONDS)
	previous_label.text = "Vorher · " + CURVE_NAMES[curve]
	curve_label.text = "Inszeniert · " + CURVE_NAMES[curve]
	phase_label.text = "Zeit · %d %%" % roundi(progress * 100) if clock_seconds < warning_seconds else ("Charge" if charging else "Bereit")
	slider.set_value_no_signal(progress)

func period() -> float:
	return warning_seconds + CHARGE_SECONDS + REST_SECONDS

static func fill_fraction(time_fraction: float, mode: FillCurve, exponent: float) -> float:
	var t := clampf(time_fraction, 0, 1)
	match mode:
		FillCurve.ACCELERATE: return pow(t, clampf(exponent, 1, 4))
		FillCurve.SMOOTH: return t * t * (3.0 - 2.0 * t)
	return t
