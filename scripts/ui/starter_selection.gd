class_name StarterSelection
extends RunSetupScreen

# Pending legacy saves and test arenas share the menu's weapon presentation.

func _ready() -> void:
	super._ready()
	back_button.visible = false
