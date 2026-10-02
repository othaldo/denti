class_name EnemyProjectilePatterns
extends RefCounted

const PROJECTILE: PackedScene = preload("res://scenes/enemies/acid_projectile.tscn")
const BOSS_COLOR := Color(0.95, 0.32, 0.63)
const ACID_COLOR := Color(0.53, 0.88, 0.13)


static func radial_directions(count: int, gap_angle: float) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	if count <= 0:
		return directions
	for index in count:
		var angle := TAU * float(index) / float(count)
		if absf(wrapf(angle - gap_angle, -PI, PI)) < TAU / float(count) * 1.15:
			continue
		directions.append(Vector2.RIGHT.rotated(angle))
	return directions


static func fire_radial(parent: Node2D, at: Vector2, count: int, gap_angle: float, speed: float, damage: float, target: Player, tint: Color = BOSS_COLOR, statuses: Array[Dictionary] = []) -> void:
	for direction in radial_directions(count, gap_angle):
		_spawn(parent, at, direction, speed, damage, target, tint, 3.0, statuses)


static func fan_directions(aim: Vector2, count: int) -> Array[Vector2]:
	var directions: Array[Vector2] = []
	if count <= 0:
		return directions
	var center := aim.normalized() if aim.length_squared() > 0.01 else Vector2.RIGHT
	for index in count:
		var angle := (float(index) - float(count - 1) * 0.5) * 0.17
		directions.append(center.rotated(angle))
	return directions


static func fire_aimed_fan(parent: Node2D, at: Vector2, aim: Vector2, count: int, speed: float, damage: float, target: Player, tint: Color = BOSS_COLOR, lifetime: float = 3.0, statuses: Array[Dictionary] = []) -> void:
	for direction in fan_directions(aim, count):
		_spawn(parent, at, direction, speed, damage, target, tint, lifetime, statuses)


static func fire_lane(parent: Node2D, at: Vector2, aim: Vector2, count: int, spacing: float, speed: float, damage: float, target: Player, tint: Color = ACID_COLOR, statuses: Array[Dictionary] = []) -> void:
	var center := aim.normalized() if aim.length_squared() > 0.01 else Vector2.RIGHT
	var side := center.orthogonal()
	for index in count:
		var offset := (float(index) - float(count - 1) * 0.5) * spacing
		_spawn(parent, at + side * offset, center, speed, damage, target, tint, 2.8, statuses)


static func fire_space_orb(parent: Node2D, at: Vector2, aim: Vector2, speed: float, damage: float, radius: float, target: Player, statuses: Array[Dictionary] = []) -> void:
	var projectile: AcidProjectile = PROJECTILE.instantiate()
	parent.add_child(projectile)
	projectile.launch(at, aim, speed * 0.55, damage, target, Color(1.0, 0.43, 0.25), radius, radius * 0.7, statuses)
	projectile.lifetime = 3.8


static func _spawn(parent: Node2D, at: Vector2, direction: Vector2, speed: float, damage: float, target: Player, tint: Color, lifetime: float, statuses: Array[Dictionary] = []) -> void:
	var projectile: AcidProjectile = PROJECTILE.instantiate()
	parent.add_child(projectile)
	projectile.launch(at, direction, speed, damage, target, tint, 21.0, 9.0, statuses)
	projectile.lifetime = lifetime
