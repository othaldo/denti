extends "res://tests/support/test_runtime.gd"

var failures := 0
const MAGIC: WeaponData = preload("res://data/weapons/magic_toothbrush.tres")
const ROCKET: WeaponData = preload("res://data/weapons/fluoride_rocket.tres")

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures += 1
		push_error(message)

func _values(ids: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for id in ids:
		result.append({"id": id, "damage": 8.0, "rarity": 2})
	return result

func _run() -> void:
	_check_images_and_bounds()
	_check_live_pool()
	if failures == 0:
		print("Animated enchantments: combined effects, shared atlas, bounded cache, pooling, preparation and save/resume passed")
	finish(0 if failures == 0 else 1)

func _check_images_and_bounds() -> void:
	var cache := ProjectileEnchantmentSkins.new()
	var base := ProjectileEnchantmentSkins.base_texture(MAGIC, 1)
	var base_data := base.get_image().get_data()
	var indices: Array[int] = []
	for definition in WeaponAffixes.ALL:
		var index := definition.projectile_effect_index
		_check(index >= 0 and not indices.has(index), "enchantment has no unique particle effect")
		indices.append(index)
		var changed := false
		for frame in ProjectileParticleFrames.COUNT:
			changed = changed or cache.compose(base, 1 << index, 7, frame).get_data() != base_data
		_check(changed, "particle effect was hidden/omitted: " + str(definition.id))
	var values := _values(["fire", "ice", "poison", "electric"])
	var bits := ProjectileEnchantmentSkins.mask(values)
	var reverse := values.duplicate(true)
	reverse.reverse()
	reverse[0].damage = 9999
	reverse[0].rarity = 4
	_check(bits == ProjectileEnchantmentSkins.mask(reverse), "order/strength needlessly creates a new visual combination")
	_check(cache.compose(base, bits, 7, 0).get_data() != cache.compose(base, bits, 7, 4).get_data(), "particle frames do not animate")
	for value in values:
		var removed := bits & ~(1 << WeaponAffixes.by_id(StringName(value.id)).projectile_effect_index)
		var contributed := false
		for frame in ProjectileParticleFrames.COUNT:
			contributed = contributed or cache.compose(base, bits, 7, frame).get_data() != cache.compose(base, removed, 7, frame).get_data()
		_check(contributed, "four-effect combination hides an enchantment: " + str(value.id))
	var weapons: Array[WeaponInstance] = []
	for index in 6:
		var weapon := WeaponInstance.new()
		weapon.configure(ROCKET, 4)
		weapon.affixes = _values([str(WeaponAffixes.ALL[index].id)])
		weapons.append(weapon)
	cache.prepare(weapons)
	_check(cache.entries.size() == 6 and cache.pages.size() == 1 and cache.uploads_total == 1, "six largest equipped styles were not packed/uploaded together")
	var old_frames := cache.frames(ProjectileEnchantmentSkins.base_texture(ROCKET, 4), ProjectileEnchantmentSkins.mask(weapons[0].affixes), 13)
	var old_atlas := (old_frames[0] as AtlasTexture).atlas
	for weapon in weapons:
		var frames := cache.frames(ProjectileEnchantmentSkins.base_texture(ROCKET, 4), ProjectileEnchantmentSkins.mask(weapon.affixes), 13)
		_check(frames.size() == ProjectileParticleFrames.COUNT, "equipped style lost animation frames")
		for texture in frames:
			_check((texture as AtlasTexture).atlas == old_atlas, "animation changes texture page and breaks batching")
	var count := cache.composed_total
	cache.prepare(weapons)
	_check(cache.composed_total == count and cache.uploads_total == 1, "unchanged equipment regenerated/reuploaded particle frames")
	for definition in WeaponAffixes.ALL:
		cache.frames(base, 1 << definition.projectile_effect_index, 7)
		_check(cache.entries.size() <= cache.MAX_STYLES and cache.pages.size() <= cache.MAX_PAGES, "skin cache exceeds its memory bound")
	_check((old_frames[0] as AtlasTexture).atlas == old_atlas and old_atlas.get_size() == Vector2(cache.PAGE_SIZE), "eviction overwrote an old in-flight atlas")
	for weapon in weapons:
		weapon.free()

func _check_live_pool() -> void:
	var session := root.get_node("GameSession")
	session.save_path = "user://test_projectile_skins.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	paused = true
	game.wave.active = false
	game.player.loadout.restore([
		{"id": "magic_toothbrush", "tier": 1, "affix_slots": 4, "affixes": _values(["fire", "ice"])},
		{"id": "magic_toothbrush", "tier": 1, "affix_slots": 4, "affixes": _values(["wet", "electric"])},
		{"id": "water_jet", "tier": 1}])
	var weapons: Array[WeaponInstance] = game.player.loadout.equipped()
	var pool: PlayerProjectilePool = game.get_node("Projectiles")
	pool.prepare_loadout(weapons)
	var baked := pool.skins.composed_total
	var uploaded := pool.skins.uploads_total
	var created := pool.created
	var undecorated := _shoot(pool, weapons[2])
	var enchanted := _shoot(pool, weapons[0])
	_check((undecorated.body_sprite.texture as AtlasTexture).atlas == (enchanted.body_sprite.texture as AtlasTexture).atlas, "mixing plain and enchanted equipment breaks texture batching")
	undecorated.retire()
	enchanted.retire()
	for cycle in 100:
		var weapon := weapons[cycle % 2]
		var shot := _shoot(pool, weapon)
		for frame in ProjectileParticleFrames.COUNT:
			shot.animation_time = float(frame) / ProjectileParticleFrames.FPS
			shot._sync_visuals()
			_check(shot.get_child_count() == 1, "enchantments added child effect nodes")
		shot.retire()
	_check(pool.skins.composed_total == baked and pool.skins.uploads_total == uploaded and pool.created == created, "prepared salvos generated images/uploads/nodes during combat")
	var old := _shoot(pool, weapons[0])
	var old_frames := old.visual_frames
	var old_texture := old.body_sprite.texture
	_check(WeaponAffixes.apply(weapons[0], {"id": "poison", "rarity": 2, "damage": 8.0}), "fixture could not add its new enchantment")
	_check(old.visual_frames == old_frames and old.body_sprite.texture == old_texture and old.affixes.size() == 2, "equipment change altered an in-flight projectile")
	var new_shot := _shoot(pool, weapons[0])
	_check(new_shot.visual_frames != old_frames and new_shot.affixes.size() == 3, "new shot reused its previous owner's enchantment look")
	var saved := RunSnapshot.capture(game)
	_check(JSON.stringify(saved).find("visual_frames") == -1, "save serialized derived textures")
	old.retire()
	_check(old.visual_frames.is_empty(), "retired old-generation shot pins an obsolete atlas")
	var plain := pool.acquire(weapons[0].data, 1)
	plain.launch(Vector2(400, 300), Vector2.RIGHT, 10, weapons[0].data)
	_check(plain.visual_frames.size() == 1 and plain.affixes.is_empty() and plain.get_child_count() == 1, "plain recycled projectile retained enchantment graphics")
	plain.retire()
	game.free()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	RunSnapshot.restore(game, saved)
	pool = game.get_node("Projectiles")
	_check(pool.get_child_count() == 2, "resume lost mixed old/new enchanted projectiles")
	for index in pool.get_child_count():
		var shot: WeaponProjectile = pool.get_child(index)
		_check(shot.affixes.size() == saved.player_projectiles[index].affixes.size() and shot.visual_frames.size() == ProjectileParticleFrames.COUNT and shot.get_child_count() == 1, "resume lost enchantments or single-sprite animation")
	baked = pool.skins.composed_total
	uploaded = pool.skins.uploads_total
	for weapon in game.player.loadout.equipped():
		_shoot(pool, weapon).retire()
	_check(pool.skins.composed_total == baked and pool.skins.uploads_total == uploaded, "first resumed attacks regenerate equipped particle graphics")
	session.clear_run()
	game.free()
	paused = false

func _shoot(pool: PlayerProjectilePool, weapon: WeaponInstance) -> WeaponProjectile:
	var shot := pool.acquire(weapon.data, weapon.tier)
	shot.launch(Vector2(400, 300), Vector2.RIGHT, 10, weapon.data, null, false, weapon.tier, weapon.affixes)
	return shot
