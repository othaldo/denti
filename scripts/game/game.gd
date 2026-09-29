extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const LOOT_SCENE: PackedScene = preload("res://scenes/game/loot.tscn")
const DAMAGE_NUMBER_SCENE: PackedScene = preload("res://scenes/ui/damage_number.tscn")
const RUN_SNAPSHOT: Script = preload("res://scripts/systems/run_snapshot.gd")
const SPAWN_PADDING := 32.0
const MAX_ACTIVE_ENEMIES := 110
const UPGRADES: Array[UpgradeData] = [
	preload("res://data/upgrades/bisskraft.tres"),
	preload("res://data/upgrades/haerte.tres"),
	preload("res://data/upgrades/schmelz.tres"),
	preload("res://data/upgrades/putzeifer.tres"),
	preload("res://data/upgrades/bewegung.tres"),
	preload("res://data/upgrades/speichel.tres"),
	preload("res://data/upgrades/glanz.tres"),
]

@onready var player: Player = $Player
@onready var arena: DentiArena = $Arena
@onready var wave: WaveController = $WaveController
@onready var shop: ShopController = $ShopController
@onready var music: MusicController = $Music
@onready var sound: SoundController = $Sound
@onready var hud: GameHUD = $HUD
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
var intermission_pending: bool = false
var starter_pending: bool = false
var boss: Enemy
var boss_pending: bool = false
var autosave_timer: float = 0.0


func _ready() -> void:
	randomize()
	wave.enemy_requested.connect(_spawn_enemy)
	wave.boss_requested.connect(_spawn_enemy)
	wave.horde_requested.connect(_spawn_horde)
	wave.wave_finished.connect(_on_wave_finished)
	player.stats.died.connect(_on_player_died)
	player.attack_performed.connect(sound.play_attack)
	player.damaged.connect(_on_player_damaged)
	choice_panel.upgrade_chosen.connect(_on_upgrade_chosen)
	choice_panel.starter_chosen.connect(_on_starter_chosen)
	choice_panel.restart_requested.connect(_restart)
	choice_panel.main_menu_requested.connect(_on_end_main_menu)
	shop_panel.buy_requested.connect(_on_shop_buy)
	shop_panel.sell_requested.connect(_on_shop_sell)
	shop_panel.reroll_requested.connect(_on_shop_reroll)
	shop_panel.continue_requested.connect(_on_shop_continue)
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
	wave.start_next_wave()
	_sync_music()
	get_tree().paused = false
	_save_run()


func _process(delta: float) -> void:
	_refresh_hud()
	if not ended and (wave.active or boss_pending):
		autosave_timer += delta
		if autosave_timer >= 8.0:
			autosave_timer = 0.0
			_save_run()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel") and not ended and not choice_panel.visible and not shop_panel.visible and not game_menu.visible:
		get_viewport().set_input_as_handled()
		game_menu.open_pause()


func _notification(what: int) -> void:
	if what == NOTIFICATION_WM_CLOSE_REQUEST and is_node_ready() and not ended:
		_save_run()


func _refresh_hud() -> void:
	var visible_boss: Enemy = boss if is_instance_valid(boss) else null
	hud.update_status(player.stats, xp, xp_goal, level, coins, wave.current_wave, wave.remaining, in_shop, visible_boss, boss_pending)


func _spawn_enemy(data: EnemyData) -> void:
	if $Enemies.get_child_count() >= MAX_ACTIVE_ENEMIES:
		return
	_create_enemy(data, _spawn_position(_spawn_edge()))


func _spawn_horde(data: EnemyData, count: int) -> void:
	var edge := _spawn_edge()
	var center := _spawn_position(edge)
	var lower := Vector2.ONE * (DentiArena.WALL_WIDTH + 8.0)
	var upper := arena.arena_size - lower
	for index in count:
		if $Enemies.get_child_count() >= MAX_ACTIVE_ENEMIES:
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
	enemy.configure(data, player, wave.current_wave)
	enemy.defeated.connect(_on_enemy_defeated)
	enemy.damaged.connect(_on_enemy_damaged)
	enemy.attack_performed.connect(sound.play_cue)
	$Enemies.add_child(enemy)
	if data.is_boss:
		boss = enemy


func _on_enemy_defeated(at: Vector2, data: EnemyData) -> void:
	sound.play_cue(&"down")
	if data.is_boss:
		boss = null
		if boss_pending:
			call_deferred("_resolve_boss_wave")
		return
	if not wave.active:
		return
	_spawn_loot(at + Vector2(-11.0, 0.0), &"xp", data.xp_drop)
	if data.coin_drop > 0 and randf() < data.coin_drop_chance:
		_spawn_loot(at + Vector2(11.0, 0.0), &"coin", data.coin_drop)


func _spawn_loot(at: Vector2, kind: StringName, amount: int) -> void:
	var loot: Loot = LOOT_SCENE.instantiate()
	loot.position = at
	loot.configure(kind, amount, player)
	loot.collected.connect(_on_loot_collected)
	$Loot.add_child(loot)


func _on_loot_collected(kind: StringName, amount: int) -> void:
	sound.play_cue(&"pickup")
	if kind == &"coin":
		coins += amount
	else:
		xp += amount
		_check_level_up()


func _on_enemy_damaged(at: Vector2, amount: float) -> void:
	_show_damage_number(at, amount)
	sound.play_cue(&"hit")


func _on_player_damaged(at: Vector2, amount: float) -> void:
	_show_damage_number(at, amount, true)
	sound.play_cue(&"hurt")


func _show_damage_number(at: Vector2, amount: float, player_hit: bool = false) -> void:
	var number: DamageNumber = DAMAGE_NUMBER_SCENE.instantiate()
	$DamageNumbers.add_child(number)
	number.show_amount(at, amount, player_hit)


func _check_level_up() -> bool:
	if xp < xp_goal or ended:
		return false
	xp -= xp_goal
	level += 1
	xp_goal = 5 + (level - 1) * 3
	var pool: Array[UpgradeData] = UPGRADES.duplicate()
	pool.shuffle()
	choice_panel.show_upgrades([pool[0], pool[1], pool[2]])
	get_tree().paused = true
	_save_run()
	return true


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	player.stats.apply_upgrade(upgrade.stat, upgrade.amount)
	if _check_level_up():
		return
	if intermission_pending:
		_open_shop()
	else:
		get_tree().paused = false
		_save_run()


func _on_wave_finished(wave_number: int) -> void:
	if ended:
		return
	if WaveController.is_boss_wave(wave_number):
		if is_instance_valid(boss):
			boss_pending = true
			_clear_arena(true, true)
			_sync_music()
			_refresh_hud()
			_save_run()
			return
		if wave_number >= WaveController.MAX_WAVES:
			_finish_run()
			_refresh_hud()
			return
	_clear_arena(true)
	intermission_pending = true
	_sync_music()
	if _check_level_up():
		return
	_open_shop()


func _resolve_boss_wave() -> void:
	if ended or not boss_pending:
		return
	boss_pending = false
	if wave.current_wave >= WaveController.MAX_WAVES:
		_finish_run()
		return
	_clear_arena(true)
	intermission_pending = true
	_sync_music()
	if _check_level_up():
		return
	_open_shop()


func _clear_arena(collect_drops: bool, keep_boss: bool = false) -> void:
	for drop in $Loot.get_children():
		if collect_drops:
			if drop.kind == &"coin":
				coins += drop.amount
			else:
				xp += drop.amount
		drop.free()
	for enemy in $Enemies.get_children():
		if keep_boss and enemy == boss:
			continue
		enemy.free()
	if not keep_boss:
		boss = null
	for projectile in $Projectiles.get_children():
		projectile.free()
	for projectile in $EnemyProjectiles.get_children():
		projectile.free()


func _finish_run() -> void:
	if ended:
		return
	ended = true
	boss_pending = false
	_sync_music()
	_clear_arena(true)
	choice_panel.show_end(true, coins)
	session.clear_run()
	_refresh_hud()
	get_tree().paused = true


func _open_shop() -> void:
	in_shop = true
	intermission_pending = false
	_sync_music()
	shop.open_shop()
	_update_shop_panel()
	get_tree().paused = true
	_save_run()


func _update_shop_panel() -> void:
	var equipment: Array[Dictionary] = []
	var weapons := player.loadout.equipped()
	for index in weapons.size():
		var weapon := weapons[index]
		equipment.append({"name": weapon.data.display_name, "tier": weapon.tier, "refund": player.loadout.refund_for(index)})
	var buyable: Array[bool] = []
	for offer in shop.offers:
		buyable.append(offer == null or offer.weapon_data == null or player.loadout.can_acquire(offer.weapon_data))
	shop_panel.show_shop(wave.current_wave, coins, shop.reroll_cost, shop.offers, wave.next_wave_preview(), equipment, player.loadout.used_slots(), WeaponLoadout.CAPACITY, buyable)
	_refresh_hud()


func _on_shop_buy(index: int) -> void:
	if not in_shop:
		return
	var offer := shop.offers[index]
	if offer == null or coins < offer.price:
		return
	if offer.weapon_data != null and not player.loadout.can_acquire(offer.weapon_data):
		return
	coins -= offer.price
	if offer.weapon_data != null:
		player.loadout.acquire(offer.weapon_data)
	else:
		for stat in offer.stat_changes:
			player.stats.apply_upgrade(StringName(stat), float(offer.stat_changes[stat]))
	shop.take_offer(index)
	_update_shop_panel()
	_save_run()


func _on_shop_sell(index: int) -> void:
	if not in_shop:
		return
	coins += player.loadout.sell(index)
	_update_shop_panel()
	_save_run()


func _on_shop_reroll() -> void:
	if not in_shop or coins < shop.reroll_cost:
		return
	coins -= shop.reroll_cost
	shop.reroll()
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
	wave.start_next_wave()
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
	choice_panel.show_end(false, coins)
	session.clear_run()
	get_tree().paused = true


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
	_sync_music()


func _sync_music() -> void:
	if ended or starter_pending:
		music.fade_out_and_stop()
	elif boss_pending:
		music.play_boss_overtime(wave.current_wave)
	else:
		music.play_wave(wave.current_wave)
