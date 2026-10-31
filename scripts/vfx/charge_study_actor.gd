extends Node2D
## Explicit-clock presentation only. Never moves an Enemy or changes a hitbox.

var sprite: Sprite2D
var base_scale := Vector2.ONE
var tension := 0.0
var release := -1.0
var duration := 0.65
var flash := 0.0

func setup(texture: Texture2D) -> void:
	sprite = Sprite2D.new()
	sprite.texture = texture
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	base_scale = Vector2.ONE * 88.0 / texture.get_height()
	add_child(sprite)

func sample(progress: float, seconds_after_release: float, charge_duration: float) -> void:
	tension = smoothstep(0.12, 0.96, progress)
	release = seconds_after_release
	duration = charge_duration
	if release >= 0: tension *= 1.0 - smoothstep(0, 0.20, release)
	flash = maxf(0, 1.0 - release / 0.09) if release >= 0 else 0.0
	if release < 0:
		sprite.scale = base_scale * Vector2(1.0 + tension * 0.16, 1.0 - tension * 0.14)
		sprite.position = Vector2(-tension * 11, tension * 6)
		sprite.rotation = -tension * 0.13
	elif release < duration:
		var stretch := 1.0 - smoothstep(0, 0.20, release)
		sprite.scale = base_scale * Vector2(1.10 + stretch * 0.22, 0.92 - stretch * 0.10)
		sprite.position = Vector2(4, -3)
		sprite.rotation = 0.12
	else:
		var elapsed := release - duration
		var settle := sin(elapsed * 24.0) * exp(-elapsed * 13.0)
		sprite.scale = base_scale * Vector2(1.0 - settle * 0.14, 1.0 + settle * 0.11)
		sprite.position = Vector2(settle * 5, -settle * 4)
		sprite.rotation = settle * 0.10
	sprite.modulate = Color.WHITE.lerp(Color(1.18, 1.08, 0.93), flash * 0.7)
	queue_redraw()

func _draw() -> void:
	# Contact shadow connects the squash/stretch to the floor.
	draw_set_transform(Vector2(sprite.position.x * 0.3, 33), 0, Vector2(1.0 + tension * 0.12, 0.22))
	draw_circle(Vector2.ZERO, 28, Color(0.23, 0.13, 0.10, 0.18 + tension * 0.04), true, -1, true)
	draw_set_transform(Vector2.ZERO)
	if release < 0:
		# Four converging, smoothly drawn glints; no particle nodes or random clocks.
		for index in 4:
			var angle := -1.1 + index * 0.72
			var ray := Vector2.from_angle(angle)
			var radius := lerpf(60, 32, tension)
			var point := ray * radius + Vector2(-8, 0)
			draw_line(point, point - ray * (3 + tension * 5), Color(1, 0.79, 0.40, tension * 0.52), 1.6, true)
	elif release < 0.20:
		var fraction := release / 0.20
		for index in 5:
			var ray := Vector2.from_angle(PI + (index - 2) * 0.27)
			var point := ray * (24 + fraction * 50)
			draw_line(point, point - ray * 12, Color(1, 0.85, 0.57, (1.0 - fraction) * 0.7), 1.6, true)
