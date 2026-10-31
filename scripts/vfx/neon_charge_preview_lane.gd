class_name NeonChargePreviewLane
extends Node2D
## Isolated visual study; never registers an attack or modifies WarningEffects.

const SHADER := preload("res://scripts/vfx/neon_charge_preview.gdshader")
const GLOW_PADDING := 56.0
var path_length := 640.0
var half_width := 48.0
var effect := ShaderMaterial.new()
var cinematic := false
var release_seconds := -1.0
var charge_duration := 0.65

func _init() -> void:
	effect.shader = SHADER
	material = effect

func configure(start: Vector2, end: Vector2, width: float) -> void:
	position = start
	rotation = start.angle_to_point(end)
	path_length = start.distance_to(end)
	half_width = maxf(width, 1.0)
	effect.set_shader_parameter("path_length", path_length)
	effect.set_shader_parameter("half_width", half_width)
	visible = path_length > 0.01
	queue_redraw()

func sample(charge_progress: float, fill_fraction: float, seconds: float, flash: float = 0.0, alpha: float = 1.0) -> void:
	visible = path_length > 0.01 and alpha > 0.001 and (not cinematic or release_seconds < charge_duration + 0.28)
	if not visible: return
	effect.set_shader_parameter("progress", clampf(charge_progress, 0, 1))
	effect.set_shader_parameter("fill_progress", clampf(fill_fraction, 0, 1))
	effect.set_shader_parameter("clock_seconds", maxf(seconds, 0))
	effect.set_shader_parameter("release_flash", clampf(flash, 0, 1))
	effect.set_shader_parameter("opacity", clampf(alpha, 0, 1))

func set_release(seconds: float, duration: float) -> void:
	release_seconds = seconds
	charge_duration = duration
	effect.set_shader_parameter("cinematic", cinematic)
	effect.set_shader_parameter("release_seconds", seconds)
	effect.set_shader_parameter("charge_seconds", duration)

func _draw() -> void:
	if path_length <= 0.01: return
	draw_rect(Rect2(Vector2(-GLOW_PADDING, -half_width - GLOW_PADDING), Vector2(path_length + GLOW_PADDING * 2, half_width * 2 + GLOW_PADDING * 2)), Color.WHITE)
