class_name WeaponMotion
extends RefCounted

const ACTIVE_START := 0.22
const ACTIVE_END := 0.72


static func is_contact(data: WeaponData) -> bool:
	return WeaponLayout.is_contact(data)


static func base_scale(data: WeaponData, density: float = 1.0) -> float:
	return WeaponLayout.visual_size(data, density) / maxf(data.held_texture().get_size().x, data.held_texture().get_size().y)


static func tip_local(data: WeaponData) -> Vector2:
	return (data.tip_anchor - data.grip_anchor) * data.held_texture().get_size()


static func hand_position(home: Vector2, direction: Vector2) -> Vector2:
	# Keep distinct hands rather than collapsing the whole loadout toward its aim.
	var lane := home.y * 0.55 + signf(home.x) * 30.0
	return direction * 40.0 + direction.orthogonal() * lane


static func pose(data: WeaponData, tier: int, home: Vector2, aim: Vector2, progress: float, idle_time: float, target_distance: float = INF, density: float = 1.0) -> Dictionary:
	var active := progress >= 0.0
	var side := -1.0 if aim.x < -0.02 else 1.0
	var factor := base_scale(data, density)
	var rotation := 0.0
	var scale := Vector2.ONE * factor
	var grip := home + Vector2(0, sin(idle_time * 3.4) * 1.0)
	var pulse := sin(clampf(progress, 0.0, 1.0) * PI) if active else 0.0
	if data.held_style == "aimed":
		scale.y *= side
		rotation = aim.angle() + deg_to_rad(data.visual_angle_degrees) * side
		if not is_contact(data) and active:
			var nozzle := home + aim * minf(24.0, maxf(target_distance - home.length() - 12.0, 8.0))
			if data.attack_mode in [&"projectile", &"beam"]:
				nozzle = home + aim * minf(42.0, maxf(target_distance - home.length() - 12.0, 8.0))
			grip = nozzle - (tip_local(data) * scale).rotated(rotation)
	elif data.held_style == "upright":
		scale.x *= side
	else:
		scale.x *= -1.0 if home.x < 0.0 else 1.0
	if data.upright_at_rest and not active:
		scale = Vector2(side, 1.0) * factor
		rotation = 0.0
	if is_contact(data) and active:
		var rest_rotation := rotation
		scale = Vector2.ONE * factor
		if data.held_style == "staff":
			scale.x *= -1.0 if home.x < 0.0 else 1.0
		var native_angle := (tip_local(data) * scale).angle()
		var action := clampf((progress - ACTIVE_START) / (ACTIVE_END - ACTIVE_START), 0.0, 1.0)
		var reach := data.range_at_tier(tier)
		var length := tip_local(data).length() * factor
		var angle := aim.angle()
		var extension := sin(action * PI * 0.5)
		match data.attack_animation:
			"slash":
				angle += lerpf(-deg_to_rad(data.arc_degrees * 0.5), deg_to_rad(data.arc_degrees * 0.5), action)
			"spin":
				angle += -PI + action * TAU
			"drill", "polish":
				extension = sin(action * PI)
				angle += sin(action * TAU * 3.0) * 0.045
		var hand_distance := maxf(reach - length, 12.0)
		if data.attack_animation in ["slash", "spin"]:
			# A short blade must not orbit outside a nearby target's body.
			# Distant targets still use the full extension up to the weapon's range.
			hand_distance = minf(hand_distance, maxf(target_distance - data.attack_width * 0.5, 12.0))
		var attack_grip := Vector2.RIGHT.rotated(angle) * hand_distance
		if data.attack_animation in ["thrust", "drill", "polish"]:
			attack_grip = aim * lerpf(12.0, hand_distance, extension)
		rotation = angle - native_angle
		if data.held_style == "aimed":
			# Powered tools keep their handle below the working head while advancing.
			scale.y *= side
			rotation = angle + deg_to_rad(data.visual_angle_degrees) * side
			var head_distance := length + lerpf(12.0, hand_distance, extension)
			attack_grip = aim * head_distance - (tip_local(data) * scale).rotated(rotation)
		var weight := clampf(progress / ACTIVE_START, 0.0, 1.0)
		if progress > ACTIVE_END:
			weight = 1.0 - (progress - ACTIVE_END) / (1.0 - ACTIVE_END)
		grip = home.lerp(attack_grip, weight)
		# Recover into the upright resting pose without spinning through a full turn.
		rotation = lerp_angle(rest_rotation, rotation, weight)
	elif active:
		match data.attack_animation:
			"shoot", "lob":
				grip -= aim * sin(minf(progress / 0.3, 1.0) * PI) * (8.0 if data.attack_animation == "shoot" else 12.0)
			"pull":
				# Only the elastic bands/pouch deform; the painted fork stays rigid.
				grip -= aim * pulse * 2.0
			"spray":
				rotation += sin(progress * TAU * 2.0) * 0.045
	return {"position": grip, "rotation": rotation, "scale": scale}


static func segment(data: WeaponData, pose_data: Dictionary) -> PackedVector2Array:
	var grip: Vector2 = pose_data.position
	var tip := grip + (tip_local(data) * Vector2(pose_data.scale)).rotated(float(pose_data.rotation))
	return PackedVector2Array([grip, tip])
