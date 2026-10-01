extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const LOOT_SCENE: PackedScene = preload("res://scenes/game/loot.tscn")
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/ui/damage_number.tscn")
const RUN_SNAPSHOT: Script = preload("res://scripts/systems/run_snapshot.gd")
const SPAWN_PADDING := 32.0
const MAX_ACTIVE_ENEMIES := 110
const UPGRADES: Array[UpgradeData] = [
	preload("res://data/upgrades/bisskraft.tres"),
	preload("res://data/upgrades/nahschaden.tres"),
	preload("res://data/upgrades/fernschaden.tres"),
	preload("res://data/upgrades/haerte.tres"),
	preload("res://data/upgrades/schmelz.tres"),
	preload("res://data/upgrades/putzeifer.tres"),
	preload("res://data/upgrades/bewegung.tres"),
	preload("res://data/upgrades/speichel.tres"),
	preload("res://data/upgrades/glanz.tres"),
	preload("res://data/upgrades/zahnglueck.tres"),
]

@onready var player: Player = $Player
@onready var arena: DentiArena = $Arena
@onready var wave: WaveController = $WaveController
@onready var shop: ShopController = $ShopController
@onready var items: ItemInventory = $Items
@onready var relics: RelicInventory = $Relics
@onready var music: MusicController = $Music
@onready var sound: SoundController = $Sound
@onready var hud: GameHUD = $HUD
@onready var mobile_controls: MobileControls = $MobileControls/Root
@onready var choice_panel: ChoicePanel = $ChoicePanel
@onready var shop_panel: ShopPanel = $ShopPanel
@onready var game_menu: GameMenu = $GameMenu
@onready var session: Node = get_node("/root/GameSession")

var xp: int = 0
var xp_goal: int = 5
var level: int = 1
var coins: int = 0
var ended: bool = false
var in_shop: bool = false
var starter_pending: bool = false
var boss: Enemy
var boss_pending: bool = false
var collecting_wave_loot: bool = false
var wave_loot_remaining: int = 0
var autosave_timer: float = 0.0
var camera_shake_time: float = 0.0
var telemetry := RunTelemetry.new()
var rewards := PostWaveRewards.new()


func _ready() -> void:
	randomize()
	wave.difficulty_id = session.selected_difficulty_id
	wave.enemy_requested.connect(_spawn_enemy)
	wave.boss_requested.connect(_spawn_enemy)
	wave.horde_requested.connect(_spawn_horde)
	wave.elite_requested.connect(_spawn_elite)
	wave.wave_finished.connect(_on_wave_finished)
	player.stats.died.connect(_on_player_died)
	player.stats.damage_taken.connect(telemetry.record_taken)
	player.stats.shield_blocked.connect(items.on_shield_blocked)
	player.stats.shield_blocked.connect(relics.on_shield_blocked)
	player.stats.healed.connect(items.on_healed)
	player.attack_performed.connect(sound.play_attack)
	player.damaged.connect(_on_player_damaged)
	player.damaged.connect(items.on_player_hurt)
	items.feedback.connect(_show_item_feedback)
	relics.feedback.connect(_show_item_feedback)
	choice_panel.upgrade_chosen.connect(_on_upgrade_chosen)
	choice_panel.chest_resolved.connect(_on_chest_resolved)
	choice_panel.relic_chosen.connect(_on_relic_chosen)
	choice_panel.starter_chosen.connect(_on_starter_chosen)
	choice_panel.restart_requested.connect(_restart)
	choice_panel.main_menu_requested.connect(_on_end_main_menu)
	shop_panel.buy_requested.connect(_on_shop_buy)
	shop_panel.sell_requested.connect(_on_shop_sell)
	shop_panel.merge_requested.connect(_on_shop_merge)
	shop_panel.reroll_requested.connect(_on_shop_reroll)
	shop_panel.reservation_requested.connect(_on_shop_reserve)
	shop_panel.continue_requested.connect(_on_shop_continue)
	mobile_controls.pause_requested.connect(game_menu.open_pause)
	if DebugRunControls.allowed():
		var cheat_menu := DebugCheatMenu.new()
		cheat_menu.name = "DebugCheatMenu"
		add_child(cheat_menu)
	if session.resume_requested:
		session.resume_requested = false
		var saved: Dictionary = session.load_run()
		if not saved.is_empty():
			_restore_run(saved)
			return
	player.global_position = arena.arena_size / 2.0
	starter_pending = true
	choice_panel.show_starters(WeaponCatalog.STARTERS)
	get_tree().paused = true
	_save_run()


func _on_starter_chosen(weapon: WeaponData) -> void:
	if not starter_pending:
		return
	player.loadout.acquire(weapon)
	starter_pending = false
	rewards.begin_wave()
	var profile_id := wave.prepare_next_wave_profile()
	telemetry.begin_wave(wave.current_wave + 1, profile_id)
	wave.start_next_wave()
	items.on_wave_start()
	relics.on_wave_start()
	_sync_music()
	get_tree().paused = false
	_save_run()


func _process(delta: float) -> void:
	mobile_controls.set_combat_active(not ended and not in_shop and not starter_pending and not collecting_wave_loot and not choice_panel.visible and not shop_panel.visible and not game_menu.visible and (wave.active or boss_pending))
	if not ended and (wave.active or boss_pending):
		telemetry.tick(delta, $Enemies.get_child_count(), $EnemyProjectiles.get_child_count())
	_refresh_hud()
	var camera: Camera2D = player.get_node("Camera2D")
	if camera_shake_time > 0.0:
		camera_shake_time = maxf(camera_shake_time - delta, 0.0)
		var strength := 13.0 * camera_shake_time / 0.45
		camera.offset = Vector2(randf_range(-strength, strength), randf_range(-strength, strength))
	else:
		camera.offset = Vector2.ZERO
	if not ended and (wave.active or boss_pending):
		autosave_timer += delta
		if autosave_timer >= 8.0:
			autosave_timer = 0.0
			_save_run()


func _unhandled_input(event: InputEvent) -> void:
	if OS.is_debug_build() and event is InputEventKey and event.pressed and not event.echo and event.keycode == KEY_F3:
		hud.toggle_telemetry()
		get_viewport().set_input_as_handled()
		return
	if event.is_action_pressed("ui_cancel") and not ended and not collecting_wave_loot and not choice_panel.visible and not shop_panel.visible and not game_menu.visible:
		get_viewport().set_input_as_handled()
		game_menu.open_pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready() and not ended:
		_save_run()


func _refresh_hud() -> void:
	var visible_boss: Enemy = boss if is_instance_valid(boss) else null
	hud.update_status(player.stats, xp, xp_goal, level, coins, wave.current_wave, wave.remaining, in_shop, visible_boss, boss_pending, collecting_wave_loot, rewards.pending_levels)
	hud.update_telemetry(telemetry, $Enemies.get_child_count(), $Projectiles.get_child_count() + $EnemyProjectiles.get_child_count())


func _spawn_enemy(data: EnemyData) -> void:
	var limit := MAX_ACTIVE_ENEMIES if data.is_elite or data.is_boss else MAX_ACTIVE_ENEMIES - maxi(wave.elite_reserved_slots(), 1)
	if $Enemies.get_child_count() >= limit:
		telemetry.record_spawn_blocked()
		return
	_create_enemy(data, _spawn_position(_spawn_edge()))


func _spawn_elite(data: EnemyData) -> void:
	if $Enemies.get_child_count() >= MAX_ACTIVE_ENEMIES:
		telemetry.record_spawn_blocked(1 + data.escort_count)
		return
	var at := _spawn_position(_spawn_edge())
	_create_enemy(data, at)
	if data.escort_data == null or data.escort_count <= 0:
		return
	var lower := Vector2.ONE * (DentiArena.WALL_WIDTH + 8.0)
	var upper := arena.arena_size - lower
	for index in data.escort_count:
		if $Enemies.get_child_count() >= MAX_ACTIVE_ENEMIES:
			telemetry.record_spawn_blocked(data.escort_count - index)
			break
		var offset := Vector2.RIGHT.rotated(TAU * float(index) / float(data.escort_count)) * (data.radius + data.escort_data.radius + 12.0)
		_create_enemy(data.escort_data, (at + offset).clamp(lower, upper))


func _spawn_horde(data: EnemyData, count: int) -> void:
	var edge := _spawn_edge()
	var center := _spawn_position(edge)
	var lower := Vector2.ONE * (DentiArena.WALL_WIDTH + 8.0)
	var upper := arena.arena_size - lower
	var limit := MAX_ACTIVE_ENEMIES - maxi(wave.elite_reserved_slots(), 1)
	for index in count:
		if $Enemies.get_child_count() >= limit:
			telemetry.record_spawn_blocked(count - index)
			break
		var offset := (float(index) - float(count - 1) / 2.0) * (data.radius * 2.5)
		var at := center + (Vector2(offset, 0.0) if edge % 2 == 0 else Vector2(0.0, offset))
		_create_enemy(data, at.clamp(lower, upper))


func _spawn_edge() -> int:
	var half_view := get_viewport_rect().size * 0.5
	var lower := DentiArena.WALL_WIDTH + 8.0
	var edges: Array[int] = []
	if player.global_position.y - half_view.y - SPAWN_PADDING >= lower:
		edges.append(0)
	if player.global_position.x + half_view.x + SPAWN_PADDING <= arena.arena_size.x - lower:
		edges.append(1)
	if player.global_position.y + half_view.y + SPAWN_PADDING <= arena.arena_size.y - lower:
		edges.append(2)
	if player.global_position.x - half_view.x - SPAWN_PADDING >= lower:
		edges.append(3)
	return edges.pick_random()


func _spawn_position(edge: int) -> Vector2:
	var half_view := get_viewport_rect().size * 0.5
	var lower := Vector2.ONE * (DentiArena.WALL_WIDTH + 8.0)
	var upper := arena.arena_size - lower
	var center := player.global_position
	match edge:
		0:
			return Vector2(randf_range(maxf(lower.x, center.x - half_view.x), minf(upper.x, center.x + half_view.x)), center.y - half_view.y - SPAWN_PADDING)
		1:
			return Vector2(center.x + half_view.x + SPAWN_PADDING, randf_range(maxf(lower.y, center.y - half_view.y), minf(upper.y, center.y + half_view.y)))
		2:
			return Vector2(randf_range(maxf(lower.x, center.x - half_view.x), minf(upper.x, center.x + half_view.x)), center.y + half_view.y + SPAWN_PADDING)
		_:
			return Vector2(center.x - half_view.x - SPAWN_PADDING, randf_range(maxf(lower.y, center.y - half_view.y), minf(upper.y, center.y + half_view.y)))


func _create_enemy(data: EnemyData, at: Vector2) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	enemy.position = at
	enemy.configure(data, player, wave.current_wave, wave.difficulty_id)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.damaged.connect(_on_enemy_damaged)
	enemy.damage_recorded.connect(telemetry.record_damage)
	enemy.weapon_hit.connect(items.on_weapon_hit)
	enemy.weapon_hit.connect(relics.on_weapon_hit)
	enemy.attack_performed.connect(sound.play_cue)
	if data.is_boss:
		enemy.death_started.connect(_on_boss_death_started)
		enemy.enraged.connect(_on_boss_enraged)
		enemy.boss_phase_started.connect(_on_boss_phase_started)
		enemy.boss_guarded.connect(_on_boss_guarded)
		enemy.reinforcements_requested.connect(_on_boss_reinforcements)
	if data.is_elite:
		enemy.elite_guarded.connect(_on_elite_guarded)
	$Enemies.add_child(enemy)
	telemetry.record_spawn(data.is_boss, data.is_elite)
	if data.is_boss:
		boss = enemy


func _on_enemy_defeated(at: Vector2, data: EnemyData) -> void:
	telemetry.record_kill(data.is_boss, data.is_elite)
	if not data.is_boss:
		sound.play_cue(&"down")
	var reward_drop: bool = wave.active and (data.is_elite or randf() < WaveController.loot_chance(wave.current_wave) * DifficultyCatalog.by_id(wave.difficulty_id).reward_chance_multiplier)
	var bonus_coins := items.on_kill(at, data.is_boss)
	coins += bonus_coins
	telemetry.record_loot(&"coin", bonus_coins, &"kill_item")
	if data.is_boss:
		boss = null
		if boss_pending:
			call_deferred("_resolve_boss_wave")
		return
	if wave.active and not rewards.chest_spawned and randf() < ChestRewards.drop_chance(player.stats.luck, data.is_elite):
		var chest := ChestRewards.roll_item(wave.current_wave, player.stats.luck, items)
		if not chest.is_empty():
			rewards.mark_chest_spawned()
			_spawn_loot(at, &"chest", int(chest["scrap_coins"]), StringName(str(chest["item_id"])))
	if reward_drop:
		_spawn_loot(at + Vector2(-11.0, 0.0), &"xp", data.xp_drop)
	if wave.active and data.coin_drop > 0 and randf() < EconomyRules.coin_chance(data, wave.current_wave, DifficultyCatalog.by_id(wave.difficulty_id).reward_chance_multiplier):
		_spawn_loot(at + Vector2(11.0, 0.0), &"coin", data.coin_drop)


func _on_boss_death_started(_at: Vector2) -> void:
	telemetry.record_boss_death()
	sound.play_cue(&"boss_break")
	camera_shake_time = 0.45


func _on_boss_enraged(at: Vector2) -> void:
	sound.play_cue(&"boss_warning")
	var inflamed := is_instance_valid(boss) and boss.overtime_active
	_show_item_feedback("ENTZÜNDET!" if inflamed else "BOSS WIRD WÜTEND!", at, boss.data.inflammation_color if inflamed else Color(1.0, 0.39, 0.27))
	camera_shake_time = 0.25


func _on_boss_phase_started(at: Vector2, _phase: int) -> void:
	sound.play_cue(&"boss_warning")
	_show_item_feedback("ZAHNSCHILD!", at, Color(0.95, 0.32, 0.63))
	camera_shake_time = 0.18


func _on_boss_guarded(at: Vector2) -> void:
	_show_item_feedback("VERSIEGELT", at, Color(0.43, 0.84, 0.94))


func _on_elite_guarded(at: Vector2) -> void:
	_show_item_feedback("SCHMELZSCHILD!", at, Color(0.43, 0.84, 0.94))


func _on_boss_reinforcements(count: int) -> void:
	_spawn_horde(WaveController.ACID_SPITTER if wave.current_wave == WaveController.MAX_WAVES else WaveController.BACTERIA, count)


func _spawn_loot(at: Vector2, kind: StringName, amount: int, reward_id: StringName = &"") -> void:
	var loot: Loot = LOOT_SCENE.instantiate()
	loot.position = at
	loot.configure(kind, amount, player, reward_id)
	loot.collected.connect(_on_loot_collected)
	$Loot.add_child(loot)


func _on_loot_collected(kind: StringName, amount: int, reward_id: StringName = &"") -> void:
	sound.play_cue(&"pickup")
	if kind == &"chest":
		rewards.queue_chest(reward_id, amount)
		telemetry.record_chest_found()
	else:
		var bonus := items.on_pickup(kind, amount)
		telemetry.record_loot(kind, amount)
		telemetry.record_loot(kind, bonus, &"pickup_item")
		if kind == &"coin":
			coins += amount + bonus
		else:
			_award_xp(amount + bonus)
	if collecting_wave_loot:
		wave_loot_remaining = maxi(wave_loot_remaining - 1, 0)
		if wave_loot_remaining == 0:
			call_deferred("_finish_loot_collection")


func _on_enemy_damaged(at: Vector2, amount: float) -> void:
	_show_damage_number(at, amount)
	sound.play_cue(&"hit")


func _on_player_damaged(at: Vector2, amount: float) -> void:
	_show_damage_number(at, amount, true)
	sound.play_cue(&"hurt")


func _show_item_feedback(message: String, at: Vector2, color: Color) -> void:
	var number: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate()
	$DamageNumbers.add_child(number)
	number.show_message(at, message, color)


func _show_damage_number(at: Vector2, amount: float, player_hit: bool = false) -> void:
	var number: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate()
	$DamageNumbers.add_child(number)
	number.show_amount(at, amount, player_hit)


func _award_xp(amount: int) -> void:
	xp += amount
	while xp >= xp_goal:
		xp -= xp_goal
		level += 1
		xp_goal = 5 + (level - 1) * 3
		rewards.earn_level()


func _show_level_choice() -> void:
	var pool: Array[UpgradeData] = []
	var equipped_stats: Array[StringName] = []
	for weapon in player.loadout.equipped():
		equipped_stats.append(StringName(weapon.data.damage_stat + "_damage"))
	for upgrade in UPGRADES:
		if upgrade.stat in [&"melee_damage", &"ranged_damage"] and not equipped_stats.has(upgrade.stat):
			continue
		pool.append(upgrade)
	pool.shuffle()
	var choices: Array[UpgradeData] = []
	# Pending levels include this choice; resolve their earned levels oldest first.
	var earned_level := level - maxi(rewards.pending_levels - 1, 0)
	for index in ChoicePanel.UPGRADE_COUNT:
		choices.append(pool[index].with_tier(DentiRarity.upgrade_tier(earned_level, player.stats.luck)))
	choice_panel.show_upgrades(choices)
	get_tree().paused = true
	_save_run()


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	player.stats.apply_upgrade(upgrade.stat, upgrade.amount)
	rewards.resolve_level()
	_advance_post_wave_rewards()


func _on_chest_resolved(keep: bool) -> void:
	var chest := rewards.current_chest()
	if chest.is_empty():
		return
	var item := ShopController.by_id(StringName(str(chest["item_id"])))
	if keep and item != null and items.acquire(item):
		telemetry.record_chest_kept()
	else:
		var scrap_coins := items.scrap_value(int(chest["scrap_coins"]))
		coins += scrap_coins
		telemetry.record_loot(&"coin", scrap_coins, &"chest_scrap")
		telemetry.record_chest_scrapped()
	rewards.resolve_chest()
	_advance_post_wave_rewards()


func _on_relic_chosen(id: StringName) -> void:
	if rewards.step != PostWaveRewards.Step.RELICS or not rewards.pending_relics.has(str(id)):
		return
	if relics.acquire(id):
		rewards.resolve_relic()
		_advance_post_wave_rewards()


func _on_wave_finished(wave_number: int) -> void:
	if ended:
		return
	if WaveController.is_boss_wave(wave_number):
		if is_instance_valid(boss):
			boss_pending = true
			boss.start_overtime()
			_clear_combat(true)
			_sync_music()
			_refresh_hud()
			_save_run()
			return
	_clear_combat()
	_sync_music()
	_begin_loot_collection()


func _resolve_boss_wave() -> void:
	if ended or not boss_pending:
		return
	boss_pending = false
	_clear_combat()
	_sync_music()
	_begin_loot_collection()


func _begin_loot_collection() -> void:
	if collecting_wave_loot or ended:
		return
	collecting_wave_loot = true
	rewards.begin_collection()
	player.velocity = Vector2.ZERO
	player.set_physics_process(false)
	wave_loot_remaining = 0
	for drop: Loot in $Loot.get_children():
		if drop.is_queued_for_deletion():
			continue
		wave_loot_remaining += 1
		drop.begin_wave_collection()
	_refresh_hud()
	_save_run()
	if wave_loot_remaining == 0:
		_finish_loot_collection()


func _finish_loot_collection() -> void:
	if not collecting_wave_loot or wave_loot_remaining > 0 or ended:
		return
	collecting_wave_loot = false
	player.set_physics_process(true)
	var interest := items.on_wave_end(coins)
	coins += interest
	telemetry.record_loot(&"coin", interest, &"interest")
	if wave.current_wave < WaveController.MAX_WAVES and WaveController.is_boss_wave(wave.current_wave) and rewards.pending_relics.is_empty():
		rewards.queue_relics(RelicCatalog.choices(relics.owned))
	rewards.finish_collection(wave.current_wave >= WaveController.MAX_WAVES)
	_advance_post_wave_rewards()


func _advance_post_wave_rewards() -> void:
	match rewards.step:
		PostWaveRewards.Step.LEVELS:
			_show_level_choice()
		PostWaveRewards.Step.CHESTS:
			var chest := rewards.current_chest()
			var item := ShopController.by_id(StringName(str(chest.get("item_id", ""))))
			if item == null:
				rewards.resolve_chest()
				_advance_post_wave_rewards()
				return
			choice_panel.show_chest(item, items.scrap_value(int(chest["scrap_coins"])))
			get_tree().paused = true
			_save_run()
		PostWaveRewards.Step.RELICS:
			var options: Array[RelicData] = []
			for id in rewards.pending_relics:
				var relic := RelicCatalog.by_id(StringName(id))
				if relic != null:
					options.append(relic)
			if options.is_empty():
				rewards.resolve_relic()
				_advance_post_wave_rewards()
				return
			choice_panel.show_relics(options)
			get_tree().paused = true
			_save_run()
		PostWaveRewards.Step.SHOP:
			_open_shop()
		PostWaveRewards.Step.END:
			_finish_run()


func _clear_arena(collect_drops: bool, keep_boss: bool = false) -> void:
	for drop in $Loot.get_children():
		if drop.is_queued_for_deletion():
			continue
		if collect_drops:
			if drop.kind == &"chest":
				rewards.queue_chest(drop.reward_id, drop.amount)
				telemetry.record_chest_found()
			else:
				var bonus := items.on_pickup(drop.kind, drop.amount)
				telemetry.record_loot(drop.kind, drop.amount)
				telemetry.record_loot(drop.kind, bonus, &"pickup_item")
				if drop.kind == &"coin":
					coins += drop.amount + bonus
				else:
					_award_xp(drop.amount + bonus)
		drop.queue_free()
	_clear_combat(keep_boss)


func _clear_combat(keep_boss: bool = false) -> void:
	for enemy in $Enemies.get_children():
		if keep_boss and enemy == boss:
			continue
		enemy.queue_free()
	if not keep_boss:
		boss = null
	for projectile in $Projectiles.get_children():
		projectile.queue_free()
	for projectile in $EnemyProjectiles.get_children():
		projectile.queue_free()


func _finish_run() -> void:
	if ended:
		return
	rewards.step = PostWaveRewards.Step.END
	ended = true
	boss_pending = false
	_sync_music()
	_clear_arena(true)
	var recap := _run_recap_data()
	recap["hell_unlocked_now"] = wave.difficulty_id == &"hard" and session.unlock_hell()
	choice_panel.show_end(true, coins, recap)
	_save_completed_report(true)
	session.clear_run()
	_refresh_hud()
	get_tree().paused = true


func _open_shop() -> void:
	rewards.step = PostWaveRewards.Step.SHOP
	in_shop = true
	_sync_music()
	shop.open_shop(wave.current_wave, player.stats.luck, player.loadout, items)
	_update_shop_panel()
	get_tree().paused = true
	_save_run()


func _update_shop_panel() -> void:
	var equipment: Array[Dictionary] = []
	var weapons := player.loadout.equipped()
	for index in weapons.size():
		var weapon := weapons[index]
		equipment.append({"data": weapon.data, "hands": weapon.data.hands, "icon": weapon.data.sprite, "uid": weapon.get_instance_id(), "name": weapon.data.display_name, "tier": weapon.tier, "refund": player.loadout.refund_for(index), "stats": weapon.data.stats_text(weapon.tier), "combat": weapon.data.combat_text(), "description": weapon.data.description, "dps": _weapon_dps(weapon.data, weapon.tier), "mergeable": player.loadout.can_merge(index)})
	var buyable: Array[bool] = []
	var offer_dps: Array[float] = []
	for offer in shop.offers:
		buyable.append(offer == null or (player.loadout.can_acquire(offer.weapon_data, offer.weapon_tier) if offer.weapon_data != null else items.can_acquire(offer)))
		offer_dps.append(_weapon_dps(offer.weapon_data, offer.weapon_tier) if offer != null and offer.weapon_data != null else 0.0)
	var owned_display := items.all_items()
	for id in relics.owned:
		var relic := RelicCatalog.by_id(StringName(id))
		if relic != null:
			owned_display.append({"name": "Relikt: " + relic.display_name, "count": 1, "description": relic.description, "tier": 4, "icon": DentiUIIcons.relic(relic.icon_index), "relic": true})
	shop_panel.set_build_context(player)
	shop_panel.show_shop(wave.current_wave, coins, shop.reroll_cost, shop.offers, equipment, player.loadout.used_slots(), WeaponLoadout.CAPACITY, buyable, player.stats.luck, owned_display, items.owned, offer_dps, shop.reserved)
	_refresh_hud()


func _weapon_dps(data: WeaponData, tier: int) -> float:
	return data.estimated_dps(tier, player.stats, items.attack_interval_factor(), items.base_weapon_damage_bonus())


func _on_shop_buy(index: int) -> void:
	if not in_shop:
		return
	var offer := shop.offers[index]
	if offer == null or coins < offer.price:
		return
	if offer.weapon_data != null and not player.loadout.can_acquire(offer.weapon_data, offer.weapon_tier):
		return
	if offer.weapon_data == null and not items.can_acquire(offer):
		return
	var acquired := player.loadout.acquire(offer.weapon_data, offer.weapon_tier, offer.price) if offer.weapon_data != null else items.acquire(offer)
	if not acquired:
		return
	coins -= offer.price
	telemetry.record_shop_spending(&"weapon" if offer.weapon_data != null else &"item", offer.price)
	shop.take_offer(index)
	_update_shop_panel()
	_save_run()


func _on_shop_sell(index: int) -> void:
	if not in_shop:
		return
	var refund := player.loadout.sell(index)
	coins += refund
	telemetry.record_loot(&"coin", refund, &"weapon_sale")
	_update_shop_panel()
	_save_run()


func _on_shop_merge(index: int) -> void:
	if not in_shop or not player.loadout.merge(index):
		return
	_update_shop_panel()
	_save_run()


func _on_shop_reroll() -> void:
	if not in_shop or coins < shop.reroll_cost or not shop.can_reroll():
		return
	coins -= shop.reroll_cost
	telemetry.record_shop_spending(&"reroll", shop.reroll_cost)
	shop.reroll(wave.current_wave, player.stats.luck, player.loadout, items)
	_update_shop_panel()
	_save_run()


func _on_shop_reserve(index: int) -> void:
	if not in_shop or not shop.toggle_reservation(index):
		return
	_update_shop_panel()
	_save_run()


func _on_shop_continue() -> void:
	if not in_shop:
		return
	if player.loadout.equipped().is_empty():
		return
	shop_panel.visible = false
	in_shop = false
	boss_pending = false
	_clear_arena(false)
	player.global_position = arena.arena_size / 2.0
	rewards.begin_wave()
	var profile_id := wave.prepare_next_wave_profile()
	telemetry.begin_wave(wave.current_wave + 1, profile_id)
	wave.start_next_wave()
	items.on_wave_start()
	relics.on_wave_start()
	_sync_music()
	get_tree().paused = false
	_refresh_hud()
	_save_run()


func _on_player_died() -> void:
	if ended:
		return
	ended = true
	_sync_music()
	_clear_arena(false)
	shop_panel.visible = false
	choice_panel.show_end(false, coins, _run_recap_data())
	_save_completed_report(false)
	session.clear_run()
	get_tree().paused = true


func _save_completed_report(won: bool) -> void:
	var report := _run_recap_data()
	report["outcome"] = "victory" if won else "death"
	session.save_run_report(report)


func _run_recap_data() -> Dictionary:
	return {
		"difficulty_id": str(wave.difficulty_id),
		"wave_reached": wave.current_wave,
		"final_level": level,
		"coins_left": coins,
		"weapons": player.loadout.save_data(),
		"items": items.owned.duplicate(),
		"relics": relics.owned.duplicate(),
		"telemetry": telemetry.save_data(),
		"waves": telemetry.wave_summaries(),
	}


func debug_start_wave(number: int) -> void:
	if not DebugRunControls.allowed() or player.loadout.equipped().is_empty():
		return
	wave.active = false
	# Remove immediately while paused so old loot callbacks and attacks cannot
	# leak into the freshly started wave.
	for container in [$Enemies, $Projectiles, $EnemyProjectiles, $Loot]:
		for child in container.get_children():
			child.free()
	boss = null
	boss_pending = false
	collecting_wave_loot = false
	wave_loot_remaining = 0
	ended = false
	in_shop = false
	starter_pending = false
	choice_panel.visible = false
	shop_panel.visible = false
	game_menu.visible = false
	player.set_physics_process(true)
	player.velocity = Vector2.ZERO
	player.global_position = arena.arena_size / 2.0
	player.hurt_time = 0.0
	player.sprite.modulate = Color.WHITE
	var configured_stats := player.stats.to_save_data()
	configured_stats["health"] = player.stats.max_health
	configured_stats["shield_charges"] = 0
	configured_stats["regen_progress"] = 0.0
	player.stats.load_save_data(configured_stats)
	# A pending strike may still retain a reference to a removed enemy.
	player.loadout.restore(player.loadout.save_data())
	rewards.begin_wave()
	wave.current_wave = clampi(number, 1, WaveController.MAX_WAVES) - 1
	wave.next_profile_id = &""
	var profile_id := wave.prepare_next_wave_profile()
	telemetry.begin_wave(wave.current_wave + 1, profile_id)
	wave.start_next_wave()
	items.on_wave_start()
	relics.on_wave_start()
	_sync_music()
	_refresh_hud()
	_save_run()


func _restart() -> void:
	session.clear_run()
	get_tree().paused = false
	get_tree().reload_current_scene()


func _on_end_main_menu() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://scenes/ui/game_menu.tscn")


func _save_run() -> void:
	if ended or not is_node_ready():
		return
	session.save_run(RUN_SNAPSHOT.capture(self))


func _restore_run(saved: Dictionary) -> void:
	RUN_SNAPSHOT.restore(self, saved)
	session.selected_difficulty_id = wave.difficulty_id
	_sync_music()


func _sync_music() -> void:
	if ended or starter_pending:
		music.fade_out_and_stop()
	elif boss_pending:
		music.play_boss_overtime(wave.current_wave)
	else:
		music.play_wave(wave.current_wave)
