class_name PlayerProjectilePool
extends Node2D

const PROJECTILE: PackedScene = preload("res://scenes/game/weapon_projectile.tscn")
const PREPARE_PER_STYLE := 24
const MAX_IDLE := 512
# Resource identity and tier keep prepared sprite shapes/colors compatible.
# Idle bullets live outside the tree, so saves and callbacks see only live shots.
var idle: Dictionary[WeaponData, Dictionary] = {}
var idle_count: int = 0
var created: int = 0

func _bucket(weapon: WeaponData, tier: int) -> Array:
	if not idle.has(weapon):
		idle[weapon] = {}
	if not idle[weapon].has(tier):
		idle[weapon][tier] = []
	return idle[weapon][tier]

func prepare(weapon: WeaponData, tier: int, count: int = PREPARE_PER_STYLE) -> void:
	var bucket := _bucket(weapon, tier)
	for number in maxi(mini(count - bucket.size(), MAX_IDLE - idle_count), 0):
		bucket.append(_create(weapon, tier))
		idle_count += 1

func prepare_loadout(weapons: Array[WeaponInstance]) -> void:
	var wanted: Dictionary[WeaponData, Array] = {}
	for weapon in weapons:
		if weapon.data.attack_mode != &"projectile":
			continue
		if not wanted.has(weapon.data):
			wanted[weapon.data] = []
		if not wanted[weapon.data].has(weapon.tier):
			wanted[weapon.data].append(weapon.tier)
	# Discard reserves for sold/fused weapons so they cannot occupy the bound
	# and prevent preparing the new equipment. Live shots finish normally.
	for data: WeaponData in idle.keys():
		for tier: int in idle[data].keys():
			if wanted.has(data) and wanted[data].has(tier):
				continue
			var bucket: Array = idle[data][tier]
			idle_count -= bucket.size()
			for shot: WeaponProjectile in bucket:
				shot.free()
			idle[data].erase(tier)
		if idle[data].is_empty():
			idle.erase(data)
	for data: WeaponData in wanted:
		for tier: int in wanted[data]:
			prepare(data, tier)

func _create(weapon: WeaponData, tier: int) -> WeaponProjectile:
	var shot: WeaponProjectile = PROJECTILE.instantiate()
	CombatDiagnostics.instrument(shot, "player_projectile", self)
	shot.pool = self
	created += 1
	# Build the actual sprites before combat; launch supplies current item effects.
	shot.launch(Vector2.ZERO, Vector2.RIGHT, 0, weapon, null, false, tier)
	shot.set_physics_process(false)
	shot.retired = true
	return shot

func acquire(weapon: WeaponData, tier: int) -> WeaponProjectile:
	var bucket := _bucket(weapon, tier)
	var shot: WeaponProjectile
	if bucket.is_empty():
		shot = _create(weapon, tier)
	else:
		shot = bucket.pop_back()
		idle_count -= 1
	shot.visible = true
	add_child(shot)
	shot.set_physics_process(true)
	return shot

func recycle(shot: WeaponProjectile) -> void:
	if shot.get_parent() != self:
		return
	shot.retired = true
	shot.set_physics_process(false)
	shot.visible = false
	shot.items = null
	shot.enemy_index = null
	remove_child(shot)
	if idle_count < MAX_IDLE:
		_bucket(shot.data, shot.tier).append(shot)
		idle_count += 1
	else:
		shot.queue_free()

func _exit_tree() -> void:
	for styles: Dictionary in idle.values():
		for bucket: Array in styles.values():
			for shot: WeaponProjectile in bucket:
				shot.free()
	idle.clear()
	idle_count = 0
