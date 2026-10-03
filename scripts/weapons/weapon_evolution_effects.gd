class_name WeaponEvolutionEffects
extends Node2D

var weapon: WeaponInstance
var pools: Array[Dictionary] = []
var threads: Array[Dictionary] = []
var marks: Dictionary = {}
var flashes: Array[Dictionary] = []
var proc_wait: float = 0.0
var drill_charge: int = 0
var drill_target: int = 0
var charge_time: float = 0.0
var charge_origin: Vector2
var charge_direction: Vector2
var charge_damage: float = 0.0
var charge_critical: bool = false

func on_attack(targets: Array[Enemy], damage: float, critical: bool) -> bool:
	if weapon.data.evolution_kind == &"drill":
		if drill_target != targets[0].get_instance_id():
			drill_charge /= 2
			drill_target = targets[0].get_instance_id()
	if weapon.data.evolution_kind != &"revelation":
		return false
	charge_time = weapon.data.evolution_duration
	charge_origin = weapon.muzzle_position()
	charge_direction = weapon.aim
	charge_damage = damage
	charge_critical = critical
	return true

func on_hit(enemy: Enemy, amount: float, _critical: bool) -> void:
	var data := weapon.data
	match data.evolution_kind:
		&"storm":
			if proc_wait > 0:
				return
			proc_wait = data.evolution_interval
			pools.append({"at": enemy.global_position, "life": data.evolution_duration, "tick": 0.0, "damage": amount * data.evolution_damage_factor})
			if pools.size() > 4:
				pools.pop_front()
		&"thread":
			if proc_wait > 0 or enemy.health <= 0:
				return
			var other := _nearest(enemy, data.evolution_radius)
			if other == null:
				return
			proc_wait = data.evolution_interval
			threads.append({"a": enemy.get_instance_id(), "b": other.get_instance_id(), "origin": weapon.player.global_position, "length": enemy.global_position.distance_to(other.global_position), "life": data.evolution_duration, "damage": amount * data.evolution_damage_factor})
			if threads.size() > 3:
				threads.pop_front()
		&"drill":
			drill_charge += 1
			if drill_charge >= data.evolution_threshold:
				drill_charge = 0
				var origin := weapon.muzzle_position()
				var aim := origin.direction_to(enemy.global_position)
				var end := origin + aim * data.evolution_radius
				_line_damage(origin, end, amount * data.evolution_damage_factor, data.attack_width * 1.5, false)
				_flash(origin, end, true, aim, data.evolution_radius)
		&"trinity":
			var id := enemy.get_instance_id()
			if marks.has(id):
				marks.erase(id)
				if proc_wait <= 0:
					proc_wait = data.evolution_interval
					for target in _enemies():
						if target.global_position.distance_to(enemy.global_position) <= data.evolution_radius + target.data.radius:
							target.take_damage(amount * data.evolution_damage_factor, null, false, &"evolution")
					_flash(enemy.global_position - Vector2(30, 0), enemy.global_position + Vector2(30, 0))
			else:
				marks[id] = data.evolution_duration

func _physics_process(delta: float) -> void:
	proc_wait = maxf(proc_wait - delta, 0)
	for id in marks.keys():
		marks[id] = float(marks[id]) - delta
		if float(marks[id]) <= 0 or not is_instance_valid(instance_from_id(id)):
			marks.erase(id)
	for index in range(flashes.size() - 1, -1, -1):
		flashes[index].life -= delta
		if flashes[index].life <= 0:
			flashes.remove_at(index)
	for index in range(pools.size() - 1, -1, -1):
		var pool := pools[index]
		pool.life -= delta
		pool.tick -= delta
		if pool.life <= 0:
			pools.remove_at(index)
			continue
		if pool.tick <= 0:
			pool.tick = weapon.data.evolution_interval
			var last: Enemy
			for enemy in _enemies():
				if enemy.global_position.distance_to(pool.at) <= weapon.data.evolution_radius + enemy.data.radius:
					enemy.apply_wet(1.0)
					enemy.take_damage(pool.damage, null, false, &"evolution")
					if last != null:
						_flash(last.global_position, enemy.global_position)
					last = enemy
	for index in range(threads.size() - 1, -1, -1):
		var thread := threads[index]
		thread.life -= delta
		var a := instance_from_id(thread.a) as Enemy
		var b := instance_from_id(thread.b) as Enemy
		if not is_instance_valid(a) or not is_instance_valid(b) or a.health <= 0 or b.health <= 0 or thread.life <= 0:
			threads.remove_at(index)
			continue
		if weapon.player.global_position.distance_to(thread.origin) >= weapon.data.evolution_threshold or a.global_position.distance_to(b.global_position) > float(thread.length) * 1.25:
			_line_damage(a.global_position, b.global_position, thread.damage, 18, true)
			_flash(a.global_position, b.global_position)
			threads.remove_at(index)
	if charge_time > 0:
		weapon._track_beam()
		charge_origin = weapon.muzzle_position()
		charge_direction = weapon.aim
		charge_time = maxf(charge_time - delta, 0)
		if charge_time <= 0:
			_release_beam()
	queue_redraw()

func _release_beam() -> void:
	charge_origin = weapon.muzzle_position()
	charge_direction = weapon.aim
	var directions: Array[Vector2] = [charge_direction]
	if charge_critical:
		directions.append(charge_direction.rotated(-0.35))
		directions.append(charge_direction.rotated(0.35))
	for index in directions.size():
		var end := charge_origin + directions[index] * weapon.data.range_at_tier(weapon.tier)
		var damage := charge_damage * (1.0 if index == 0 else weapon.data.evolution_damage_factor)
		for enemy in _enemies():
			var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, charge_origin, end)
			if closest.distance_to(enemy.global_position) <= weapon.data.attack_width * 0.5 + enemy.data.radius:
				WeaponAttackShapes.hit(enemy, weapon.data, weapon.tier, damage, charge_critical, weapon.player.items, directions[index])
		_flash(charge_origin, end, true, directions[index], weapon.data.range_at_tier(weapon.tier), directions[index].angle() - charge_direction.angle())

func _line_damage(start: Vector2, end: Vector2, amount: float, width: float, bleed: bool) -> void:
	for enemy in _enemies():
		var closest := Geometry2D.get_closest_point_to_segment(enemy.global_position, start, end)
		if closest.distance_to(enemy.global_position) <= width * 0.5 + enemy.data.radius:
			enemy.take_damage(amount, null, false, &"evolution")
			if bleed and enemy.health > 0:
				enemy.apply_bleed(weapon.data.bleed_dps * weapon.player.stats.damage_factor(), weapon.data.bleed_duration, 3)

func _enemies() -> Array[Enemy]:
	var result: Array[Enemy] = []
	for node in get_tree().get_nodes_in_group("enemies"):
		var enemy := node as Enemy
		if enemy != null and enemy.health > 0:
			result.append(enemy)
	return result

func _nearest(excluded: Enemy, radius: float) -> Enemy:
	var result: Enemy
	var best := radius * radius
	for enemy in _enemies():
		var distance := enemy.global_position.distance_squared_to(excluded.global_position)
		if enemy != excluded and distance < best:
			best = distance
			result = enemy
	return result

func _flash(start: Vector2, end: Vector2, mounted: bool = false, direction: Vector2 = Vector2.ZERO, reach: float = 0.0, angle: float = 0.0) -> void:
	flashes.append({"a": start, "b": end, "life": 0.22, "mounted": mounted, "direction": direction, "reach": reach, "angle": angle})
	if flashes.size() > 32:
		flashes.pop_front()

func _draw() -> void:
	if weapon == null:
		return
	var color := weapon.data.projectile_color
	for pool in pools:
		draw_circle(to_local(pool.at), weapon.data.evolution_radius, Color(color, 0.08))
		draw_arc(to_local(pool.at), weapon.data.evolution_radius, 0, TAU, 32, Color(color, 0.4), 2)
	for thread in threads:
		var a := instance_from_id(thread.a) as Enemy
		var b := instance_from_id(thread.b) as Enemy
		if is_instance_valid(a) and is_instance_valid(b):
			draw_line(to_local(a.global_position), to_local(b.global_position), Color(color, 0.6), 2)
	for id in marks:
		var enemy := instance_from_id(id) as Enemy
		if is_instance_valid(enemy):
			draw_arc(to_local(enemy.global_position), enemy.data.radius + 5, 0, TAU, 16, Color(color, 0.65), 2)
	for flash in flashes:
		var line := flash_segment(flash)
		var width := weapon.data.attack_width if weapon.data.evolution_kind == &"revelation" and flash.get("mounted", false) else 3.0
		draw_line(to_local(line[0]), to_local(line[1]), Color(color, float(flash.life) / 0.22 * 0.18), width)
		draw_line(to_local(line[0]), to_local(line[1]), Color(color, float(flash.life) / 0.22), 3)
	if charge_time > 0:
		var start := weapon.muzzle_position()
		draw_line(to_local(start), to_local(start + weapon.aim * weapon.data.range_at_tier(weapon.tier)), Color(color, 0.4), 2)
		var pulse := 6.0 + (1.0 - charge_time / weapon.data.evolution_duration) * 7.0
		draw_arc(to_local(weapon.muzzle_position()), pulse, 0, TAU, 24, Color(color, 0.8), 2)

func flash_segment(flash: Dictionary) -> PackedVector2Array:
	if not flash.get("mounted", false):
		return PackedVector2Array([flash.a, flash.b])
	var start := weapon.muzzle_position()
	var direction: Vector2 = weapon.aim.rotated(float(flash.angle)) if weapon.data.evolution_kind == &"revelation" else flash.direction
	return PackedVector2Array([start, start + direction * float(flash.reach)])

func save_state(indices: Dictionary) -> Dictionary:
	var saved_flashes: Array[Dictionary] = []
	for flash in flashes:
		saved_flashes.append({"ax": flash.a.x, "ay": flash.a.y, "bx": flash.b.x, "by": flash.b.y,
			"life": flash.life, "mounted": flash.get("mounted", false), "dx": flash.direction.x,
			"dy": flash.direction.y, "reach": flash.reach, "angle": flash.angle})
	var saved_pools: Array[Dictionary] = []
	for pool in pools:
		saved_pools.append({"x": pool.at.x, "y": pool.at.y, "life": pool.life, "tick": pool.tick, "damage": pool.damage})
	var saved_threads: Array[Dictionary] = []
	for thread in threads:
		if indices.has(thread.a) and indices.has(thread.b):
			saved_threads.append({"a": indices[thread.a], "b": indices[thread.b], "x": thread.origin.x, "y": thread.origin.y, "length": thread.length, "life": thread.life, "damage": thread.damage})
	var saved_marks: Array[Dictionary] = []
	for id in marks:
		if indices.has(id):
			saved_marks.append({"enemy": indices[id], "life": marks[id]})
	return {"flashes": saved_flashes, "pools": saved_pools, "threads": saved_threads, "marks": saved_marks, "wait": proc_wait, "drill": drill_charge, "target": indices.get(drill_target, -1), "charge": charge_time, "x": charge_origin.x, "y": charge_origin.y, "dx": charge_direction.x, "dy": charge_direction.y, "damage": charge_damage, "critical": charge_critical}

func restore_state(saved: Dictionary, enemies: Array[Node]) -> void:
	pools.clear()
	threads.clear()
	marks.clear()
	flashes.clear()
	for entry in saved.get("flashes", []):
		if flashes.size() < 32:
			flashes.append({"a": Vector2(entry.ax, entry.ay), "b": Vector2(entry.bx, entry.by), "life": clampf(entry.life, 0, 0.22),
				"mounted": bool(entry.get("mounted", false)), "direction": Vector2(entry.get("dx", 1), entry.get("dy", 0)),
				"reach": maxf(entry.get("reach", 0), 0), "angle": float(entry.get("angle", 0))})
	proc_wait = clampf(float(saved.get("wait", 0)), 0, weapon.data.evolution_interval)
	drill_charge = clampi(int(saved.get("drill", 0)), 0, weapon.data.evolution_threshold - 1)
	drill_target = _restored_id(int(saved.get("target", -1)), enemies)
	charge_time = clampf(float(saved.get("charge", 0)), 0, weapon.data.evolution_duration)
	charge_origin = Vector2(float(saved.get("x", 0)), float(saved.get("y", 0)))
	charge_direction = Vector2(float(saved.get("dx", 1)), float(saved.get("dy", 0))).normalized()
	charge_damage = maxf(float(saved.get("damage", 0)), 0)
	charge_critical = bool(saved.get("critical", false))
	for entry in saved.get("pools", []):
		if pools.size() < 4:
			pools.append({"at": Vector2(entry.x, entry.y), "life": clampf(entry.life, 0, weapon.data.evolution_duration), "tick": clampf(entry.tick, 0, weapon.data.evolution_interval), "damage": maxf(entry.damage, 0)})
	for entry in saved.get("threads", []):
		var a := _restored_id(int(entry.a), enemies)
		var b := _restored_id(int(entry.b), enemies)
		if a > 0 and b > 0 and threads.size() < 3:
			threads.append({"a": a, "b": b, "origin": Vector2(entry.x, entry.y), "length": maxf(entry.length, 1), "life": clampf(entry.life, 0, weapon.data.evolution_duration), "damage": maxf(entry.damage, 0)})
	for entry in saved.get("marks", []):
		var id := _restored_id(int(entry.enemy), enemies)
		if id > 0:
			marks[id] = clampf(entry.life, 0, weapon.data.evolution_duration)

func _restored_id(index: int, enemies: Array[Node]) -> int:
	return enemies[index].get_instance_id() if index >= 0 and index < enemies.size() else 0
