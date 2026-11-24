extends "res://tests/support/test_runtime.gd"


func _initialize() -> void:
	call_deferred("_run")


func _run() -> void:
	var ids := {}
	var item_paths := {}
	var stat_keys: Array[StringName] = DentiAttributes.KEYS
	for item in ItemCatalog.ALL:
		check(item.id != &"" and not ids.has(item.id), "duplicate/empty item ID: " + str(item.id))
		check(item.weapon_data == null and ItemCatalog.by_id(item.id) == item and ShopController.by_id(item.id) == item, "item catalog boundary broken: " + str(item.id))
		ids[item.id] = true
		item_paths[item.resource_path] = true
		for key in item.stat_changes:
			check(StringName(key) in stat_keys, "unknown item stat: " + str(key))
			check(is_finite(float(item.stat_changes[key])), "non-finite item stat: " + str(item.id))
	for filename in DirAccess.get_files_at("res://data/items"):
		if filename.ends_with(".tres"):
			check(item_paths.has("res://data/items/" + filename), "unregistered item resource: " + filename)
	for offer in ShopController.WEAPON_OFFERS:
		check(not ids.has(offer.id) and offer.weapon_data != null and not ItemCatalog.ALL.has(offer), "weapon offer included as an item: " + str(offer.id))
		check(ShopController.by_id(offer.id) == offer, "weapon offer lookup broken: " + str(offer.id))
		ids[offer.id] = true
	for weapon in WeaponCatalog.ALL:
		check(ids.has(weapon.id) and weapon.hands > 0 and weapon.hands <= PlayerStats.DEFAULT_ROOT_CAPACITY, "weapon lacks valid offer/root cost for the default player: " + str(weapon.id))
		for tier in range(1, 5):
			check(weapon.damage_at_tier(tier) > 0 and weapon.interval_at_tier(tier) > 0 and weapon.range_at_tier(tier) > 0, "invalid weapon tier values: " + str(weapon.id))
	var enemy_paths := {}
	for enemy in EnemyCatalog.ALL:
		check(not enemy_paths.has(enemy.resource_path) and EnemyCatalog.by_path(enemy.resource_path) == enemy, "enemy catalog lookup/uniqueness broken")
		enemy_paths[enemy.resource_path] = true
	for filename in DirAccess.get_files_at("res://data/enemies"):
		if filename.ends_with(".tres"):
			check(enemy_paths.has("res://data/enemies/" + filename), "unregistered enemy resource: " + filename)
	check(EnemyCatalog.by_path("res://scenes/game/game.tscn") == null, "save allowlist accepts an unrelated resource")
	print("Denti catalog boundaries and resource contracts test passed" if failures.is_empty() else str(failures))
	finish_checks()
