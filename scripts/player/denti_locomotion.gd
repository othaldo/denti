class_name DentiLocomotion
extends Sprite2D

enum Heading { NORTH, NORTHEAST, EAST, SOUTHEAST, SOUTH, SOUTHWEST, WEST, NORTHWEST }

const ART := {
	&"good_old_molar": preload("res://assets/denti/locomotion/good_old_molar.png"),
	&"assassin": preload("res://assets/denti/locomotion/assassin.png"),
	&"tooth_fairy": preload("res://assets/denti/locomotion/tooth_fairy.png"),
	&"ember": preload("res://assets/denti/locomotion/ember.png"),
	&"rinser": preload("res://assets/denti/locomotion/rinser.png"),
	&"frost_warden": preload("res://assets/denti/locomotion/frost_warden.png"),
	&"necrodent": preload("res://assets/denti/locomotion/necrodent.png"),
	&"herb_druid": preload("res://assets/denti/locomotion/herb_druid.png"),
}
const ROOT_MOTION := preload("res://scripts/player/denti_root_motion.gdshader")
# The frame packer aligns the painted body and its soles to these coordinates.
const FRAME_CENTER := Vector2(112, 96)
const PAINTED_HEIGHT := 150.0
const WALK_DISTANCE := 80.0
const ROOT_START_BY_CLASS := {
	&"tooth_fairy": 0.74, &"ember": 0.78, &"rinser": 0.75,
	&"frost_warden": 0.78, &"necrodent": 0.75, &"herb_druid": 0.80,
}

@onready var body := get_parent() as Sprite2D
@onready var expressions := get_node("../Expressions") as DentiExpressions

var profile_id: StringName
var facing: Heading = Heading.SOUTH
var step_weight := 0.0
var dash_weight := 0.0
var step_phase := 0.0
var breath_phase := 0.0
var _body_scale := Vector2.ONE
var _foot := Vector2.ZERO
var _moving := false
var _motion := ShaderMaterial.new()


func _ready() -> void:
	_motion.shader = ROOT_MOTION
	_motion.set_shader_parameter("frame_grid", Vector2(hframes, vframes))
	material = _motion
	expressions.face_changed.connect(_on_face_changed)


func configure(id: StringName, body_scale: Vector2, height: float, foot: Vector2) -> void:
	profile_id = id
	_body_scale = body_scale
	_foot = foot
	texture = ART.get(id)
	visible = texture != null
	body.self_modulate.a = 0.0 if visible else 1.0
	if not visible:
		expressions.present_default_face()
		return
	var frame_scale := height / PAINTED_HEIGHT
	scale = Vector2.ONE * frame_scale / body_scale
	position = (foot - Vector2(0, height * 0.5)) / body_scale
	_motion.set_shader_parameter("root_start", ROOT_START_BY_CLASS.get(id, 0.70))
	_refresh_heading()


func advance(direction: Vector2, distance: float, dashing: bool, delta: float, attack: Vector2, cast_lift: float) -> void:
	var moving := distance > 0.01
	var refresh_heading := moving != _moving
	_moving = moving
	if moving and not direction.is_zero_approx():
		var next := posmod(roundi(direction.angle() * 8 / TAU) + 2, 8) as Heading
		refresh_heading = refresh_heading or facing != next
		facing = next
	if refresh_heading:
		_refresh_heading()
	var walking := moving and not dashing
	if walking:
		step_phase = fposmod(step_phase + distance / WALK_DISTANCE * TAU, TAU)
	step_weight = move_toward(step_weight, 1.0 if walking else 0.0, delta * 11.0)
	dash_weight = move_toward(dash_weight, 1.0 if dashing and moving else 0.0, delta * 18.0)
	breath_phase = fposmod(breath_phase + delta * 3.0, TAU)
	var step := sin(step_phase)
	var stride := absf(step) * step_weight
	var horizontal := sin(float(facing) * TAU / 8.0)
	if visible:
		# The profile overlaps the roots, so its far foot needs a shorter lift.
		var root_lift := lerpf(0.083, 0.055, absf(horizontal)) * step_weight
		var reach := lerpf(0.024, 0.054, absf(horizontal)) * step_weight
		_motion.set_shader_parameter("root_lift", Vector2(maxf(step, 0.0), maxf(-step, 0.0)) * root_lift)
		_motion.set_shader_parameter("root_swing", Vector2(-1, 1) * cos(step_phase) * reach)
	var breath := sin(breath_phase) * 0.016 * (1.0 - step_weight)
	var stretch := breath + stride * 0.035 + dash_weight * 0.07
	var shape := Vector2(1.0 - stretch + attack.x * 0.12 - cast_lift * 0.07,
		1.0 + stretch - attack.x * 0.09 + cast_lift * 0.11)
	var lean := (horizontal * 0.065 + step * 0.055) * step_weight + horizontal * dash_weight * 0.19 + attack.y * 0.14
	var rotation := lerp_angle(body.rotation, lean, minf(delta * 14.0, 1.0))
	var deformation := Transform2D(rotation, shape, 0.0, Vector2.ZERO)
	var lift := 2.0 + stride * 2.3 + dash_weight * 4.0 + attack.x * 4.0 + cast_lift * 7.0
	body.position = _foot - deformation.basis_xform(_foot) - Vector2(0.0, lift)
	body.rotation = rotation
	body.scale = _body_scale * shape


func restore_facing(saved: Variant) -> void:
	facing = Heading.SOUTH
	if (saved is int or saved is float) and saved >= 0 and saved < Heading.size() and saved == floorf(float(saved)):
		facing = int(saved) as Heading
	step_weight = 0.0
	dash_weight = 0.0
	step_phase = 0.0
	advance(Vector2.ZERO, 0.0, false, 0.0, Vector2.ZERO, 0.0)
	_refresh_heading()


func _on_face_changed() -> void:
	if expressions.visible and expressions.current_face in [DentiExpressions.Face.CELEBRATE, DentiExpressions.Face.DEAD]:
		# Both can fire in the same frame the game disables player physics.
		step_weight = 0.0
		dash_weight = 0.0
		advance(Vector2.ZERO, 0.0, false, 0.0, Vector2.ZERO, 0.0)
	_refresh_heading()


func _refresh_heading() -> void:
	if texture == null:
		return
	var shown := facing
	if expressions.visible and (expressions.current_face == DentiExpressions.Face.DEAD or
			(expressions.current_face == DentiExpressions.Face.CELEBRATE and not _moving)):
		shown = Heading.SOUTH
	frame = shown
	@warning_ignore("integer_division")
	_motion.set_shader_parameter("frame_cell", Vector2(shown % hframes, shown / hframes))
	if not expressions.visible:
		return
	match shown:
		Heading.SOUTH:
			_project_face(Vector2(112, 93), Vector2(0.98, 0.98))
		Heading.SOUTHWEST:
			_project_face(Vector2(94, 92), Vector2(0.69, 0.92))
		Heading.SOUTHEAST:
			_project_face(Vector2(130, 92), Vector2(-0.69, 0.92))
		_:
			expressions.face_sprite.hide()


func _project_face(mouth: Vector2, size: Vector2) -> void:
	var anchor := (position + (mouth - FRAME_CENTER) * scale) / expressions.scale
	expressions.present_face(anchor, size)
