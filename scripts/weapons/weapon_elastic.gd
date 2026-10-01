class_name WeaponElastic
extends Node2D

var data: WeaponData
var pouch: Sprite2D
var left: Vector2
var right: Vector2
var rest: Vector2


func configure(weapon: WeaponData) -> void:
	data = weapon
	var size := data.held_texture().get_size()
	left = (data.fork_left_anchor - data.grip_anchor) * size
	right = (data.fork_right_anchor - data.grip_anchor) * size
	rest = (data.pouch_anchor - data.grip_anchor) * size
	pouch = Sprite2D.new()
	pouch.texture = data.pull_texture
	pouch.scale = Vector2.ONE * size.x * data.pouch_width / pouch.texture.get_width()
	add_child(pouch)
	set_progress(-1.0)


func set_progress(progress: float) -> void:
	# The shot is emitted at attack start; the pouch snaps forward, settles,
	# then draws back for the next shot without changing the muzzle anchor.
	var pull := 1.0 if progress < 0.0 else clampf((progress - 0.15) / 0.85, 0.0, 1.0)
	pouch.position = rest + Vector2(0.0, data.held_texture().get_height() * 0.09 * pull)
	queue_redraw()


func _draw() -> void:
	var width := data.held_texture().get_width() * 0.018
	for anchor in [left, right]:
		draw_line(anchor, pouch.position, Color("35262d"), width, true)
		draw_line(anchor, pouch.position, Color("6e5051"), width * 0.32, true)
