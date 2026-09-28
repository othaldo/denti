extends Node2D

const ENEMY_SCENE: PackedScene = preload("res://scenes/enemies/enemy.tscn")
const LOOT_SCENE: PackedScene = preload("res://scenes/game/loot.tscn")
const SPAWN_PADDING := 32.0
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
@onready var wave: WaveController = $WaveController
@onready var shop: ShopController = $ShopController
@onready var hud: GameHUD = $HUD
@onready var choice_panel: ChoicePanel = $ChoicePanel
@onready var shop_panel: ShopPanel = $ShopPanel

var xp: int = 0
var xp_goal: int = 5
var level: int = 1
var coins: int = 0
var ended: bool = false
var in_shop: bool = false
var intermission_pending: bool = false
var owned_weapons: Array[StringName] = []
var boss: Enemy
var boss_pending: bool = false


func _ready() -> void:
	randomize()
	wave.enemy_requested.connect(_spawn_enemy)
	wave.boss_requested.connect(_spawn_enemy)
	wave.wave_finished.connect(_on_wave_finished)
	player.stats.died.connect(_on_player_died)
	choice_panel.upgrade_chosen.connect(_on_upgrade_chosen)
	choice_panel.restart_requested.connect(_restart)
	shop_panel.buy_requested.connect(_on_shop_buy)
	shop_panel.reroll_requested.connect(_on_shop_reroll)
	shop_panel.continue_requested.connect(_on_shop_continue)
	wave.start_next_wave()


func _process(_delta: float) -> void:
	_refresh_hud()


func _refresh_hud() -> void:
	hud.update_status(player.stats, xp, xp_goal, level, coins, wave.current_wave, wave.remaining, in_shop, boss, boss_pending)


func _spawn_enemy(data: EnemyData) -> void:
	var enemy: Enemy = ENEMY_SCENE.instantiate()
	var edge := randi_range(0, 3)
	match edge:
		0:
			enemy.position = Vector2(randf_range(0.0, DentiArena.SIZE.x), -SPAWN_PADDING)
		1:
			enemy.position = Vector2(DentiArena.SIZE.x + SPAWN_PADDING, randf_range(0.0, DentiArena.SIZE.y))
		2:
			enemy.position = Vector2(randf_range(0.0, DentiArena.SIZE.x), DentiArena.SIZE.y + SPAWN_PADDING)
		3:
			enemy.position = Vector2(-SPAWN_PADDING, randf_range(0.0, DentiArena.SIZE.y))
	enemy.configure(data, player, wave.current_wave)
	enemy.defeated.connect(_on_enemy_defeated)
	$Enemies.add_child(enemy)
	if data.is_boss:
		boss = enemy


func _on_enemy_defeated(at: Vector2, data: EnemyData) -> void:
	if data.is_boss:
		boss = null
		if boss_pending:
			call_deferred("_finish_run")
		return
	if not wave.active:
		return
	_spawn_loot(at + Vector2(-11.0, 0.0), &"xp", data.xp_drop)
	_spawn_loot(at + Vector2(11.0, 0.0), &"coin", data.coin_drop)


func _spawn_loot(at: Vector2, kind: StringName, amount: int) -> void:
	var loot: Loot = LOOT_SCENE.instantiate()
	loot.position = at
	loot.configure(kind, amount, player)
	loot.collected.connect(_on_loot_collected)
	$Loot.add_child(loot)


func _on_loot_collected(kind: StringName, amount: int) -> void:
	if kind == &"coin":
		coins += amount
	else:
		xp += amount
		_check_level_up()


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
	return true


func _on_upgrade_chosen(upgrade: UpgradeData) -> void:
	player.stats.apply_upgrade(upgrade.stat, upgrade.amount)
	if _check_level_up():
		return
	if intermission_pending:
		_open_shop()
	else:
		get_tree().paused = false


func _on_wave_finished(wave_number: int) -> void:
	if ended:
		return
	if wave_number >= WaveController.MAX_WAVES:
		if is_instance_valid(boss):
			boss_pending = true
			_clear_arena(true, true)
		else:
			_finish_run()
		_refresh_hud()
		return
	_clear_arena(true)
	intermission_pending = true
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


func _finish_run() -> void:
	if ended:
		return
	ended = true
	boss_pending = false
	_clear_arena(true)
	choice_panel.show_end(true, coins)
	_refresh_hud()
	get_tree().paused = true


func _open_shop() -> void:
	in_shop = true
	intermission_pending = false
	shop.open_shop(owned_weapons)
	_update_shop_panel()
	get_tree().paused = true


func _update_shop_panel() -> void:
	shop_panel.show_shop(wave.current_wave, coins, shop.reroll_cost, shop.offers)
	_refresh_hud()


func _on_shop_buy(index: int) -> void:
	if not in_shop:
		return
	var offer := shop.offers[index]
	if offer == null or coins < offer.price:
		return
	coins -= offer.price
	if offer.weapon_scene != null:
		player.add_child(offer.weapon_scene.instantiate())
		owned_weapons.append(offer.id)
	else:
		for stat in offer.stat_changes:
			player.stats.apply_upgrade(StringName(stat), float(offer.stat_changes[stat]))
	shop.take_offer(index)
	_update_shop_panel()


func _on_shop_reroll() -> void:
	if not in_shop or coins < shop.reroll_cost:
		return
	coins -= shop.reroll_cost
	shop.reroll(owned_weapons)
	_update_shop_panel()


func _on_shop_continue() -> void:
	if not in_shop:
		return
	shop_panel.visible = false
	in_shop = false
	boss_pending = false
	_clear_arena(false)
	player.global_position = DentiArena.SIZE / 2.0
	wave.start_next_wave()
	get_tree().paused = false
	_refresh_hud()


func _on_player_died() -> void:
	if ended:
		return
	ended = true
	_clear_arena(false)
	shop_panel.visible = false
	choice_panel.show_end(false, coins)
	get_tree().paused = true


func _restart() -> void:
	get_tree().paused = false
	get_tree().reload_current_scene()
