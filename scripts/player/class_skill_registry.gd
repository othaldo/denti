class_name ClassSkillRegistry
extends RefCounted

## Every class skill module the player carries. Adding a class with its own
## verb means adding its ClassSkillModule script here; the player, game and
## run snapshot forward hooks and state to all modules generically.
const MODULES: Array[Script] = [
	preload("res://scripts/player/fairy_skills.gd"),
	preload("res://scripts/player/ember_skills.gd"),
	preload("res://scripts/player/rinser_skills.gd"),
	preload("res://scripts/player/frost_skills.gd"),
	preload("res://scripts/player/necrodent_skills.gd"),
]
