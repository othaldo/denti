extends WeaponStrike

# Only used by benchmark_melee_performance.gd --profile.
var elapsed_us := 0
var calls := 0

func tick(weapon: WeaponInstance, from_progress: float, to_progress: float) -> void:
	var started := Time.get_ticks_usec()
	super.tick(weapon, from_progress, to_progress)
	elapsed_us += Time.get_ticks_usec() - started
	calls += 1
