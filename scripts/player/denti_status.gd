class_name DentiStatus
extends RefCounted

enum Type { POISON, BLEED }
const NAMES: Array[String] = ["Vergiftet", "Blutung"]
const COLORS: Array[Color] = [Color(0.35, 0.92, 0.31), Color(0.96, 0.25, 0.43)]
const KEYS: Array[String] = ["poison", "bleed"]
const MAX_DURATION := 6.0
const MAX_TICK_DAMAGE := 12.0
const TICK_INTERVAL := 1.0

static func sanitize(payload: Dictionary) -> Dictionary:
	var kind := int(payload.get("kind", -1))
	if kind not in [Type.POISON, Type.BLEED]:
		return {}
	var damage := clampf(float(payload.get("damage", 0.0)), 0.0, MAX_TICK_DAMAGE)
	var duration := clampf(float(payload.get("duration", 0.0)), 0.0, MAX_DURATION)
	return {"kind": kind, "damage": damage, "duration": duration} if damage > 0.0 and duration > 0.0 else {}

static func sanitize_attacks(payloads: Array) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for payload in payloads:
		if payload is Dictionary:
			var clean := sanitize(payload)
			if not clean.is_empty() and result.size() < 2:
				result.append(clean)
	return result
