extends SceneTree

var failures: Array[String] = []

func _initialize() -> void:
	call_deferred("_run")

func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var session: Node = root.get_node("GameSession")
	session.save_path = "user://test_item_families.json"
	session.resume_requested = false
	session.clear_run()
	var game: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(game)
	current_scene = game
	game.choice_panel.buttons[0].pressed.emit()
	game.wave.active = false
	paused = true
	var families: Dictionary = {}
	var ids: Dictionary = {}
	var mythics: Array[ShopOfferData] = []
	var new_cells: Array[int] = []
	var count := 0
	for item in ShopController.CATALOG:
		_check(not ids.has(item.id), "duplicate item/weapon ID: " + str(item.id))
		ids[item.id] = true
		if item.weapon_data != null:
			continue
		count += 1
		if item.family_id != &"":
			if not families.has(item.family_id):
				families[item.family_id] = []
			families[item.family_id].append(item)
		if item.rarity_tier == 5:
			mythics.append(item)
			_check(item.max_stacks == 1 and item.effect_kind == &"" and item.stat_changes.size() == 1, "mythic is not a unique pure bonus")
			for value in item.stat_changes.values():
				_check(float(value) > 0.0, "mythic has a downside")
		var icon: Texture2D = item.icon_texture if item.icon_texture != null else DentiUIIcons.item(item.icon_index)
		_check(icon != null and icon.get_width() > 0, "missing icon: " + str(item.id))
		if item.icon_index >= 30:
			_check(not new_cells.has(item.icon_index), "new items share an icon cell")
			new_cells.append(item.icon_index)
			var atlas := icon as AtlasTexture
			var expected_sheet := "item_icons_mythic_packed.png" if item.icon_index >= 78 else "item_icons_families_%d_packed.png" % (1 + (item.icon_index - 30) / 16)
			if item.icon_index >= 86:
				expected_sheet = "item_icons_dodge_packed.png"
			_check(atlas != null and atlas.atlas.resource_path.ends_with(expected_sheet) and atlas.region.size == Vector2(512, 512), "item selects the wrong padded atlas cell")
	_check(count == 93 and families.size() == 17 and mythics.size() == 9, "incomplete 93-item expansion")
	new_cells.sort()
	_check(new_cells.size() == 61 and new_cells[0] == 30 and new_cells[60] == 90, "new icon indices have gaps")
	for family_id in families:
		var tiers: Array[int] = []
		var cap: int = families[family_id][0].family_limit
		for item: ShopOfferData in families[family_id]:
			tiers.append(item.rarity_tier)
			_check(item.family_limit == cap, "variants have inconsistent shared limits")
		tiers.sort()
		_check(tiers == [1, 2, 3, 4], "family lacks one of four rarities: " + str(family_id))
	# Mixed tiers share the limit, but every acquired tier keeps its own effects.
	for id in [&"health_1", &"health_2", &"ceramic_shell"]:
		_check(game.items.acquire(ShopController.by_id(id)), "could not mix health tiers")
	_check(game.player.stats.max_health == 171.0 and game.player.stats.regen == 1.0, "variant stat effects differ from their cards")
	_check(game.items.acquire(ShopController.by_id(&"health_4")), "early health items blocked legendary upgrade")
	for copy in 8:
		_check(game.items.acquire(ShopController.by_id(&"health_1")), "could not build twelve mixed health stacks")
	_check(not game.items.acquire(ShopController.by_id(&"health_4")), "rarity variants bypass twelve-item family cap")
	_check(game.items.family_count(&"health") == 12, "family count lost mixed tiers")
	game.shop.offers.clear()
	for draw in 200:
		var offer: ShopOfferData = game.shop._pick_item(4, game.items, game.player.loadout)
		_check(offer != null and offer.family_id != &"health", "maxed family remained in shop pool")
	var before: float = game.player.stats.max_health
	var mythic := ShopController.by_id(&"mythic_heart")
	_check(game.items.acquire(mythic) and game.player.stats.max_health == before + 60.0, "mythic pure bonus was not applied")
	_check(not game.items.acquire(mythic), "mythic could be bought twice")
	_check(DentiRarity.name_for(5) == "Mythisch" and DentiRarity.color_for(5) != DentiRarity.color_for(4), "mythic badge aliases legendary")
	_check(DentiRarity.cumulative_chance(5, 11, 10000.0) == 0.0, "mythic appeared before wave 12")
	_check(DentiRarity.cumulative_chance(5, 100, 10000.0) <= 0.01, "luck bypassed mythic cap")
	var pending := PostWaveRewards.new()
	pending.queue_chest(&"mythic_crit", 23)
	var restored_rewards := PostWaveRewards.new()
	restored_rewards.restore(pending.save_data())
	_check(restored_rewards.step == PostWaveRewards.Step.COMBAT and restored_rewards.current_chest().get("item_id") == "mythic_crit", "pending mythic chest was lost or interrupted combat on resume")
	var rng := RandomNumberGenerator.new()
	var mythic_seed := -1
	for value in 10000:
		rng.seed = value
		if rng.randf() < DentiRarity.cumulative_chance(5, 20, 10000.0):
			mythic_seed = value
			break
	_check(mythic_seed >= 0, "test could not find a mythic roll")
	rng.seed = mythic_seed
	var chest := ChestRewards.roll_item(20, 10000.0, game.items, rng)
	var chest_item := ShopController.by_id(StringName(chest.get("item_id", "")))
	_check(chest_item != null and chest_item.rarity_tier == 5 and chest_item.id != mythic.id, "chest cannot roll an unowned mythic")
	for item in mythics:
		if item.id != mythic.id:
			_check(game.items.acquire(item), "could not acquire another unique mythic")
	rng.seed = mythic_seed
	chest = ChestRewards.roll_item(20, 10000.0, game.items, rng)
	chest_item = ShopController.by_id(StringName(chest.get("item_id", "")))
	_check(chest_item != null and chest_item.rarity_tier < 5, "exhausted mythic pool did not fall back")
	for draw in 5000:
		_check(DentiRarity.roll(30, 10000.0, rng) <= 4, "weapons/level-ups rolled mythic")
	# Saving uses stable resource IDs and does not reapply stat changes on restore.
	game._open_shop()
	game.shop.offers[0] = ShopController.by_id(&"return_4").duplicate()
	game.shop.offers[1] = mythic.duplicate()
	game.shop.reserved[1] = true
	game.shop.take_offer(2)
	# Existing crown builds retain their power and can now buy later variants.
	game.items.owned["metal_crown"] = 8
	game._update_shop_panel()
	game._save_run()
	session.resume_requested = true
	var resumed: Node2D = load("res://scenes/game/game.tscn").instantiate()
	root.add_child(resumed)
	current_scene = resumed
	_check(resumed.items.family_count(&"health") == 12 and not resumed.items.can_acquire(ShopController.by_id(&"health_4")), "resume lost family limit")
	_check(resumed.items.count(&"metal_crown") == 8 and resumed.items.can_acquire(ShopController.by_id(&"armor_4")), "saved crowns were removed or still blocked upgraded armor")
	_check(resumed.items.count(mythic.id) == 1 and resumed.player.stats.max_health == before + 60.0, "resume lost or reapplied mythic bonus")
	_check(resumed.shop.offers[1].rarity_tier == 5 and resumed.shop.reserved[1], "resume lost mythic offer/reservation")
	_check(resumed.shop.offers[2] == null, "resume refilled a sold slot for free")
	resumed.coins = 1000
	resumed._on_shop_reroll()
	_check(resumed.shop.offers[2] != null and resumed.shop_panel.offer_buttons[2].content.visible and resumed.shop_panel.offer_buttons[2].text != "Ausverkauft", "reroll left sold card visible")
	paused = false
	session.clear_run()
	if failures.is_empty():
		print("Denti item families test passed")
	quit(0 if failures.is_empty() else 1)
