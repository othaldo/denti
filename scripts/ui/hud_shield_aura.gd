class_name HUDShieldAura
extends Control

# One filtered distance field renders all shells without overlapping line joins.
const SURFACE: Shader = preload("res://scripts/ui/tooth_shield.gdshader")
const DISTANCE: Texture2D = preload("res://assets/ui/tooth_shield_distance.res")
var charges := 0
var veil: ShaderMaterial
var _surface := ColorRect.new()
var _shape_rect := Rect2()
var _visual_rect := Rect2()
var _motion := true
var _phase := 0.0


func _init(contour: PackedVector2Array, source: Texture2D) -> void:
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	visible = false
	_shape_rect = Rect2(contour[0] / source.get_size(), Vector2.ZERO)
	for point in contour:
		_shape_rect = _shape_rect.expand(point / source.get_size())
	veil = ShaderMaterial.new()
	veil.shader = SURFACE
	veil.set_shader_parameter("distance_field", DISTANCE)
	_surface.material = veil
	_surface.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_surface)
	resized.connect(_layout)


func show_charges(amount: int) -> void:
	var next := clampi(amount, 0, 5)
	if next == charges:
		return
	charges = next
	visible = charges > 0
	veil.set_shader_parameter("charges", charges)
	_layout()


func set_motion(enabled: bool) -> void:
	if _motion == enabled:
		return
	_motion = enabled
	veil.set_shader_parameter("motion", 1.0 if enabled else 0.0)


func set_phase(value: float) -> void:
	_phase = value
	veil.set_shader_parameter("phase", value)


func _layout() -> void:
	if size.x < 1 or size.y < 1:
		return
	_surface.position = -size * 0.25
	_surface.size = size * 1.5
	veil.set_shader_parameter("tooth_size", minf(size.x, size.y))
	var padding := 2.0 + maxi(0, charges - 1) * 3.2 + 5.0
	_visual_rect = Rect2(_shape_rect.position * size, _shape_rect.size * size).grow(padding)


func visual_rect() -> Rect2:
	return _visual_rect
