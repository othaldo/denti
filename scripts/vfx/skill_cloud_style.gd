class_name SkillCloudStyle
extends Resource
## Look of one animated skill cloud drawn by SkillPuffs. Values are relative to
## the gameplay radius, so the same style fits small and talent-enlarged clouds.

## Main tint; the neutral puff art takes this colour.
@export var color := Color.WHITE
## Back puffs are darkened, front puffs lightened by this amount.
@export_range(0.0, 0.6) var depth_shade := 0.2
@export_range(1, 12) var puffs := 7
## Puff size relative to the radius.
@export_range(0.2, 1.2) var puff_size := 0.62
## How far puff centres spread from the middle, relative to the radius.
@export_range(0.0, 1.0) var spread := 0.62
## Orbit speed of the puffs in radians per second.
@export_range(0.0, 3.0) var drift := 0.35
## Size pulse of each puff.
@export_range(0.0, 0.4) var breathe := 0.08
@export_range(0.0, 1.0) var opacity := 0.62
## Soft ground shadow below the puffs; a bright colour turns it into a glow bed.
@export_range(0.0, 1.0) var shadow_opacity := 0.22
@export var shadow_color := Color.BLACK
## Faint outline at the exact gameplay radius (lanes: centre line) for readability.
@export_range(0.0, 1.0) var edge_opacity := 0.2
@export_range(0, 8) var bubbles := 4
@export_range(0.2, 4.0) var bubble_period := 1.1
@export var bubble_color := Color.WHITE
## Rising particles become glowing sparks (embers) instead of popping bubbles.
@export var rise_sparkles := false
@export_range(0, 8) var sparkles := 0
@export var sparkle_color := Color.WHITE
## Seconds the cloud needs to billow up and to dissolve.
@export_range(0.05, 2.0) var spawn_seconds := 0.3
@export_range(0.05, 2.0) var fade_seconds := 0.6
