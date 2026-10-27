class_name WeaponFlossCut
extends Node2D
## Painted grips stay with Denti; connected elemental floss does the attack.

var data: WeaponData
var left: Sprite2D
var right: Sprite2D
var points := PackedVector2Array()
var strands: Array[PackedVector2Array] = []
var progress := -1.0
var seconds := 0.0


func configure(weapon: WeaponData) -> void:
	data = weapon
	left = _grip(data.floss_left_texture, data.grip_anchor)
	if data.floss_right_texture != null:
		right = _grip(data.floss_right_texture, Vector2(1 - data.grip_anchor.x, data.grip_anchor.y))


func _grip(texture: Texture2D, anchor: Vector2) -> Sprite2D:
	var result := Sprite2D.new()
	result.texture = texture
	result.offset = (Vector2.ONE * 0.5 - anchor) * texture.get_size()
	result.texture_filter = CanvasItem.TEXTURE_FILTER_LINEAR_WITH_MIPMAPS
	add_child(result)
	return result


func set_pose(pose_data: Dictionary, phase: float, time: float, density: float) -> void:
	strands = pose_data.strands
	points = strands[0]
	progress = phase
	seconds = time
	var factor := WeaponMotion.base_scale(data, density)
	left.position = pose_data.grips[0]
	left.rotation = pose_data.heading - (data.floss_left_tip - data.grip_anchor).angle()
	left.scale = Vector2.ONE * factor
	if right != null:
		right.position = pose_data.grips[1]
		var anchor := Vector2(1 - data.grip_anchor.x, data.grip_anchor.y)
		right.rotation = pose_data.heading - (data.floss_right_tip - anchor).angle()
		right.scale = left.scale
	queue_redraw()


func _draw() -> void:
	if points.is_empty(): return
	var active := progress >= WeaponMotion.ACTIVE_START and progress <= WeaponMotion.ACTIVE_END
	var elemental := WeaponElementVisuals.ELEMENTS.has(data.element_skin)
	var color := WeaponElementVisuals.color(data.element_skin, Color("fff8dc"))
	for strand in strands:
		draw_polyline(strand, Color("372431"), 4.2, true)
		if active and elemental:
			for index in strand.size() - 1:
				WeaponElementVisuals.strip(self, data.element_skin, AttackEffects.Shape.THREAD, strand[index], strand[index + 1], data.attack_width, Color.WHITE, seconds)
			draw_polyline(strand, Color(color.lightened(0.35), 0.85), 1.0, true)
			# Painted flames, frost, slime, sparks, blood or droplets travel forward.
			for mote in 3:
				var at := float(mote) / 3 + seconds * WeaponElementVisuals.animation_rate(data.element_skin) * 1.8
				var index := clampi(int(fposmod(at, 1) * (strand.size() - 1)), 1, strand.size() - 1)
				WeaponElementVisuals.flash(self, data.element_skin, strand[index], 5.5, Color(1, 1, 1, 0.8), seconds + mote * 0.07)
			WeaponElementVisuals.flash(self, data.element_skin, strand[-1], 9, Color.WHITE, seconds)
		else:
			draw_polyline(strand, color, 2.2, true)
			draw_polyline(strand, Color(color.lightened(0.6), 0.8), 0.65, true)
