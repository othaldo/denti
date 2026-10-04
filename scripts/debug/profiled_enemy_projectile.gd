extends AcidProjectile

var diagnostics: CombatDiagnostics

func _physics_process(delta: float) -> void:
	var measured := diagnostics.should_sample(true)
	var started := Time.get_ticks_usec() if measured else 0
	super._physics_process(delta)
	if measured:
		diagnostics.record(&"enemy_projectiles", started)
