class_name WeaponStrike
extends RefCounted

var damage: float = 0.0
var critical: bool = false
var hit_ids: Dictionary[int, bool] = {}
var target_id: int = 0


func begin(amount: float, is_critical: bool, target: Enemy) -> void:
	damage = amount
	critical = is_critical
	target_id = target.get_instance_id()
	hit_ids.clear()


func tick(weapon: WeaponInstance, from_progress: float, to_progress: float) -> void:
	var start := maxf(from_progress, WeaponMotion.ACTIVE_START)
	var end := minf(to_progress, WeaponMotion.ACTIVE_END)
	if end < start:
		return
	# Sample the swept weapon path, including skipped physics frames/high attack speed.
	var steps := maxi(ceili((end - start) / 0.025), 1)
	var enemies: Array[Enemy] = []
	var candidates: Array[Enemy] = []
	if weapon.data.attack_mode == &"melee":
		var target := instance_from_id(target_id) as Enemy if target_id != 0 else null
		if is_instance_valid(target) and not target.is_queued_for_deletion():
			candidates.append(target)
	else:
		candidates = weapon.player.nearby_enemies(weapon.player.global_position, weapon.data.range_at_tier(weapon.tier))
	for enemy in candidates:
		if enemy == null or enemy.health <= 0.0 or hit_ids.has(enemy.get_instance_id()):
			continue
		if weapon.data.attack_mode == &"melee" and enemy.get_instance_id() != target_id:
			continue
		if WeaponAttackShapes.contains(weapon.data, weapon.tier, weapon.player.global_position, weapon.aim, enemy.global_position, enemy.data.radius):
			enemies.append(enemy)
	if enemies.is_empty():
		return
	for index in range(steps + 1):
		var progress := lerpf(start, end, float(index) / float(steps))
		var pose_data := WeaponMotion.pose(weapon.data, weapon.tier, weapon.home_position, weapon.aim, progress, weapon.idle_time, weapon.aim_distance, weapon.visual_density)
		var blade := WeaponMotion.segment(weapon.data, pose_data)
		var grip := weapon.player.global_position + blade[0]
		var tip := weapon.player.global_position + blade[1]
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.health <= 0.0:
				continue
			var id := enemy.get_instance_id()
			if hit_ids.has(id):
				continue
			var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, grip, tip)
			var radius := enemy.data.radius + weapon.data.attack_width * 0.5
			if closest.distance_squared_to(enemy.global_position) <= radius * radius:
				hit_ids[id] = true
				WeaponAttackShapes.hit(enemy, weapon.data, weapon.tier, damage, critical, weapon.player.items, weapon.aim)
