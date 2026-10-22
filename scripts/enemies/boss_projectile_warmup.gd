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
		# Exercise the actual textured strip, sector, timer and shadow paths.
		AttackEffects.lane(self, Vector2(1, 4), Vector2(7, 4), 2.0, Color.WHITE, 0.5)
		WarningEffects.charge(self, Vector2(1, 4), Vector2(7, 4), 2.0, 4, Color.WHITE, 0.5)
		WarningEffects.charge_impact(self, Vector2(4, 4), 2, 0.5)
		AttackEffects.lane(self, Vector2(1, 4), Vector2(7, 4), 2.0, Color.WHITE, 0.5, Transform2D.IDENTITY, PackedFloat32Array([1, 1, 0.5, 0.3, 0.2, 0.3, 0.5, 1, 1]))
		AttackEffects.spray(self, Vector2(1, 4), Vector2.RIGHT, 6.0, 65.0, Color.WHITE, 0.0)
		CrownCourtVisuals._sector(self, Vector2(1, 4), Vector2.RIGHT, 6.0, 60.0, Color.WHITE, Transform2D.IDENTITY)
		AttackEffects.warning_ring(self, Vector2(4, 4), 2.0, 0.5, Color.WHITE)
		AttackEffects.danger(self, Vector2(4, 4), 2.0, Color.WHITE)
		WarningEffects.sector(self, Vector2(1, 4), Vector2.RIGHT, 4, deg_to_rad(40), 0.5, false, false)
		WarningEffects.ring(self, Vector2(4, 4), 1, 2, 0.5, false, false)
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
	WarningEffects.prepare()
	textures.append(CombatGlyphs.ATLAS)
	textures.append(GroundEffects.ATLAS)
	textures.append(AttackEffects.ATLAS)
	textures.append_array(art_textures())
	texture_count = textures.size()
	for texture in textures:
		var sprite := Sprite2D.new()
		sprite.texture = texture
		sprite.position = Vector2(4, 4)
		sprite.scale = Vector2.ONE * (6.0 / maxf(texture.get_width(), texture.get_height()))
		add_child(sprite)
	add_child(ChargePreview.new())
	var cloak: CountCloakRig = CloakEncounter.RIG.instantiate()
	cloak.name = &"CloakRigWarmup"
	cloak.position = Vector2(4, 7)
	cloak.scale = Vector2.ONE * 0.02
	add_child(cloak)
	cloak.sample(1.09)
	var collector := KingAcidRig.new()
	collector.name = &"KingRigWarmup"
	collector.position = Vector2(4, 7)
	collector.scale = Vector2.ONE * 0.02
	add_child(collector)
	collector.sample(0, 1, 0, 0, false, true)
	collector.show_acid_level(0.5)
	var emperor := EmperorCourtRig.new()
	emperor.name = &"EmperorRigWarmup"
	emperor.scale = Vector2.ONE * 0.02
	emperor.position = Vector2(4, 7)
	add_child(emperor)
	emperor.sample(0, 1, 2, Vector2.DOWN, true)
	var goblin := LootGoblinRig.new()
	goblin.name = &"GoblinRigWarmup"
	goblin.scale = Vector2.ONE * 0.02
	goblin.position = Vector2(4, 7)
	add_child(goblin)
	goblin.sample(0.25, true, true, false, 0.5, 1)
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
	# Prepare the HUD's shared contour/mipmaps and exercise its shaders before
	# Start/Continue, alongside the existing combat graphics warmup.
	var hud := Control.new()
	hud.name = "CombatHUDWarmup"
	add_child(hud)
	var tooth := HUDToothVessel.new()
	tooth.size = Vector2(108, 108)
	tooth.scale = Vector2.ONE * 0.05
	hud.add_child(tooth)
	tooth.show_value(100, 100, "100 / 100")
	tooth.show_shield(1)
	var level := HUDProgressionFrame.new()
	level.size = Vector2(32, 32)
	level.scale = Vector2.ONE * 0.1
	hud.add_child(level)
	var boss_frame := HUDPaintedFrame.new(GameHUD.BOSS_ART)
	boss_frame.size = Vector2(6, 2)
	hud.add_child(boss_frame)
	var stamina := HUDToothVessel.new("res://assets/ui/stamina_vessel_frame.png")
	stamina.size = Vector2(108, 108)
	stamina.scale = Vector2.ONE * 0.05
	hud.add_child(stamina)
	for id: StringName in HUDStatusIcons.SOURCES:
		HUDStatusIcons.texture(id)
	_release_after_render()


static func art_textures() -> Array[Texture2D]:
	var result: Array[Texture2D] = [DentiExpressions.BODY, DentiExpressions.ATLAS]
	result.append(CountCloakRig.ART)
	result.append(PrinceCaramelArt.ATLAS)
	result.append(KingAcidArt.ATLAS)
	result.append(KingAcidArt.STREAM)
	result.append(EmperorCourtArt.ATLAS)
	for data in EnemyCatalog.ALL:
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
