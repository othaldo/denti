extends SceneTree
## Actual projectile nodes and production attack rendering, in a separate viewport.

const OUTPUT := "res://docs/screenshots/weapon_element_effects/"
const ELEMENTS: Array[StringName] = [&"", &"fire", &"ice", &"poison", &"electric", &"bleed", &"wet"]
var samples: Array[EffectSample] = []
var shots: Array[WeaponProjectile] = []

class EffectSample extends Node2D:
	var element: StringName
	var seconds := 0.0
	func _draw() -> void:
		var tint := Color(1, 1, 1, 0.85)
		WeaponElementVisuals.strip(self, element, AttackEffects.Shape.BEAM, Vector2(-66, 0), Vector2(66, 0), 26, tint, seconds)
		WeaponElementVisuals.strip(self, element, AttackEffects.Shape.SLASH, Vector2(-56, 126), Vector2(56, 98), 24, tint, seconds)
		WeaponElementVisuals.spray(self, element, Vector2(-54, 232), Vector2.RIGHT, 112, 48, tint, seconds)
		WeaponElementVisuals.flash(self, element, Vector2(0, 348), 32, tint, seconds)
		WeaponElementVisuals.pool(self, element, Vector2(0, 466), 32, Color(0.3, 0.85, 1, 0.65), seconds)


func _initialize() -> void:
	call_deferred("_run")


func _values(id: StringName) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	if id != &"":
		result.append({"id": str(id), "level": 1, "rarity": 1, "damage": 8.0})
	return result


func _run() -> void:
	paused = true
	var viewport := SubViewport.new()
	viewport.size = Vector2i(1536, 1180)
	viewport.render_target_update_mode = SubViewport.UPDATE_ALWAYS
	viewport.world_2d = World2D.new()
	root.add_child(viewport)
	var board := Node2D.new()
	viewport.add_child(board)
	var floor := ColorRect.new()
	floor.size = viewport.size
	floor.color = DentiUIStyle.BACKGROUND
	board.add_child(floor)
	_label(board, "Waffenelemente · Projektile und Angriffe", Vector2(26, 12), 30)
	_label(board, "Projektile in Spielgröße und dreifacher Größe · echte Spielrenderer", Vector2(26, 49), 18)
	for column in ELEMENTS.size():
		var element: StringName = ELEMENTS[column]
		_label(board, "Normal" if element == &"" else WeaponAffixes.by_id(element).display_name, Vector2(166 + column * 194, 94), 22)
	for row in 3:
		var data: WeaponData = WeaponCatalog.by_id([&"magic_toothbrush", &"water_jet", &"fluoride_rocket"][row])
		_label(board, ["Zauberpaste", "Wasserflosser", "Rakete"][row], Vector2(26, 167 + row * 112), 17)
		var pool := PlayerProjectilePool.new()
		board.add_child(pool)
		var weapons: Array[WeaponInstance] = []
		# One renderer cache per legal six-weapon loadout. The normal baseline is
		# drawn outside that prepared cache so it cannot evict a seventh style.
		for element in ELEMENTS.slice(1):
			var weapon := WeaponInstance.new()
			weapon.configure(data, 1)
			weapon.affixes = _values(element)
			weapons.append(weapon)
		pool.prepare_skins(weapons)
		for column in ELEMENTS.size():
			for zoom in 2:
				var shot := WeaponProjectile.new() if column == 0 else pool.acquire(data, 1)
				if column == 0:
					board.add_child(shot)
				shot.launch(Vector2(230 + column * 194, 153 + row * 112 + zoom * 48), Vector2.RIGHT, 10, data, null, false, 1, _values(ELEMENTS[column]))
				shot.scale = Vector2.ONE * (1.0 if zoom == 0 else 3.0)
				shots.append(shot)
		for weapon in weapons:
			weapon.free()
	for row in 5:
		_label(board, ["Strahl", "Nahkampf", "Sprühkegel", "Treffer", "Evolution"][row], Vector2(26, 535 + row * 116), 18)
	for column in ELEMENTS.size():
		var sample := EffectSample.new()
		sample.element = ELEMENTS[column]
		sample.position = Vector2(230 + column * 194, 548)
		board.add_child(sample)
		samples.append(sample)
		WeaponElementVisuals.prepare_spray(sample.element, 48)
	DirAccess.make_dir_recursive_absolute(OUTPUT)
	DirAccess.make_dir_recursive_absolute("res://.godot/weapon_element_effect_frames")
	for frame in 24:
		var seconds := float(frame) / 12.0
		for shot in shots:
			shot.animation_time = seconds
			shot._sync_visuals()
		for sample in samples:
			sample.seconds = seconds
			sample.queue_redraw()
		await process_frame
		await RenderingServer.frame_post_draw
		var captured := viewport.get_texture().get_image()
		captured.save_png("res://.godot/weapon_element_effect_frames/%02d.png" % frame)
		if frame == 4:
			captured.save_png(OUTPUT + "overview.png")
	viewport.free()
	print("PASS native element effects: actual projectiles, beams, melee, sprays, impacts and evolution pools")
	quit()


func _label(parent: Node, value: String, at: Vector2, font_size: int) -> void:
	var label := Label.new()
	label.theme = DentiUIStyle.make_theme()
	label.text = value
	label.position = at
	label.add_theme_font_size_override("font_size", font_size)
	parent.add_child(label)
