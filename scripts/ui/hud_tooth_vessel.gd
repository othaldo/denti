class_name HUDToothVessel
extends Control

const LIQUID: Shader = preload("res://scripts/ui/tooth_liquid.gdshader")
const FRAME_PATH := "res://assets/ui/tooth_vessel_frame.png"
static var _frame: Texture2D
static var _outline: PackedVector2Array

var value: float = 100.0
var max_value: float = 100.0
var displayed_ratio: float = 1.0
var trailing_ratio: float = 1.0
var phase: float = 0.0
var impact: float = 0.0
var label: Label
var maximum_label: Label
var glass: TextureRect
var liquid: ShaderMaterial
var shield_aura: HUDShieldAura
var _fluid: Polygon2D
var _target: float = 1.0
var _trail_delay: float = 0.0
var _initialized := false
var _compact := false


func _init() -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	_prepare_frame()
	liquid = ShaderMaterial.new()
	liquid.shader = LIQUID
	_fluid = Polygon2D.new()
	_fluid.polygon = _outline
	_fluid.uv = _outline
	_fluid.texture = _frame
	_fluid.material = liquid
	_fluid.antialiased = true
	add_child(_fluid)
	glass = TextureRect.new()
	glass.mouse_filter = Control.MOUSE_FILTER_IGNORE
	glass.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	glass.stretch_mode = TextureRect.STRETCH_SCALE
	glass.texture = _frame
	var rim := ShaderMaterial.new()
	rim.shader = LIQUID
	rim.set_shader_parameter("frame_pass", true)
	glass.material = rim
	add_child(glass)
	shield_aura = HUDShieldAura.new(_outline, _frame)
	add_child(shield_aura)
	label = Label.new()
	label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	label.clip_text = true
	label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DentiUIStyle.style_hud_text(label, DentiUIStyle.INK, 18, 4, DentiUIStyle.BACKGROUND)
	add_child(label)
	maximum_label = Label.new()
	maximum_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	maximum_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	maximum_label.clip_text = true
	maximum_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	DentiUIStyle.style_hud_text(maximum_label, DentiUIStyle.INK, 12, 3, DentiUIStyle.BACKGROUND)
	add_child(maximum_label)
	resized.connect(_layout)


static func _prepare_frame() -> void:
	if _frame != null:
		return
	_frame = load(FRAME_PATH)
	var bitmap := BitMap.new()
	bitmap.create_from_image_alpha(_frame.get_image(), 0.3)
	var largest_area := 0.0
	for polygon in bitmap.opaque_to_polygons(Rect2i(Vector2i.ZERO, bitmap.get_size()), 1.5):
		var area := 0.0
		for index in polygon.size():
			var next: Vector2 = polygon[(index + 1) % polygon.size()]
			area += polygon[index].cross(next)
		if absf(area) > largest_area:
			largest_area = absf(area)
			_outline = polygon


func show_value(amount: float, maximum: float, caption: String) -> void:
	value = amount
	max_value = maximum
	var ratio := clampf(amount / maxf(maximum, 0.001), 0.0, 1.0)
	if not _initialized:
		displayed_ratio = ratio
		trailing_ratio = ratio
		_initialized = true
	elif ratio < _target:
		impact = 1.0
		_trail_delay = 0.25
	_target = ratio
	label.text = caption.get_slice(" / ", 0)
	maximum_label.text = "/ " + caption.get_slice(" / ", 1)
	tooltip_text = caption
	_upload()


func set_compact(compact: bool) -> void:
	_compact = compact
	_layout()


func show_shield(charges: int) -> void:
	shield_aura.show_charges(charges)


func _layout() -> void:
	var art_size := Vector2.ONE * (96 if _compact else 108)
	glass.position = Vector2((size.x - art_size.x) * 0.5, 0)
	glass.size = art_size
	_fluid.position = glass.position
	_fluid.scale = art_size / _frame.get_size()
	shield_aura.position = glass.position
	shield_aura.size = art_size
	var inset := glass.position.x + art_size.x * 0.17
	var width := art_size.x * 0.66
	var top := floorf(art_size.y * 0.21)
	var line_height := 24.0
	label.position = Vector2(inset, top)
	label.size = Vector2(width, line_height)
	maximum_label.position = Vector2(inset, top + line_height)
	maximum_label.size = Vector2(width, 18)


func _process(delta: float) -> void:
	var animated := DentiUIMotion.enabled(self)
	shield_aura.set_motion(animated)
	liquid.set_shader_parameter("motion", 1.0 if animated else 0.0)
	if not animated:
		displayed_ratio = _target
		trailing_ratio = _target
		impact = 0.0
		_upload()
	elif not get_tree().paused:
		advance(delta)


func advance(delta: float) -> void:
	phase = fmod(phase + delta, 3600.0)
	displayed_ratio = lerpf(displayed_ratio, _target, 1.0 - exp(-14.0 * delta))
	_trail_delay = maxf(0, _trail_delay - delta)
	if _trail_delay <= 0 or _target > trailing_ratio:
		trailing_ratio = lerpf(trailing_ratio, _target, 1.0 - exp(-4.5 * delta))
	trailing_ratio = maxf(trailing_ratio, displayed_ratio)
	impact = maxf(0, impact - delta * 4.0)
	_upload()


func _upload() -> void:
	shield_aura.set_phase(phase)
	liquid.set_shader_parameter("fill", displayed_ratio)
	liquid.set_shader_parameter("trail", trailing_ratio)
	liquid.set_shader_parameter("phase", phase)
	liquid.set_shader_parameter("impact", impact)
