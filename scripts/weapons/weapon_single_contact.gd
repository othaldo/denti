class_name WeaponSingleContact
extends RefCounted
## Bounded contacts on the actual blade, with optional replacement of a dead target.


static func tick(strike: WeaponStrike, weapon: WeaponInstance, start: float, end: float) -> void:
	if strike.contact_hits >= strike.contact_limit: return
	var target := instance_from_id(strike.target_id) as Enemy if strike.target_id != 0 else null
	var target_alive := is_instance_valid(target) and not target.is_queued_for_deletion() and target.health > 0
	if strike.contact_hits == 0 and not target_alive and not weapon.data.contact_retarget: return
	var candidates: Array[Enemy] = []
	if strike.contact_hits == 0 and target_alive: candidates.append(target)
	if strike.contact_limit > 1 or strike.contact_hits > 0 or not target_alive:
		var nearby := weapon.player.nearby_enemies(weapon.player.global_position, weapon.data.range_at_tier(weapon.tier))
		nearby.sort_custom(func(a: Enemy, b: Enemy):
			return weapon.aim.dot(a.global_position - weapon.player.global_position) < weapon.aim.dot(b.global_position - weapon.player.global_position))
		for enemy in nearby:
			if enemy != target or not target_alive: candidates.append(enemy)
	var steps := maxi(ceili((end - start) / 0.025), 1)
	for step in range(steps + 1):
		var progress := lerpf(start, end, float(step) / steps)
		var pose := WeaponMotion.pose(weapon.data, weapon.tier, weapon.home_position, weapon.aim, progress, weapon.idle_time, weapon.aim_distance, weapon.visual_density)
		var blade := WeaponMotion.segment(weapon.data, pose)
		var grip := weapon.player.global_position + blade[0]
		var tip := weapon.player.global_position + blade[1]
		for enemy in candidates:
			if not is_instance_valid(enemy) or enemy.is_queued_for_deletion() or enemy.health <= 0: continue
			if strike.hit_ids.has(enemy.get_instance_id()): continue
			var offset := enemy.global_position - weapon.player.global_position
			if weapon.aim.dot(offset) < 0: continue
			if strike.contact_hits == 0 and target_alive and enemy != target: continue
			# Follow-up contacts only continue forward from the first actual impact.
			if strike.contact_hits > 0 and weapon.aim.dot(enemy.global_position - strike.primary_contact) < 0: continue
			if not WeaponAttackShapes.contains(weapon.data, weapon.tier, weapon.player.global_position, weapon.aim, enemy.global_position, enemy.data.radius): continue
			var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, grip, tip)
			var radius := enemy.data.radius + weapon.data.attack_width * 0.5
			if closest.distance_squared_to(enemy.global_position) > radius * radius: continue
			var factor := 1.0 if strike.contact_hits == 0 else weapon.data.contact_extra_damage
			if strike.contact_hits == 0: strike.primary_contact = enemy.global_position
			strike.contact_hits += 1
			strike.hit_ids[enemy.get_instance_id()] = true
			WeaponAttackShapes.hit(enemy, weapon.data, weapon.tier, strike.damage * factor, strike.critical, weapon.player.items, weapon.aim, weapon.affixes, factor, true, weapon.instance_uid)
			if strike.contact_hits >= strike.contact_limit: return
