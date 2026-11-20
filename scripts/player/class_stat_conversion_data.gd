class_name ClassStatConversionData
extends Resource

@export var source_stat: StringName
@export var target_stat: StringName
@export var factor: float = 0.0
@export var positive_only: bool = true

func valid() -> bool:
	return source_stat != target_stat and source_stat in PlayerStatKeys.ALL and target_stat in PlayerStatKeys.ALL and is_finite(factor)
