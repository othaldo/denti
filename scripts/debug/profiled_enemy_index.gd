extends EnemySpatialIndex

var diagnostics: CombatDiagnostics

func _process(delta: float) -> void:
	var measured := diagnostics.should_sample(false)
	var started := Time.get_ticks_usec() if measured else 0
	super._process(delta)
	if measured:
		diagnostics.record(&"enemy_visuals", started)

func _draw() -> void:
	if diagnostics.hide_effects():
		draw_multimesh(shadow_batch.multimesh, shadow_batch.texture)
		return
	var measured := diagnostics.should_sample(false)
	var started := Time.get_ticks_usec() if measured else 0
	super._draw()
	if measured:
		diagnostics.record(&"drawing", started)
