class_name BossInflammationAura
extends AnimatedSprite2D

const FRAMES: SpriteFrames = preload("res://data/effects/boss_inflammation_frames.tres")
const FRAME_SIZE := Vector2(480, 480)
const VISUAL_ESCALATION_SECONDS := 60.0
const MAX_VISUAL_GROWTH := 0.22

var settings: EnemyData
var pulse_time: float = 0.0


func configure(enemy_data: EnemyData) -> void:
	settings = enemy_data
	name = "InflammationAura"
	z_index = -1
	sprite_frames = FRAMES
	animation = &"inflamed"
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	material = glow
	visible = false


func sync(active: bool, seconds: int, visual_offset: Vector2, delta: float, death_progress: float = 0.0) -> void:
	visible = active and settings.is_boss and death_progress < 1.0
	if not visible:
		stop()
		return
	if not is_playing():
		play(&"inflamed")
	pulse_time += maxf(delta, 0.0)
	var escalation := clampf(float(seconds) / VISUAL_ESCALATION_SECONDS, 0.0, 1.0)
	var pulse := 1.0 + sin(pulse_time * 9.0) * 0.035
	var width := settings.radius * settings.inflammation_aura_size * (1.0 + MAX_VISUAL_GROWTH * escalation) * pulse
	scale = Vector2.ONE * width / FRAME_SIZE.x
	position = visual_offset + Vector2(0.0, -settings.radius * 0.12)
	modulate = settings.inflammation_color
	modulate.a = lerpf(settings.inflammation_intensity, 1.0, escalation * 0.5) * (1.0 - death_progress)
	speed_scale = 1.0 + escalation * 0.45
