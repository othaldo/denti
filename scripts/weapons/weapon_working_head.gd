class_name WeaponWorkingHead
extends Node2D

# Project the circular face after rotating it: its elliptical outline and axle
# stay fixed while the painted grooves rotate inside that perspective.
var face: Sprite2D
var spin_angle: float = 0.0


func configure(data: WeaponData) -> void:
	position = WeaponMotion.tip_local(data)
	rotation = deg_to_rad(data.working_head_angle_degrees)
	scale = Vector2(data.working_head_aspect, 1.0)
	face = Sprite2D.new()
	face.texture = data.working_head_texture
	var diameter := minf(data.held_texture().get_size().x, data.held_texture().get_size().y) * data.working_head_radius * 2.0
	face.scale = Vector2.ONE * diameter / maxf(face.texture.get_size().x, face.texture.get_size().y)
	add_child(face)


func advance(angle: float) -> void:
	spin_angle = fposmod(spin_angle + angle, TAU)
	face.rotation = spin_angle
