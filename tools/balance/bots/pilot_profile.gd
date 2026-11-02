extends Resource
## Input limitations only. No player/enemy stat bonuses.

@export var id: StringName
@export var display_name: String
@export var reaction_ticks := 10
@export var decision_ticks := 6
@export var prediction_seconds := 0.5
@export var avoidance_weight := 2.0
@export var mistake_chance := 0.0
@export var mistake_angle_degrees := 0.0
@export var reads_warnings := true
@export var uses_dash := true
@export var dash_danger_threshold := 1.5
