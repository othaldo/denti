extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var index := EnemySpatialIndex.new()
	root.add_child(index)
	for number in 40:
		var enemy: Enemy = load("res://scenes/enemies/enemy.tscn").instantiate()
		enemy.configure(WaveController.PLAQUE, null, 17)
		enemy.position = Vector2(number * 30, 50)
		index.add_child(enemy)
	var batch := index.shadow_batch
	batch.update()
	_check(index.get_child_count() == 40 and batch.multimesh.visible_instance_count == 40, "batched shadows changed enemy child counts or omitted enemies")
	_check(batch.multimesh.instance_count >= 40 and batch.multimesh.instance_count <= 80, "shadow instance capacity grows without a bound")
	_check(batch.texture == CombatSpriteTextures.enemy_shadow(), "shadows regenerate their texture")
	var hidden: Enemy = index.get_child(0)
	hidden.visible = false
	var removed: Enemy = index.get_child(1)
	removed.queue_free()
	batch.update()
	_check(batch.multimesh.visible_instance_count == 38, "hidden/deleted enemies leave visible shadows")
	var moved: Enemy = index.get_child(2)
	moved.position = Vector2(-129, 370)
	moved.rotation = 0.3
	moved.scale = Vector2(1.2, 0.8)
	moved.modulate = Color(1.3, 1.3, 1.3, 0.4)
	batch.update()
	# The dummy headless renderer does not store GPU instance transforms.
	if DisplayServer.get_name() != "headless":
		var atlas := batch.texture as AtlasTexture
		var coordinates: PackedVector2Array = batch.multimesh.mesh.surface_get_arrays(0)[Mesh.ARRAY_TEX_UV]
		var bounds := Rect2(atlas.region.position / atlas.atlas.get_size(), atlas.region.size / atlas.atlas.get_size()).grow(0.00001)
		for coordinate in coordinates:
			_check(bounds.has_point(coordinate), "shadow mesh samples outside its packed atlas region")
		var transform := batch.multimesh.get_instance_transform_2d(0)
		_check(transform.origin.is_equal_approx(moved.transform * Vector2(0, moved.data.radius * 0.7)), "shadow lost the enemy's transform")
		var color := batch.multimesh.get_instance_color(0)
		# Instance colors are stored at half precision by the real renderer.
		_check(absf(color.a - moved.modulate.a) < 0.005 and absf(color.r - moved.modulate.r) < 0.005, "shadow lost hit tint or transparency: %s" % color)
	for enemy in index.get_children():
		enemy.free()
	_check(batch.enemies.is_empty() and batch.multimesh.visible_instance_count == 0 and not index.is_processing(), "combat cleanup left live shadows or processing")
	index.free()
	if failures.is_empty():
		print("Denti enemy shadow batch regression test passed")
	quit(0 if failures.is_empty() else 1)
