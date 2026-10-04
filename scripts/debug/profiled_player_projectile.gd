extends WeaponProjectile

var diagnostics: CombatDiagnostics

func _physics_process(delta: float) -> void:
	var measured := diagnostics.should_sample(true)
	var started := Time.get_ticks_usec() if measured else 0
	super._physics_process(delta)
	if measured:
		diagnostics.record(&"player_projectiles", started)

func _draw() -> void:
	if diagnostics.hide_effects():
		return
	var measured := diagnostics.should_sample(false)
	var started := Time.get_ticks_usec() if measured else 0
	super._draw()
	if measured:
		diagnostics.record(&"drawing", started)
