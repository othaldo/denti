class_name DashCollision
extends RefCounted

const CONTACT_RADIUS := 20.0

static func circle_fraction(start: Vector2, travel: Vector2, centre: Vector2, radius: float) -> float:
	var offset := start - centre
	var c := offset.length_squared() - radius * radius
	if c <= 0.0: return 0.0
	var a := travel.length_squared()
	if a <= 0.000001: return INF
	var b := offset.dot(travel)
	var discriminant := b * b - a * c
	if discriminant < 0.0: return INF
	var fraction := (-b - sqrt(discriminant)) / a
	return fraction if fraction >= 0.0 and fraction <= 1.0 else INF

static func move(player: Player, travel: Vector2, seconds: float) -> bool:
	var start := player.global_position
	var destination := (start + travel).clamp(Vector2.ONE * DentiArena.PLAYER_MARGIN, player.arena.arena_size - Vector2.ONE * DentiArena.PLAYER_MARGIN)
	var movement := destination - start
	var first := INF
	var obstacle: Enemy
	var candidates := player.enemies_on_segment(start, destination, CONTACT_RADIUS)
	# A locked enemy charge can enter the path from outside the spatial query.
	# Sweep relative motion as well, rather than treating that body as static.
	if is_instance_valid(player.enemy_index):
		for enemy in player.enemy_index.shadow_batch.enemies:
			if enemy.health > 0 and not enemy.is_queued_for_deletion() and not _charge_movement(enemy, seconds).is_zero_approx() and not candidates.has(enemy):
				candidates.append(enemy)
	for enemy in candidates:
		var relative := movement - _charge_movement(enemy, seconds)
		var fraction := circle_fraction(start, relative, enemy.global_position, enemy.data.radius + CONTACT_RADIUS)
		if fraction < first:
			first = fraction
			obstacle = enemy
	if obstacle != null:
		destination = start + movement * maxf(first - 0.0001, 0.0)
	var wall := player.move_and_collide(destination - start)
	if wall == null and is_instance_valid(obstacle):
		obstacle.try_contact_hit()
	return wall != null or obstacle != null or not destination.is_equal_approx(start + travel)

static func _charge_movement(enemy: Enemy, seconds: float) -> Vector2:
	if enemy.caramel_encounter != null:
		return enemy.caramel_encounter.rush_movement(seconds)
	if enemy.special_phase != Enemy.SpecialPhase.ACTIVE: return Vector2.ZERO
	var distance := enemy.data.attack_speed * enemy.overtime_speed_factor() * seconds
	if enemy.active_special_attack == EnemyData.SpecialAttack.BOSS and enemy.boss_move == Enemy.BossMove.CHARGE:
		distance *= enemy.difficulty.boss_movement_multiplier
		return enemy.global_position.move_toward(enemy.boss_dash_end, distance) - enemy.global_position
	if enemy.active_special_attack == EnemyData.SpecialAttack.DASH:
		var margin := DentiArena.WALL_WIDTH + enemy.data.radius + 6
		var destination := (enemy.global_position + enemy.special_direction * distance).clamp(Vector2.ONE * margin, enemy.target.arena.arena_size - Vector2.ONE * margin)
		return destination - enemy.global_position
	return Vector2.ZERO
