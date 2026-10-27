class_name WeaponFlossMotion
extends RefCounted
## Stationary root grips; only the connected strands extend and retract.

const GRIP_SPACING := 24.0
const START_RADIUS := 32.0
const SEGMENTS := 16
const CONTACT_STEP := 0.04


static func grip_positions(data: WeaponData, home: Vector2) -> PackedVector2Array:
	if data.floss_right_texture != null:
		return PackedVector2Array([home - Vector2(0, GRIP_SPACING * 0.5), home + Vector2(0, GRIP_SPACING * 0.5)])
	return PackedVector2Array([home])


static func pose(data: WeaponData, tier: int, home: Vector2, aim: Vector2, progress: float, density: float = 1.0) -> Dictionary:
	var grips := grip_positions(data, home)
	var rest_angle := 0.0 if home.x >= 0 else PI
	var heading := rest_angle
	var extension := 0.0
	var active := progress >= WeaponMotion.ACTIVE_START and progress <= WeaponMotion.ACTIVE_END
	if progress >= 0:
		if progress < WeaponMotion.ACTIVE_START:
			heading = lerp_angle(rest_angle, aim.angle(), smoothstep(0, WeaponMotion.ACTIVE_START, progress))
		elif active:
			heading = aim.angle()
			extension = clampf((progress - WeaponMotion.ACTIVE_START) / (WeaponMotion.ACTIVE_END - WeaponMotion.ACTIVE_START), 0, 1)
		else:
			var recover := smoothstep(WeaponMotion.ACTIVE_END, 1, progress)
			heading = lerp_angle(aim.angle(), rest_angle, recover)
			extension = 1 - recover
	var curves: Array[PackedVector2Array] = []
	var factor := WeaponMotion.base_scale(data, density)
	for index in grips.size():
		var anchor := data.grip_anchor if index == 0 else Vector2(1 - data.grip_anchor.x, data.grip_anchor.y)
		var port := data.floss_left_tip if index == 0 else data.floss_right_tip
		var native_axis := (port - anchor) * data.held_texture().get_size()
		var rotation := heading - native_axis.angle()
		var origin := grips[index] + (native_axis * factor).rotated(rotation)
		var side := 0.0 if grips.size() == 1 else (-0.5 if index == 0 else 0.5)
		var tip := origin + Vector2.from_angle(heading) * 9
		if progress >= 0:
			var launch := aim * START_RADIUS + aim.orthogonal() * side * data.floss_strand_spacing
			var maximum := aim * data.range_at_tier(tier) + aim.orthogonal() * side * data.floss_strand_spacing
			if progress < WeaponMotion.ACTIVE_START:
				tip = tip.lerp(launch, smoothstep(0, WeaponMotion.ACTIVE_START, progress))
			elif active:
				tip = launch.lerp(maximum, extension)
			else:
				tip = tip.lerp(maximum, extension)
		var points := PackedVector2Array()
		var normal := Vector2.from_angle(heading).orthogonal()
		for segment in SEGMENTS + 1:
			var t := float(segment) / SEGMENTS
			var wave := sin(t * TAU - extension * TAU) * sin(t * PI)
			var amplitude := data.floss_wave_amplitude if active else 5.0
			points.append(origin.lerp(tip, t) + normal * wave * amplitude)
		curves.append(points)
	return {"curve": curves[0], "strands": curves, "grips": grips, "heading": heading}


static func swept_curves(data: WeaponData, tier: int, home: Vector2, aim: Vector2, start: float, end: float, density: float) -> Array[PackedVector2Array]:
	var result: Array[PackedVector2Array] = []
	var steps := maxi(ceili((end - start) / CONTACT_STEP), 1)
	for index in steps + 1:
		var phase := lerpf(start, end, float(index) / steps)
		var sampled := pose(data, tier, home, aim, phase, density)
		result.append_array(sampled.strands)
	return result


static func touches(curve: PackedVector2Array, offset: Vector2, radius: float) -> bool:
	for index in curve.size() - 1:
		if Geometry2D.get_closest_point_to_segment(offset, curve[index], curve[index + 1]).distance_squared_to(offset) <= radius * radius:
			return true
	return false
