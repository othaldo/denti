class_name BossStageRewardData
extends Resource

@export var xp: int = 30
## Level points granted by the whole stage. The XP is derived from the current
## level curve when the stage first pays out, so later bosses stay worth
## roughly one ordinary wave instead of shrinking to a single point.
## 0 keeps the fixed `xp` budget.
@export var levels: int = 0
@export var coins: int = 32
@export var capsules: int = 1
@export_range(0.0, 1.0) var rich_coin_fraction: float = 0.5
@export_range(0.0, 1.0) var phase_xp_fraction: float = 0.1

