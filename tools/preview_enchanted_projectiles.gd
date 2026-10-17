extends SceneTree

const COMBINATIONS := [[], ["fire", "ice"], ["wet", "electric"], ["poison", "bleed"], ["fire", "ice", "poison", "electric"]]
const CAPTIONS := ["Ohne", "Feuer + Eis", "Nass + Elektro", "Gift + Blutung", "Feuer / Eis / Gift / Elektro"]

func _initialize() -> void:
	call_deferred("_run")

func _affixes(ids: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in ids:
		result.append({"id": id, "damage": 8.0})
	return result

func _label(parent: Node, message: String, at: Vector2, size: int = 18) -> void:
	var label := Label.new()
	label.text = message
	label.position = at
	label.add_theme_font_size_override("font_size", size)
	label.add_theme_color_override("font_color", Color("fff1ce"))
	label.add_theme_color_override("font_shadow_color", Color("302a3b"))
	label.add_theme_constant_override("shadow_offset_y", 2)
	parent.add_child(label)

func _run() -> void:
	AudioServer.set_bus_mute(0, true)
	paused = true
	root.size = Vector2i(1220, 880)
	root.content_scale_size = root.size
	var scene := Node2D.new()
	root.add_child(scene)
	var floor_sprite := Sprite2D.new()
	floor_sprite.texture = DentiArena.FLOOR
	floor_sprite.centered = false
	floor_sprite.scale = Vector2(root.size) / floor_sprite.texture.get_size()
	scene.add_child(floor_sprite)
	_label(scene, "DENTI · ANIMIERTE VERZAUBERUNGEN", Vector2(35, 20), 25)
	_label(scene, "Je Feld: Spielgröße oben · 3× darunter", Vector2(35, 55))
	for column in CAPTIONS.size():
		_label(scene, CAPTIONS[column], Vector2(160 + column * 210, 95), 14)
	var types: Array[WeaponData] = [WeaponCatalog.by_id(&"water_jet"), WeaponCatalog.by_id(&"magic_toothbrush"), WeaponCatalog.by_id(&"fluoride_rocket")]
	var weapons: Array[WeaponInstance] = []
	for data in types:
		for combo in COMBINATIONS:
			var weapon := WeaponInstance.new()
			weapon.configure(data, 4)
			weapon.affixes = _affixes(combo)
			weapons.append(weapon)
	var pool := PlayerProjectilePool.new()
	scene.add_child(pool)
	pool.prepare_skins(weapons)
	for row in types.size():
		_label(scene, ["Wasser", "Zauberpaste", "Rakete"][row], Vector2(30, 170 + row * 200), 19)
		for column in COMBINATIONS.size():
			for zoom in 2:
				var shot := pool.acquire(types[row], 4)
				shot.launch(Vector2(220 + column * 210, 165 + row * 200 + zoom * 75), Vector2.RIGHT, 10, types[row], null, false, 4, _affixes(COMBINATIONS[column]))
				shot.scale = Vector2.ONE * (1.0 if zoom == 0 else 3.0)
	_label(scene, "Weitere Kombination: Reichweite + Tempo + Weihe + Lebensraub", Vector2(35, 750), 19)
	for column in 8:
		var shot := pool.acquire(types[0], 4)
		shot.launch(Vector2(100 + column * 145, 820), Vector2.RIGHT.rotated(-0.5 + column * 0.15), 10, types[0], null, false, 4, _affixes(["range", "tempo", "holy", "leech"]))
		shot.scale = Vector2.ONE * 2.0
	await process_frame
	await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png("res://docs/screenshots/enchanted_projectiles.png")
	DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path("res://.godot/enchantment_frames"))
	for frame in ProjectileParticleFrames.COUNT:
		for shot: WeaponProjectile in pool.get_children():
			shot.animation_time = float(frame) / ProjectileParticleFrames.FPS
			shot._sync_visuals()
		await process_frame
		await RenderingServer.frame_post_draw
		root.get_texture().get_image().save_png("res://.godot/enchantment_frames/frame_%02d.png" % frame)
	scene.free()
	for weapon in weapons:
		weapon.free()
	await _benchmark(types[0])
	quit()

func _benchmark(data: WeaponData) -> void:
	var pool := PlayerProjectilePool.new()
	root.add_child(pool)
	var variants: Array[WeaponInstance] = []
	for ids in [[], ["fire"], ["ice"], ["fire", "ice"], ["poison", "electric"], ["fire", "ice", "poison", "electric"]]:
		var weapon := WeaponInstance.new()
		weapon.configure(data, 4)
		weapon.affixes = _affixes(ids)
		variants.append(weapon)
	pool.prepare_skins(variants)
	var baked := pool.skins.composed_total
	var uploaded := pool.skins.uploads_total
	for index in 200:
		var weapon := variants[index % variants.size()]
		var shot := pool.acquire(data, 4)
		shot.launch(Vector2(50 + index % 20 * 58, 40 + index / 20 * 80), Vector2.RIGHT, 10, data, null, false, 4, weapon.affixes)
	for frame in 8:
		for shot: WeaponProjectile in pool.get_children():
			shot.animation_time = float(frame) / ProjectileParticleFrames.FPS
			shot._sync_visuals()
		await process_frame
		await RenderingServer.frame_post_draw
	print("200 mixed shots / plain + 5 combinations: sprites=", pool.get_child_count(), ", draw_calls=", RenderingServer.get_rendering_info(RenderingServer.RENDERING_INFO_TOTAL_DRAW_CALLS_IN_FRAME), ", extra_compositions=", pool.skins.composed_total - baked, ", extra_uploads=", pool.skins.uploads_total - uploaded, ", pages=", pool.skins.pages.size())
	pool.free()
	for weapon in variants:
		weapon.free()
