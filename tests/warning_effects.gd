extends "res://tests/support/test_runtime.gd"

var failures: Array[String] = []

func _initialize() -> void: call_deferred("_run")
func _check(condition: bool, message: String) -> void:
	if not condition:
		failures.append(message)
		push_error(message)

func _run() -> void:
	var image := WarningEffects.ATLAS.get_image()
	var data := load("res://data/encounters/count_cloak.tres") as CloakEncounterData
	var prepared = WarningEffects.PREPARED
	_check(WarningEffects.ATLAS == AttackEffects.ATLAS, "warnings no longer share the attack atlas")
	_check(data.strike(0).reach == prepared.FAN_REACH and data.strike(0).half_angle_degrees == prepared.FAN_ANGLE and data.strike(0).edge_half_angle_degrees == prepared.EDGE_ANGLE, "fan profile changed: regenerate the warning atlas")
	_check(data.strike(1).reach == prepared.THRUST_REACH and data.strike(1).half_angle_degrees == prepared.THRUST_ANGLE, "thrust profile changed: regenerate the warning atlas")
	_check(data.strike(2).inner_radius == prepared.RING_INNER and data.strike(2).reach == prepared.RING_OUTER, "ring profile changed: regenerate the warning atlas")
	for row in [[Vector2i(1024, 0), 480, prepared.FAN_REACH], [Vector2i(1024, 480), 288, prepared.FAN_REACH], [Vector2i(1024, 768), 224, prepared.THRUST_REACH]]:
		var center: Vector2i = row[0] + Vector2i(8, int(row[1]) / 2)
		_check(image.get_pixelv(center + Vector2i(int(row[2]), 0)).a > 0.6, "sector boundary moved away from the actual reach")
		_check(image.get_pixelv(center + Vector2i(int(row[2]) + 8, 0)).a < 0.01, "sector leaks beyond its padded edge")
		_check(image.get_pixelv(center + Vector2i(50, 0)).a > 0.05 and image.get_pixelv(center + Vector2i(50, 0)).a < 0.1, "sector fill hides the arena or vanishes")
	var ring_center := Vector2i(1328, 1296)
	_check(image.get_pixelv(ring_center).a == 0, "ring texture fills the safe core")
	for radius in [prepared.RING_INNER, prepared.RING_OUTER]:
		for axis in [Vector2i.RIGHT, Vector2i.LEFT, Vector2i.UP, Vector2i.DOWN]:
			_check(image.get_pixelv(ring_center + axis * int(radius)).a > 0.6, "ring contour does not mark its damage boundary")
	_check(image.get_pixelv(ring_center + Vector2i(100, 0)).a == 0, "ring texture obscures the usable inner safe area")
	for frame in 4:
		var at := Vector2i(1024 + frame * 256, WarningEffects.LANE_Y)
		_check(image.get_pixelv(at + Vector2i(4, 32)).a > 0.6 and image.get_pixelv(at + Vector2i(252, 32)).a > 0.6, "lane end caps lost the exact endpoints")
		_check(image.get_pixelv(at + Vector2i(120, 4)).a > 0.6 and image.get_pixelv(at + Vector2i(120, 60)).a > 0.6, "lane width no longer matches the threat width")
		for x in 256:
			_check(image.get_pixelv(at + Vector2i(x, 0)).a == 0 and image.get_pixelv(at + Vector2i(x, 63)).a == 0, "lane atlas has no transparent gutter")
	var first := image.get_region(Rect2i(1040, 1600, 224, 64))
	_check(image.get_pixel(1056, 1760).a > 0.25 and image.get_pixel(1056, 1728).a == 0, "charge ribbon lost its soft core or transparent feather")
	_check(image.get_pixel(1090, 1760).a < image.get_pixel(1148, 1760).a, "charge tail no longer fades into the floor")
	_check(image.get_pixel(1248, 1760).a > 0.5 and image.get_pixel(1279, 1728).a == 0, "impact dust lost its core or transparent gutter")
	_check(image.get_pixel(1248 + 27, 1760).a < image.get_pixel(1248 + 14, 1760).a, "impact dust gained a hard bright ring")
	var second := image.get_region(Rect2i(1296, 1600, 224, 64))
	_check(first.get_data() != second.get_data(), "lane light phases are identical")
	WarningEffects.prepare()
	var ids: Array[int] = []
	for style in WarningEffects.lane_styles: ids.append(style.get_instance_id())
	for repeat in 100: WarningEffects.prepare()
	_check(WarningEffects.lane_styles.size() == 15, "warning styles allocate again during reuse")
	_check(image.get_pixel(1144, 1696).a == 0 and image.get_pixel(1144, 1668).a > 0.6, "density outline layer fills the floor or loses its boundary")
	for index in ids.size():
		var style := WarningEffects.lane_styles[index]
		_check(style.get_instance_id() == ids[index] and style.texture == WarningEffects.ATLAS and style.axis_stretch_horizontal == StyleBoxTexture.AXIS_STRETCH_MODE_TILE, "lane replaced its cached tiled styles")
	if failures.is_empty(): print("PASS warning_effects: shared atlas, profile geometry, safe core, exact caps/width, light phases and cached tiling")
	finish(0 if failures.is_empty() else 1)
