class_name BossProjectileWarmup
extends SubViewport

var texture_count := 0
class ChargePreview extends Node2D:
	var shadow := EnemyShadowBatch.new()

	func _init() -> void:
		shadow.multimesh.instance_count = 1
		shadow.multimesh.visible_instance_count = 1
		shadow.multimesh.set_instance_transform_2d(0, Transform2D(0, Vector2.ONE * 0.05, 0, Vector2(4, 4)))
		shadow.multimesh.set_instance_color(0, Color.WHITE)

	func _draw() -> void:
		# Exercise the same built-in canvas draw paths as the lane warning/trail.
		draw_colored_polygon(PackedVector2Array([Vector2(1, 1), Vector2(7, 1), Vector2(7, 7), Vector2(1, 7)]), Color(0.95, 0.20, 0.29, 0.3))
		draw_line(Vector2(1, 4), Vector2(7, 4), Color(1.0, 0.72, 0.27, 0.7), 3.0)
		draw_circle(Vector2(6, 4), 1.0, Color(0.95, 0.20, 0.29, 0.3))
		draw_arc(Vector2(4, 4), 2.0, 0.0, TAU, 8, Color(1.0, 0.72, 0.27), 1.0)
		draw_multimesh(shadow.multimesh, shadow.texture)


func _ready() -> void:
	name = "BossProjectileWarmup"
	process_mode = Node.PROCESS_MODE_ALWAYS
	size = Vector2i(8, 8)
	world_2d = World2D.new()
	disable_3d = true
	gui_disable_input = true
	transparent_bg = true
	render_target_update_mode = SubViewport.UPDATE_ONCE
	# Preparing the images alone leaves their first rendered use in combat.
	# Draw them once in an isolated tiny viewport during the initial menu load.
	var textures := EnemyProjectileVisuals.standard_textures()
	textures.append_array(CombatSpriteTextures.standard_textures())
	CombatDrawCache.prepare()
	textures.append(CombatGlyphs.ATLAS)
	textures.append_array(art_textures())
	texture_count = textures.size()
	for texture in textures:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.position = Vector2(4, 4)
		sprite.scale = Vector2.ONE * (6.0 / maxf(texture.get_width(), texture.get_height()))
		add_child(sprite)
	add_child(ChargePreview.new())
	var numbers: Label = preload("res://scenes/ui/damage_number.tscn").instantiate()
	numbers.name = "CombatFontWarmup"
	numbers.text = "0123456789-+!"
	numbers.scale = Vector2.ONE * 0.1
	add_child(numbers)
	var additive := Sprite2D.new()
	additive.texture = BossInflammationAura.FRAMES.get_frame_texture(&"inflamed", 0)
	additive.scale = Vector2.ONE * 0.01
	var glow := CanvasItemMaterial.new()
	glow.blend_mode = CanvasItemMaterial.BLEND_MODE_ADD
	additive.material = glow
	add_child(additive)
	_release_after_render()


static func art_textures() -> Array[Texture2D]:
	var result: Array[Texture2D] = [DentiExpressions.BODY, DentiExpressions.ATLAS]
	for data in [WaveController.PLAQUE, WaveController.BACTERIA, WaveController.SUGAR, WaveController.ACID_SPITTER, WaveController.POISON_GERM, WaveController.GUM_BITER, WaveController.ACID_CROWN, WaveController.HUNT_GERM, WaveController.CAVITY_COUNT, WaveController.CAVITY_PRINCE, WaveController.CAVITY_KING, WaveController.CAVITY_EMPEROR]:
		result.append(data.sprite)
	var weapons: Array[WeaponData] = WeaponCatalog.ALL.duplicate()
	for recipe in WeaponEvolutions.ALL:
		weapons.append(recipe.result)
	for weapon in weapons:
		for texture in [weapon.held_texture(), weapon.working_head_texture, weapon.pull_texture]:
			if texture != null and not result.has(texture):
				result.append(texture)
	for frame in BossInflammationAura.FRAMES.get_frame_count(&"inflamed"):
		result.append(BossInflammationAura.FRAMES.get_frame_texture(&"inflamed", frame))
	return result


func _release_after_render() -> void:
	# process_frame also works with the headless test renderer, which does not
	# emit frame_post_draw. The textures remain in the shared visual cache.
	await get_tree().process_frame
	await get_tree().process_frame
	queue_free()
