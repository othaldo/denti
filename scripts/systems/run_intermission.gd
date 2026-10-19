class_name RunIntermission
extends RefCounted


static func restore(game, saved: Dictionary) -> void:
	var wave: WaveController = game.wave
	var player: Player = game.player
	var shop: ShopController = game.shop
	var upgrade_data: Array = saved.get("upgrades", [])
	if not saved.has("rewards"):
		if game.in_shop:
			game.rewards.step = PostWaveRewards.Step.SHOP
		elif upgrade_data.size() in [3, ChoicePanel.UPGRADE_COUNT]:
			game.rewards.pending_levels = 1
			game.rewards.step = PostWaveRewards.Step.COMBAT if wave.active or game.boss_pending else PostWaveRewards.Step.LEVELS
		elif bool(saved.get("intermission_pending", false)):
			game.rewards.step = PostWaveRewards.Step.SHOP
	if bool(saved.get("collecting_wave_loot", false)):
		game._begin_loot_collection()
		return
	if game.starter_pending:
		game.get_node("/root/SceneTransitions").present(&"starter")
		game.run_flow.enter(RunFlow.Phase.STARTER)
		game.choice_panel.show_starters(WeaponCatalog.STARTERS)
		game.get_tree().paused = true
		game._refresh_hud()
		return
	if game.story.enabled and game.story.travel_target >= 1:
		game._show_story_travel()
		return
	if game.story.enabled and game.story.dialogue_id != &"":
		game._show_story_line()
		return
	if game.rewards.step == PostWaveRewards.Step.LEVELS and upgrade_data.size() in [3, ChoicePanel.UPGRADE_COUNT]:
		var options: Array[UpgradeData] = []
		for value in upgrade_data:
			if value is Dictionary:
				value = value.duplicate()
				# Choices in older saves used absolute movement and cooldown stats.
				if str(value.get("stat", "")) == "move_speed":
					value["stat"] = "speed_bonus"
				elif str(value.get("stat", "")) == "attack_interval":
					value["stat"] = "attack_speed"
				elif str(value.get("stat", "")) == "damage":
					value["stat"] = "damage_bonus"
			var resource_path := str(value.get("resource", "")) if value is Dictionary else ""
			for upgrade in game.UPGRADES:
				if value is Dictionary and (upgrade.resource_path == resource_path if resource_path != "" else str(upgrade.stat) == str(value.get("stat", ""))):
					options.append(upgrade.with_tier(int(value.get("tier", 1))))
					break
				if value is String and upgrade.resource_path == value:
					options.append(upgrade.with_tier(1))
					break
		if options.size() == upgrade_data.size():
			for option in options:
				option.with_stat_context(player.stats)
			game.get_node("/root/SceneTransitions").present(&"rewards")
			game.run_flow.enter(RunFlow.Phase.REWARDS)
			game.choice_panel.show_upgrades(options)
			game._update_level_reroll()
			game.get_tree().paused = true
		else:
			game._advance_post_wave_rewards()
	elif game.rewards.step == PostWaveRewards.Step.CHESTS or game.rewards.step == PostWaveRewards.Step.RELICS or game.rewards.step == PostWaveRewards.Step.STORY:
		game._advance_post_wave_rewards()
	elif game.rewards.step == PostWaveRewards.Step.LEVELS:
		game._advance_post_wave_rewards()
	elif game.in_shop or game.rewards.step == PostWaveRewards.Step.SHOP:
		game.get_node("/root/SceneTransitions").present(&"shop")
		if shop.offers.size() != ShopController.OFFER_COUNT:
			shop.complete_saved_offers(wave.current_wave, player.stats.luck, player.loadout, game.items)
		game.in_shop = true
		game._update_shop_panel()
		game.get_tree().paused = true
	game._refresh_hud()


static func capture_choices(panel: ChoicePanel) -> Array[Dictionary]:
	var upgrades: Array[Dictionary] = []
	if panel.visible and panel.mode == &"upgrade":
		for upgrade in panel.current_upgrades:
			# Save the actual offer identity. Several upgrades may eventually affect
			# the same stat while carrying different effects or scaling.
			upgrades.append({"resource": upgrade.resource_path, "stat": str(upgrade.stat), "tier": upgrade.tier})
	return upgrades
