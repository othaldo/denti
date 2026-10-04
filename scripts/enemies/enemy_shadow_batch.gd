class_name EnemyShadowBatch
extends RefCounted

# One instanced draw beneath the enemy sprites, without extra gameplay children.
var multimesh := MultiMesh.new()
var texture: Texture2D
var enemies: Array[Enemy] = []

func _init() -> void:
	texture = CombatSpriteTextures.enemy_shadow()
	multimesh.transform_format = MultiMesh.TRANSFORM_2D
	multimesh.use_colors = true
	var quad := QuadMesh.new()
	quad.size = Vector2(32, 32)
	multimesh.mesh = quad
	multimesh.visible_instance_count = 0

func update() -> void:
	if multimesh.instance_count < enemies.size():
		multimesh.instance_count = maxi(16, nearest_po2(enemies.size()))
	var count := 0
	for enemy in enemies:
		if enemy.is_queued_for_deletion() or not enemy.visible:
			continue
		var radius := enemy.data.radius * 0.7
		var shadow := Transform2D(0, Vector2.ONE * radius / 15.0, 0, Vector2(0, radius))
		multimesh.set_instance_transform_2d(count, enemy.transform * shadow)
		multimesh.set_instance_color(count, enemy.modulate * enemy.self_modulate)
		count += 1
	multimesh.visible_instance_count = count
