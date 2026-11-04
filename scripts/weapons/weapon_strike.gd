class_name WeaponStrike
extends RefCounted

var damage: float = 0.0
var critical: bool = false
var hit_ids: Dictionary[int, bool] = {}
var target_id: int = 0
var contact_hits: int = 0
var contact_limit: int = 1
var primary_contact := Vector2.ZERO


func begin(amount: float, is_critical: bool, target: Enemy, max_contacts: int = 1) -> void:
	damage = amount
	critical = is_critical
	target_id = target.get_instance_id()
	hit_ids.clear()
	contact_hits = 0
	contact_limit = clampi(max_contacts, 1, 4)
	primary_contact = Vector2.ZERO


func tick(weapon: WeaponInstance, from_progress: float, to_progress: float) -> void:
	var start := maxf(from_progress, WeaponMotion.ACTIVE_START)
	var end := minf(to_progress, WeaponMotion.ACTIVE_END)
	if end < start:
		return
	if weapon.data.attack_mode == &"melee" and (weapon.data.contact_retarget or weapon.data.contact_extra_targets > 0):
		WeaponSingleContact.tick(self, weapon, start, end)
		return
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
		if weapon.data.attack_animation == "floss_cut":
			if weapon.aim.dot(enemy.global_position - weapon.player.global_position) >= 0:
				enemies.append(enemy)
		elif WeaponAttackShapes.contains(weapon.data, weapon.tier, weapon.player.global_position, weapon.aim, enemy.global_position, enemy.data.radius):
			enemies.append(enemy)
	if enemies.is_empty():
		return
	if weapon.data.attack_animation == "floss_cut":
		var paths := WeaponFlossMotion.swept_curves(weapon.data, weapon.tier, weapon.home_position, weapon.aim, start, end, weapon.visual_density)
		for enemy in enemies:
			if not is_instance_valid(enemy) or enemy.health <= 0: continue
			var offset := enemy.global_position - weapon.player.global_position
			var hit_radius := enemy.data.radius + weapon.data.attack_width * 0.5
			var touching := false
			for path in paths:
				if WeaponFlossMotion.touches(path, offset, hit_radius):
					touching = true
					break
			if touching:
				hit_ids[enemy.get_instance_id()] = true
				var at := enemy.global_position
				var outward := offset.normalized() if not offset.is_zero_approx() else weapon.aim
				var dealt := WeaponAttackShapes.hit(enemy, weapon.data, weapon.tier, damage, critical, weapon.player.items, outward, weapon.affixes, 1.0, true, weapon.instance_uid)
				if dealt > 0 and weapon.data.element_skin == &"":
					ElementImpactBatch.emit_from(enemy, &"bleed", at, outward, 30)
		return
	# Sample the rigid blade; the floss arc above uses its exact swept sector.
	var sample_step := 0.025
	if weapon.data.attack_animation == "spin" and weapon.data.spin_grip_radius > 0:
		# Range upgrades enlarge the visible spin. Keep the arc between samples
		# shorter than a candidate's hit radius so small enemies cannot fall in it.
		var hit_radius := INF
		for enemy in enemies: hit_radius = minf(hit_radius, enemy.data.radius + weapon.data.attack_width * 0.5)
		sample_step = minf(sample_step, (WeaponMotion.ACTIVE_END - WeaponMotion.ACTIVE_START) * hit_radius / (TAU * maxf(weapon.data.range_at_tier(weapon.tier), 1.0)))
	var steps := maxi(ceili((end - start) / sample_step), 1)
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
				if weapon.data.attack_mode == &"melee":
					contact_hits += 1
					primary_contact = enemy.global_position
				var outward := enemy.global_position - weapon.player.global_position if weapon.data.attack_mode == &"area" else weapon.aim
				outward = outward.normalized() if not outward.is_zero_approx() else weapon.aim
				WeaponAttackShapes.hit(enemy, weapon.data, weapon.tier, damage, critical, weapon.player.items, outward, weapon.affixes, 1.0, true, weapon.instance_uid)
