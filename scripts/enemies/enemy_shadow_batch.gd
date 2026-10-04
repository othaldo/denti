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
	if texture is AtlasTexture:
		# MultiMesh consumes the underlying texture RID, not AtlasTexture's
		# region. Encode the region in mesh UVs instead of sampling the atlas.
		var region := texture as AtlasTexture
		var arrays := quad.get_mesh_arrays()
		var coordinates: PackedVector2Array = arrays[Mesh.ARRAY_TEX_UV]
		for index in coordinates.size():
			coordinates[index] = (region.region.position + coordinates[index] * region.region.size) / region.atlas.get_size()
		arrays[Mesh.ARRAY_TEX_UV] = coordinates
		var mesh := ArrayMesh.new()
		mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
		multimesh.mesh = mesh
	else:
		multimesh.mesh = quad
	multimesh.visible_instance_count = 0

func update() -> bool:
	if multimesh.instance_count < enemies.size():
		multimesh.instance_count = maxi(16, nearest_po2(enemies.size()))
	var count := 0
	var has_attack_visuals := false
	for enemy in enemies:
		if enemy.is_queued_for_deletion() or not enemy.visible:
			continue
		has_attack_visuals = has_attack_visuals or enemy.health > 0.0 and enemy.special_phase != Enemy.SpecialPhase.COOLDOWN
		var radius := enemy.data.radius * 0.7
		var shadow := Transform2D(0, Vector2.ONE * radius / 15.0, 0, Vector2(0, radius))
		multimesh.set_instance_transform_2d(count, enemy.transform * shadow)
		multimesh.set_instance_color(count, enemy.modulate * enemy.self_modulate)
		count += 1
	multimesh.visible_instance_count = count
	return has_attack_visuals
