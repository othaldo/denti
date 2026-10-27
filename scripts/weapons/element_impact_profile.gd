class_name ElementImpactProfile
extends Resource

enum Motion { EMBER, SHARD, BUBBLE, ARC, DROP }

@export var element: StringName
@export var atlas_region: Rect2
@export var motion: Motion = Motion.DROP
@export_range(0.1, 2.0) var burst_duration := 0.44
@export_range(0.1, 2.0) var ground_duration := 0.9
@export_range(0.0, 1.0) var ground_opacity := 0.48
@export_range(0.0, 60.0) var lift := 20.0
@export_range(1, 8) var fragments := 5
