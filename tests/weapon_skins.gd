extends "res://tests/support/test_runtime.gd"

var game: Node2D
var failures: Array[String] = []


func _initialize() -> void:
	call_deferred("_run")


func check(ok: bool, message: String) -> void:
	if not ok:
		failures.append(message)
		push_error(message)


func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_weapon_skins.json"
	session.progression_path = "user://test_weapon_skins.cfg"
	session.clear_run()
	game = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	choose_panel(game.choice_panel, 0)
	game.wave.active = false
	paused = true
	var catalog: Array[WeaponData] = WeaponCatalog.ALL.duplicate()
	for recipe in WeaponEvolutions.ALL:
		catalog.append(recipe.result)
	var loadout: WeaponLoadout = game.player.loadout
	var rigs: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://data/weapon_skins/rigs.json"))
	for data in catalog:
		var normal := data.sprite
		check(normal is AtlasTexture and normal.atlas.resource_path.ends_with("/%s/normal.png" % data.id), "%s: old normal art" % data.id)
		check(data.held_texture().get_size() == Vector2(512, 512), "%s: unbounded runtime texture" % data.id)
		check(data.held_texture().get_image().has_mipmaps(), "%s: missing combat-scale mipmaps" % data.id)
		# The earlier art's visible size is the reference, rather than its canvas.
		var normal_image: Image = data.sprite.atlas.get_image()
		var bounds := _paint_bounds(normal_image)
		var visible_size := maxf(bounds.size.x, bounds.size.y) * WeaponMotion.base_scale(data)
		check(absf(visible_size - float(rigs[str(data.id)].combat_visible_size)) < 0.02, "%s: painted size drifted from the approved Denti proportions" % data.id)
		for id in [&"fire", &"ice", &"poison", &"electric", &"bleed", &"wet"]:
			var values := WeaponUpgrades.advance([], id, data, 4)
			loadout.restore([{"id": str(data.id), "tier": 4, "affixes": values}], false)
			var weapon := loadout.equipped()[0]
			check(weapon.data.element_skin == id, "%s: element identity lost" % data.id)
			check(weapon.data.sprite.atlas.resource_path.ends_with("/%s/%s.png" % [data.id, id]), "%s: wrong element texture" % data.id)
			check(weapon.sprite.texture == weapon.data.held_texture(), "%s: equipped sprite stale" % data.id)
			check(is_equal_approx(weapon.data.base_damage, data.base_damage) and is_equal_approx(weapon.data.interval, data.interval), "%s: painting changed combat values" % data.id)
			check(data.sprite == normal and data.element_skin == &"", "%s: shared catalog mutated" % data.id)
			check(is_equal_approx(WeaponMotion.base_scale(weapon.data), WeaponMotion.base_scale(data)), "%s: element changed the weapon's body scale" % data.id)
			if weapon.working_head != null:
				check(weapon.working_head.face.texture.resource_path.ends_with("/%s_head.png" % id), "%s: old rotating head" % data.id)
			if weapon.elastic != null:
				check(weapon.elastic.pouch.texture.resource_path.ends_with("/%s_pouch.png" % id), "%s: old sling pouch" % data.id)
			var saved := loadout.save_data()
			loadout.restore(saved, false)
			check(loadout.equipped()[0].data.element_skin == id, "%s: resume lost appearance" % data.id)
		var supports := WeaponUpgrades.advance([], &"tempo", data, 4)
		check(WeaponRolls.with_affixes(data, supports).sprite == normal, "%s: support changes the element" % data.id)
	# An in-place upgrade updates this weapon immediately, including the UI model.
	loadout.restore([{"id": "cavity_grinder", "tier": 4}, {"id": "cavity_grinder", "tier": 4}], false)
	var selected := loadout.equipped()[0]
	var state := WeaponUpgradeState.new()
	state.points = 2
	check(state.plan(loadout, selected.instance_uid, &"fire"), "cannot plan skin change")
	var models := WeaponUpgradePresentation.equipment(state, loadout, game.player.stats, game.items)
	check(models[0].data.element_skin == &"fire" and models[1].data.element_skin == &"", "draft painting leaks to another weapon")
	state.undo()
	check(WeaponUpgradePresentation.equipment(state, loadout, game.player.stats, game.items)[0].data.element_skin == &"", "undo retains draft painting")
	state.plan(loadout, selected.instance_uid, &"fire")
	check(state.commit(loadout), "cannot commit skin change")
	check(selected.data.element_skin == &"fire" and selected.sprite.texture == selected.data.held_texture(), "commit did not refresh held art")
	check(loadout.equipped()[1].data.element_skin == &"", "commit repainted a second weapon")
	check(loadout.merge(0) == false, "tier IV fusion changed")
	# Normal fusion preserves an existing element and its in-place sprite.
	loadout.restore([{"id": "turbo_drill", "tier": 1, "affixes": [{"id": "ice", "level": 1, "damage": 1}]}, {"id": "turbo_drill", "tier": 1}])
	check(loadout.merge(0) and loadout.equipped()[0].data.element_skin == &"ice", "fusion lost elemental appearance")
	check(loadout.equipped()[0].sprite.texture == loadout.equipped()[0].data.held_texture(), "fusion left the held texture stale")
	# Historic Mk capsules and mixed-element saves still use the same appearance.
	loadout.restore([{"id": "magic_toothbrush", "tier": 4, "affixes": [{"id": "fire", "level": 3, "damage": 1}]}])
	selected = loadout.equipped()[0]
	check(WeaponAffixes.apply(selected, {"id": "mk"}) and selected.data.element_skin == &"fire", "legacy Mk capsule lost the skin")
	var mixed: Array[Dictionary] = [{"id": "ice", "rarity": 1, "rank": 1, "damage": 3}, {"id": "fire", "rarity": 4, "rank": 3, "damage": 35}]
	check(WeaponRolls.with_affixes(WeaponCatalog.ALL[0], mixed).element_skin == &"fire", "legacy strongest-element identity disagrees with its painting")
	for recipe in WeaponEvolutions.ALL:
		loadout.restore([])
		game.items.restore({})
		loadout.acquire(WeaponCatalog.by_id(recipe.base_weapon), 4)
		if recipe.partner_weapon != &"":
			loadout.acquire(WeaponCatalog.by_id(recipe.partner_weapon), 4)
		for family in recipe.families:
			for item in ShopController.CATALOG:
				if item.family_id == family and item.rarity_tier == 4:
					game.items.acquire(item)
					break
		for id in recipe.items:
			game.items.acquire(ShopController.by_id(id))
		selected = loadout.equipped()[0]
		selected.affixes = WeaponUpgrades.advance([], &"electric", selected.data, 4)
		selected.refresh_affix_stats()
		check(loadout.evolve(0, recipe, game.items), "%s: cannot evolve enchanted ingredient" % recipe.id)
		var evolved := loadout.equipped()[0]
		check(evolved.data.element_skin == &"electric" and evolved.data.sprite.atlas.resource_path.ends_with("/%s/electric.png" % recipe.result.id), "%s: evolution uses ingredient painting" % recipe.id)
	check(WeaponSkins._skins.size() <= WeaponSkins.CACHE_LIMIT, "skin cache grows across runs")
	session.clear_run()
	DirAccess.remove_absolute(ProjectSettings.globalize_path(session.progression_path))
	paused = false
	if failures.is_empty():
		print("PASS weapon_skins: 24 weapons, 168 forms, live rigs, drafts, isolation, fusion and resume")
	finish(0 if failures.is_empty() else 1)


func _paint_bounds(image: Image) -> Rect2i:
	var left := image.get_width()
	var top := image.get_height()
	var right := 0
	var bottom := 0
	for y in image.get_height():
		for x in image.get_width():
			if image.get_pixel(x, y).a < 16.0 / 255.0: continue
			left = mini(left, x)
			top = mini(top, y)
			right = maxi(right, x + 1)
			bottom = maxi(bottom, y + 1)
	return Rect2i(left, top, right - left, bottom - top)
