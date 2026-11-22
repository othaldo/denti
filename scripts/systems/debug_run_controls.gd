class_name DebugRunControls
extends RefCounted

var game: Node2D
## Weapons the last class switch removed because the new class cannot wield them.
var removed_weapons: Array[String] = []


static func allowed(debug_build: bool = OS.is_debug_build(), web_build: bool = OS.has_feature("web"), platform: String = OS.get_name()) -> bool:
	return debug_build and not web_build and platform in ["Windows", "Linux", "macOS"]


func _init(run: Node2D) -> void:
	game = run


func add_weapon(id: StringName, tier: int) -> bool:
	var data := WeaponCatalog.by_id(id)
	if not allowed() or data == null or game.player.loadout.used_slots() + data.hands > game.player.loadout.capacity:
		return false
	if not game.player.loadout.acquire(data, clampi(tier, 1, WeaponLoadout.MAX_TIER), 0):
		return false
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
		weapons[index].refresh_affix_stats()
		changed()


func add_item(id: StringName, copies: int) -> int:
	var item := ItemCatalog.by_id(id)
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


## Grants or removes a relic, including class relics of other classes.
## Returns whether the relic is owned afterwards.
func toggle_relic(id: StringName) -> bool:
	if not allowed() or RelicCatalog.by_id(id) == null:
		return false
	if game.relics.has_relic(id):
		game.relics.owned.erase(str(id))
	else:
		game.relics.acquire(id)
	changed()
	return game.relics.has_relic(id)


## Switches the class mid-run. Earned stats, weapons and items stay; class
## starting offsets, roots, dash, skill state and talent ranks follow the new
## class. Ranks of the old tree are dropped because they are invalid in the
## new tree; their points stay spent. Weapons the new class cannot wield are
## removed without refund (listed in removed_weapons), since such a run could
## not be resumed. Returns "" or the reason it is blocked.
func set_class(id: StringName) -> String:
	var profile := ClassCatalog.by_id(id)
	if not allowed() or profile == null:
		return "Unbekannte Klasse"
	if profile == game.player.stats.class_data:
		return "Bereits aktiv"
	if game.starter_pending:
		return "Erst Startwaffe wählen"
	if game.rewards.step == PostWaveRewards.Step.LEVELS:
		return "Erst Aufstieg abschließen"
	var player: Player = game.player
	if not player.stats.switch_class(profile):
		return "Klasse ungültig"
	removed_weapons.clear()
	var equipped: Array[WeaponInstance] = player.loadout.equipped()
	for index in range(equipped.size() - 1, -1, -1):
		if not player.loadout.weapon_allowed(equipped[index].data):
			removed_weapons.append(WeaponPresentation.weapon_name(equipped[index]))
			player.loadout.sell(index)
	if profile.exclusive_weapon_id != &"" and player.loadout.equipped().is_empty():
		player.loadout.acquire(WeaponCatalog.by_id(profile.exclusive_weapon_id), 1, 0)
	player.dash.config = profile.dash_config()
	player.dash.charge = minf(player.dash.charge, player.dash.capacity)
	game.talents.enabled = profile.talent_tree != null
	game.talents.ranks.clear()
	game.talents.bound.clear()
	game.talents.actions.clear()
	game.talents.tiers.clear()
	game.talents.cursor.clear()
	player.reset_skill_modules()
	player.class_combat.reset_wave()
	game._sync_talents()
	changed()
	return ""


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


func start_wave(number: int, difficulty: StringName = &"") -> bool:
	if not allowed() or game.player.loadout.equipped().is_empty():
		return false
	if difficulty != &"":
		game.wave.difficulty_id = DifficultyCatalog.by_id(difficulty).id
		game.session.selected_difficulty_id = game.wave.difficulty_id
	game.debug_start_wave(clampi(number, 1, WaveController.MAX_WAVES))
	return true


func changed() -> void:
	game.weapon_mastery.eligible = false
	if game.weapon_enchantment_panel.visible:
		game.rewards.weapon_upgrades.validate(game.player.loadout)
		game.weapon_enchantment_panel.refresh()
	if game.in_shop:
		game._update_shop_panel()
	game._refresh_hud()
	game._save_run()
