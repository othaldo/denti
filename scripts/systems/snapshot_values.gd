class_name SnapshotValues
extends RefCounted


static func is_number(value: Variant) -> bool:
	return (value is float or value is int) and is_finite(float(value))


static func is_vector(value: Variant) -> bool:
	return value is Array and value.size() == 2 and is_number(value[0]) and is_number(value[1])


static func vector_data(value: Vector2) -> Array[float]:
	return [value.x, value.y]


static func read_vector(value: Variant) -> Vector2:
	if value is Array and value.size() >= 2:
		return Vector2(float(value[0]), float(value[1]))
	return Vector2.ZERO
