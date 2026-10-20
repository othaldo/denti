class_name CountRigMotion
extends RefCounted
## A fast release between readable anticipation and a longer cloth follow-through.

const DURATION := 3.4
const TIMES := [0.0, 0.22, 0.68, 1.00, 1.09, 1.24, 1.48, 1.88, 1.97, 2.15, 2.65, 3.4]


static func combo() -> Animation:
	var animation := Animation.new()
	animation.length = DURATION
	animation.loop_mode = Animation.LOOP_LINEAR
	_rotation(animation, "Torso", [0, 0, -7, -9, 12, 5, 8, 9, -12, -5, 0, 0])
	_rotation(animation, "Torso/Head", [0, 0, 3, 4, -6, -2, -4, -4, 6, 2, 0, 0])
	_track(animation, "Skeleton2D/Torso:position", TIMES, [Vector2(0,-45), Vector2(0,-45), Vector2(-4,-48), Vector2(-5,-48), Vector2(7,-42), Vector2(2,-44), Vector2(3,-48), Vector2(5,-48), Vector2(-7,-42), Vector2(-2,-44), Vector2(0,-45), Vector2(0,-45)])
	_rotation(animation, "Torso/LeftShoulder", [-60, -60, -5, 2, -106, -116, -42, -40, -35, -44, -60, -60])
	_rotation(animation, "Torso/RightShoulder", [60, 60, -72, -85, -66, -62, -81, -94, 88, 102, 60, 60])
	_rotation(animation, "Torso/LeftShoulder/LeftMiddle", [0, 0, 8, 0, 27, -12, 4, 0, -8, 8, 0, 0], 0.035)
	_rotation(animation, "Torso/LeftShoulder/LeftMiddle/LeftTip", [0, 0, 12, 0, 18, -15, 6, 0, -6, 8, 0, 0], 0.065)
	_rotation(animation, "Torso/RightShoulder/RightMiddle", [0, 0, -8, 0, 8, -8, -6, 0, -27, 12, 0, 0], 0.035)
	_rotation(animation, "Torso/RightShoulder/RightMiddle/RightTip", [0, 0, -12, 0, 6, -8, -8, 0, -18, 15, 0, 0], 0.065)
	_rotation(animation, "Torso/Head/LeftAntenna", [0, -3, 6, 8, -18, 12, -5, -8, 18, -12, 2, 0], 0.045)
	_rotation(animation, "Torso/Head/RightAntenna", [0, 3, -6, -8, 16, -10, 5, 8, -16, 10, -2, 0], 0.055)
	_rotation(animation, "LeftFoot", [0, 0, -5, -7, 10, 0, 2, 4, -7, 0, 0, 0])
	_rotation(animation, "RightFoot", [0, 0, -2, -4, 7, 0, 5, 7, -10, 0, 0, 0])
	# A slap passes in front of the torso/collar, while the face stays readable.
	_track(animation, "LeftCloth:z_index", [0.0, 1.04, 1.30, DURATION], [3, 7, 3, 3], true)
	_track(animation, "RightCloth:z_index", [0.0, 1.92, 2.25, DURATION], [3, 7, 3, 3], true)
	return animation


static func _rotation(animation: Animation, bone: String, degrees: Array, delay: float = 0.0) -> void:
	var times: Array = []
	var values: Array = []
	for index in TIMES.size():
		times.append(TIMES[index] + delay if index > 0 and index < TIMES.size() - 1 else TIMES[index])
		values.append(deg_to_rad(float(degrees[index])))
	_track(animation, "Skeleton2D/" + bone + ":rotation", times, values)


static func _track(animation: Animation, path: String, times: Array, values: Array, discrete := false) -> void:
	var track := animation.add_track(Animation.TYPE_VALUE)
	animation.track_set_path(track, NodePath(path))
	if discrete:
		animation.value_track_set_update_mode(track, Animation.UPDATE_DISCRETE)
	for index in times.size():
		animation.track_insert_key(track, float(times[index]), values[index])
