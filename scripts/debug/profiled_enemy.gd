extends Enemy

var diagnostics: CombatDiagnostics

func _physics_process(delta: float) -> void:
	# The central owner measures its whole step, including complex enemies.
	if spatial_index != null and spatial_index.motion.stepping:
		super._physics_process(delta)
		return
	var measured := diagnostics.should_sample(true)
	var started := Time.get_ticks_usec() if measured else 0
	super._physics_process(delta)
	if measured:
		diagnostics.record(&"enemy_physics", started)

func _process(delta: float) -> void:
	var measured := diagnostics.should_sample(false)
	var started := Time.get_ticks_usec() if measured else 0
	super._process(delta)
	if measured:
		diagnostics.record(&"enemy_visuals", started)

func _draw() -> void:
	if diagnostics.hide_effects():
		return
	var measured := diagnostics.should_sample(false)
	var started := Time.get_ticks_usec() if measured else 0
	super._draw()
	if measured:
		diagnostics.record(&"drawing", started)

func take_damage(amount: float, weapon: WeaponData = null, critical: bool = false, proc_id: StringName = &"") -> void:
	if diagnostics.no_hits():
		return
	var measured := diagnostics.should_sample(Engine.is_in_physics_frame())
	var started := Time.get_ticks_usec() if measured else 0
	super.take_damage(amount, weapon, critical, proc_id)
	if measured:
		diagnostics.record(&"hits", started)
