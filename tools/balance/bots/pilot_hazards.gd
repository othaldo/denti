extends RefCounted
## Evaluates only currently announced geometry, at its visible impact time.

const PLAYER_RADIUS := HazardGeometry.PLAYER_RADIUS
const SAFETY_MARGIN := 12.0

static func contains(hazard: Dictionary, point: Vector2) -> bool:
	return escape_distance(hazard, point) > 0.0

static func escape_distance(hazard: Dictionary, point: Vector2) -> float:
	var padding := PLAYER_RADIUS + SAFETY_MARGIN
	if hazard.get("shape", "circle") == "capsule":
		return maxf(float(hazard.radius) + padding - Geometry2D.get_closest_point_to_segment(point, hazard.position, hazard.end).distance_to(point), 0)
	var offset: Vector2 = point - Vector2(hazard.position)
	var distance := offset.length()
	var outer := float(hazard.radius) + padding - distance
	var inner := float(hazard.get("inner", 0))
	if outer <= 0 or inner > 0 and distance < inner - padding: return 0
	var escape := minf(outer, distance - inner + padding) if inner > 0 else outer
	if hazard.get("shape", "circle") == "sector" and float(hazard.angle) < PI:
		if distance <= padding: return minf(escape, padding - distance)
		var angle := absf(Vector2(hazard.direction).angle_to(offset))
		if angle > float(hazard.angle) + PI * 0.5: return 0
		var side := distance * sin(float(hazard.angle) - angle) + padding
		escape = minf(escape, side)
	return maxf(escape, 0)

static func risk(hazard: Dictionary, at: Vector2, velocity: Vector2, horizon: float) -> float:
	var first := maxf(float(hazard.time), 0)
	var last := minf(float(hazard.time) + float(hazard.get("duration", 0.1)), horizon)
	if first > horizon or last < 0 or last < first: return 0
	var result := 0.0
	# Moving through a warning before impact is legal. Only the active window
	# matters. Escape distance still distinguishes routes when no walk fully exits.
	for fraction in [0.0, 0.5, 1.0]:
		var seconds := lerpf(first, last, fraction)
		var escape := escape_distance(hazard, at + velocity * seconds)
		if escape > 0: result += 2.0 + minf(escape / 80.0, 3.0)
	return result / 3.0
