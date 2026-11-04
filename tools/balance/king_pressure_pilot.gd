extends RefCounted
const NAVIGATION = preload("res://tools/balance/king_pressure_navigation.gd")
var goal := -1
var previous_state := -1
var trial_index := -1
var escape := Vector2.ZERO
var navigation := NAVIGATION.new()

func destination(trial: KingPressureTrial) -> Vector2:
	var player := trial.encounter.enemy.target
	if trial_index != trial.trial_index:
		trial_index = trial.trial_index
		goal = -1
		previous_state = -1
		navigation = NAVIGATION.new()
	if goal < 0 or trial.valves[goal].broken:
		goal = -1
		for index in trial.valves.size():
			if trial.valves[index].broken: continue
			if goal < 0 or player.position.distance_to(trial.stance(index)) < player.position.distance_to(trial.stance(goal)): goal = index
	var target := trial.stance(goal) if goal >= 0 else player.position
	target = navigation.safe_target(target, trial.anchor.direction_to(target), player.position, trial)
	if trial.state in [KingPressureTrial.State.LOCKED, KingPressureTrial.State.FIRING]:
		if previous_state not in [KingPressureTrial.State.LOCKED, KingPressureTrial.State.FIRING]:
			var sideways := trial.aim.orthogonal()
			var next_goal := target
			var next_distance := INF
			for index in trial.valves.size():
				if trial.valves[index].broken or index == trial.hit_valve: continue
				var at := trial.stance(index)
				if at.distance_to(player.position) < next_distance:
					next_distance = at.distance_to(player.position)
					next_goal = at
			var side := signf((next_goal - player.position).dot(sideways))
			if is_zero_approx(side): side = 1
			var near := Geometry2D.get_closest_point_to_segment(player.position, trial.origin, trial.destination)
			escape = near + sideways * side * 70
		target = navigation.safe_target(escape, trial.aim, player.position, trial)
	previous_state = trial.state
	return navigation.next(player.position, target, trial)
