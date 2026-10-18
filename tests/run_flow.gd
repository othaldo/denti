extends "res://tests/support/test_runtime.gd"

func _initialize() -> void:
	var flow := RunFlow.new()
	for phase: RunFlow.Phase in RunFlow.Phase.values():
		flow.enter(phase)
		assert(flow.is_combat() == (phase in [RunFlow.Phase.COMBAT, RunFlow.Phase.BOSS_OVERTIME]))
		assert(flow.requires_pause() == (phase in [RunFlow.Phase.STARTER, RunFlow.Phase.REWARDS, RunFlow.Phase.SHOP, RunFlow.Phase.STORY, RunFlow.Phase.ENDED]))
	flow.set_phase_flag(RunFlow.Phase.SHOP, true)
	flow.set_phase_flag(RunFlow.Phase.COLLECTING, true)
	assert(flow.phase == RunFlow.Phase.COLLECTING)
	flow.set_phase_flag(RunFlow.Phase.SHOP, false)
	assert(flow.phase == RunFlow.Phase.COLLECTING)
	flow.set_phase_flag(RunFlow.Phase.COLLECTING, false)
	assert(flow.phase == RunFlow.Phase.COMBAT)
	print("Denti authoritative run phase test passed")
	finish()
