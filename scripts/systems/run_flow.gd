class_name RunFlow
extends RefCounted

# Reward ordering remains in PostWaveRewards; this owns the surrounding run phase.
enum Phase { COMBAT, STARTER, BOSS_OVERTIME, COLLECTING, REWARDS, SHOP, STORY, ENDED }
var phase: Phase = Phase.COMBAT


func enter(next: Phase) -> void:
	phase = next


func is_combat() -> bool:
	return phase in [Phase.COMBAT, Phase.BOSS_OVERTIME]


func requires_pause() -> bool:
	return phase in [Phase.STARTER, Phase.REWARDS, Phase.SHOP, Phase.STORY, Phase.ENDED]


func set_phase_flag(target: Phase, enabled: bool) -> void:
	if enabled:
		enter(target)
	elif phase == target:
		enter(Phase.COMBAT)
