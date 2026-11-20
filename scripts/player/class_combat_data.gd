class_name ClassCombatData
extends Resource

@export var opener_bonus := 0.0
@export var opener_duration := 0.9
@export var opener_roles: Array[StringName] = []

@export_group("Dash poison trail")
## The dash drags a poison lane behind Denti. It snaps shortly after the dash
## (hit + poison on everything on the line) and stays as a poison field.
@export var trail_enabled := false
@export var trail_damage := 0.0
@export var trail_melee_scaling := 0.0
@export var trail_width := 44.0
@export var trail_delay := 0.25
## Poison budget per snap hit before Bisskraft; spreads over the poison DoT.
@export var trail_poison := 0.0
@export var trail_poison_scaling := 0.0
## How long the lane stays as a poison field after snapping.
@export var trail_field := 3.0
## Share of the snap poison applied by each field tick.
@export var trail_field_share := 0.2
@export var trail_field_interval := 0.5
@export var trail_refund := 0.0
@export var trail_refund_cap := 0.0
@export var trail_sugar_factor := 1.0
## Depotfüllung lens: additional trail poison per owned depot power.
@export var trail_depot_factor := 0.5
@export var trail_limit := 2
@export var trail_cross_radius := 90.0

func valid() -> bool:
	for value in [opener_bonus, opener_duration, trail_damage, trail_melee_scaling, trail_width, trail_delay, trail_poison, trail_poison_scaling,
			trail_field, trail_field_share, trail_field_interval, trail_refund, trail_refund_cap, trail_sugar_factor, trail_depot_factor, trail_cross_radius]:
		if not is_finite(value) or value < 0: return false
	for role in opener_roles:
		if role not in WeaponRoles.ALL: return false
	if trail_enabled and (trail_width <= 0 or trail_limit < 1 or trail_field_interval <= 0): return false
	return opener_duration > 0
