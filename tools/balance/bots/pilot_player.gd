extends "res://tools/balance/comparison_player.gd"

var probe_dash := false

func _physics_process(delta: float) -> void:
	if probe_dash:
		probe_dash = false
		try_dash()
	super._physics_process(delta)

func _unhandled_input(_event: InputEvent) -> void:
	# Native spectators must not change a measured run with movement/dash input.
	pass
