extends DamageNumberBatch

var diagnostics: CombatDiagnostics

func _process(delta: float) -> void:
	var measured := diagnostics.should_sample(false)
	var started := Time.get_ticks_usec() if measured else 0
	super._process(delta)
	if measured:
		diagnostics.record(&"text_updates", started)

func _draw() -> void:
	var measured := diagnostics.should_sample(false)
	var started := Time.get_ticks_usec() if measured else 0
	super._draw()
	if measured:
		diagnostics.record(&"drawing", started)
