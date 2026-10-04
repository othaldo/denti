class_name EnemyProjectilePool
extends Node2D

# Idle bullets stay outside the scene tree: no callbacks, drawings or saves.
const PREPARE_COUNT := 384
const MAX_IDLE := 768
var idle: Array[AcidProjectile] = []
var created := 0

func _ready() -> void:
	if DisplayServer.get_name() != "headless":
		prepare()

func prepare(count: int = PREPARE_COUNT) -> void:
	for index in maxi(count - idle.size(), 0):
		idle.append(_create())

func _create() -> AcidProjectile:
	var projectile := AcidProjectile.new()
	created += 1
	projectile.pool = self
	# Prepare both sprite nodes before combat. Launch selects the real data.
	projectile.launch(Vector2.ZERO, Vector2.RIGHT, 0, 0, null, EnemyProjectilePatterns.SPACE_ORB_COLOR, 31, 21.7)
	projectile.set_physics_process(false)
	return projectile

func acquire() -> AcidProjectile:
	var projectile: AcidProjectile = _create() if idle.is_empty() else idle.pop_back()
	projectile.visible = true
	add_child(projectile)
	projectile.set_physics_process(true)
	return projectile

func recycle(projectile: AcidProjectile) -> void:
	projectile.set_physics_process(false)
	projectile.visible = false
	projectile.target = null
	projectile.inflicted_statuses = []
	remove_child(projectile)
	if idle.size() < MAX_IDLE:
		idle.append(projectile)
	else:
		projectile.queue_free()

func _exit_tree() -> void:
	for projectile in idle:
		projectile.free()
	idle.clear()
