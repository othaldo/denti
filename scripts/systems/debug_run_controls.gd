class_name DebugRunControls
extends RefCounted

var game: Node2D


static func allowed(debug_build: bool = OS.is_debug_build(), web_build: bool = OS.has_feature("web"), platform: String = OS.get_name()) -> bool:
	return debug_build and not web_build and platform in ["Windows", "Linux", "macOS"]


func _init(run: Node2D) -> void:
	game = run


func add_weapon(id: StringName, tier: int) -> bool:
	var data := WeaponCatalog.by_id(id)
	if not allowed() or data == null or game.player.loadout.used_slots() + data.hands > WeaponLoadout.CAPACITY:
		return false
	game.player.loadout.acquire(data, clampi(tier, 1, WeaponLoadout.MAX_TIER), 0)
	changed()
	return true


func remove_weapon(index: int) -> void:
	if not allowed():
		return
	game.player.loadout.sell(index)
	changed()


func set_weapon_tier(index: int, tier: int) -> void:
	if not allowed():
		return
	var weapons: Array[WeaponInstance] = game.player.loadout.equipped()
	if index >= 0 and index < weapons.size():
		weapons[index].tier = clampi(tier, 1, WeaponLoadout.MAX_TIER)
		changed()


func add_item(id: StringName, copies: int) -> int:
	var item := ShopController.by_id(id)
	if not allowed() or item == null or item.weapon_data != null:
		return 0
	var added := 0
	var limit := item.max_stacks if item.max_stacks > 0 else 99
	for _copy in clampi(copies, 0, maxi(limit - game.items.count(id), 0)):
		if not game.items.acquire(item):
			break
		added += 1
	changed()
	return added


func set_coins(value: int) -> void:
	if allowed():
		game.coins = maxi(value, 0)
		changed()


func set_stats(values: Dictionary) -> void:
	if allowed():
		var saved: Dictionary = game.player.stats.to_save_data()
		for key in values:
			if saved.has(key):
				saved[key] = values[key]
		game.player.stats.load_save_data(saved)
		changed()


func start_wave(number: int) -> bool:
	if not allowed() or game.player.loadout.equipped().is_empty():
		return false
	game.debug_start_wave(clampi(number, 1, WaveController.MAX_WAVES))
	return true


func changed() -> void:
	if game.in_shop:
		game._update_shop_panel()
	game._refresh_hud()
	game._save_run()
