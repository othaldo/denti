extends "res://tools/balance/bots/pilot_player.gd"
## A diagnostic HP reserve must not shorten the normal damage-based hit frames.
var reference_max_health := 100.0

func take_hit(amount: float, inflicted_statuses: Array[Dictionary] = []) -> float:
	var reserve_max := stats.max_health
	stats.max_health = reference_max_health
	var actual := super.take_hit(amount, inflicted_statuses)
	stats.max_health = reserve_max
	return actual
