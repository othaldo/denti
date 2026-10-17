extends SceneTree

const KINDS := ["Wassertropfen", "Heilige Lanze", "Fluorid-Rakete", "Säureklumpen", "Blutsplitter", "Boss-Splitter", "Zauberpaste", "Mundspülung", "Amalgam-Splitter"]

func _initialize() -> void:
	call_deferred("_run")

func _sprite(parent: Node, texture: Texture2D, at: Vector2, scale_factor: float = 0.5, angle: float = 0.0) -> Sprite2D:
	var sprite := Sprite2D.new()
	sprite.texture = texture
	sprite.position = at
	sprite.scale = Vector2.ONE * scale_factor
	sprite.rotation = angle
	parent.add_child(sprite)
	return sprite

func _label(parent: Node, message: String, at: Vector2, font_size: int = 20) -> void:
	var label := Label.new()
	label.text = message
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	label.add_theme_color_override("font_color", Color("fff1ce"))
	label.add_theme_color_override("font_shadow_color", Color("302a3b"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	root.size = Vector2i(1100, 1025)
	root.content_scale_size = root.size
	var scene := Node2D.new()
	root.add_child(scene)
	var floor_sprite := _sprite(scene, DentiArena.FLOOR, Vector2.ZERO)
	floor_sprite.centered = false
	floor_sprite.scale = Vector2(1100, 1025) / floor_sprite.texture.get_size()
	_label(scene, "DENTI · NEUE PROJEKTILE", Vector2(40, 20), 26)
	var textures: Array[Texture2D] = [CombatSpriteTextures.projectile(Color(0.24, 0.8, 1), 7), CombatSpriteTextures.projectile(Color(1, 0.86, 0.4), 11), CombatSpriteTextures.rocket(Color(0.69, 1.0, 0.78)), EnemyProjectileVisuals.body(EnemyProjectilePatterns.ACID_COLOR, 9), EnemyProjectileVisuals.body(DentiStatus.COLORS[1], 9), EnemyProjectileVisuals.body(EnemyProjectilePatterns.SPACE_ORB_COLOR, 9)]
	textures.append_array([CombatSpriteTextures.projectile(Color(0.76, 0.96, 1), 7), CombatSpriteTextures.projectile(Color(0.27, 0.9, 0.67), 11), CombatSpriteTextures.projectile(Color(0.69, 0.72, 0.8), 11)])
	for index in textures.size():
		var at := Vector2(60 + index % 3 * 355, 100 + index / 3 * 225)
		_label(scene, KINDS[index], at, 22)
		_label(scene, "Spielgröße", at + Vector2(0, 160), 16)
		_label(scene, "3×", at + Vector2(210, 160), 16)
		_sprite(scene, textures[index], at + Vector2(70, 100))
		_sprite(scene, textures[index], at + Vector2(240, 100), 1.5)
	_label(scene, "Viele Geschosse · normale Spielgröße · keine Partikelsysteme", Vector2(40, 800), 22)
	for index in 96:
		var at := Vector2(60 + index % 24 * 43, 865 + index / 24 * 42)
		_sprite(scene, textures[index % textures.size()], at, 0.5, -0.5 + float(index % 5) * 0.3)
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/projectile_art_preview.png")
	scene.free()
	if "--benchmark" in OS.get_cmdline_user_args():
		await _benchmark()
	quit()

func _benchmark() -> void:
	for painted in [false, true]:
		var scene := Node2D.new()
		root.add_child(scene)
		var tint := Color(0.24, 0.8, 1)
		for index in 200:
			var at := Vector2(40 + index % 20 * 50, 40 + index / 20 * 65)
			if painted:
				_sprite(scene, CombatSpriteTextures.projectile(tint, 7), at)
			else:
				for texture in [CombatSpriteTextures.projectile_tail(tint, 7), CombatSpriteTextures.projectile_outline(tint, 7), CombatSpriteTextures.projectile_body(tint, 7)]:
					_sprite(scene, texture, at)
		for frame in 8:
			await process_frame
			await RenderingServer.frame_post_draw
		print("200 shots, painted=", painted, ", sprites=", scene.get_child_count(), ", draw_calls=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME))
		scene.free()
