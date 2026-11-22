class_name ClassSkillModule
extends Node2D

## Base for one class's verb and skills. Every module exists on every player
## but only acts while its class is played (`active()`). The player forwards
## combat events through the hooks below; unused hooks stay no-ops.
## Talent powers come from ClassCombatEffects.power().

const FLASH_SECONDS := 0.35
const MAX_STATE_ITEMS := 64

var player: Player
var flashes: Array[Dictionary] = []
var lines: Array[Dictionary] = []

func _ready() -> void:
	top_level = true
	global_position = Vector2.ZERO
	z_index = 2

## Stable class id this module belongs to.
func class_id() -> StringName:
	return &""

## Key under which the module stores its state in the run snapshot.
func state_key() -> String:
	return str(class_id())

func active() -> bool:
	return player != null and player.stats != null and player.stats.class_data != null and player.stats.class_data.id == class_id()

func power(id: String) -> float:
	return player.class_combat.power(id) if player != null else 0.0

func items() -> ItemInventory:
	return player.items

# --- Hooks (override as needed) ------------------------------------------------

func reset_wave() -> void:
	flashes.clear()
	lines.clear()
	queue_redraw()

func advance(delta: float) -> void:
	for list in [flashes, lines]:
		for index in range(list.size() - 1, -1, -1):
			list[index].time -= delta
			if list[index].time <= 0.0: list.remove_at(index)
	queue_redraw()

func on_dash_started() -> void: pass
func on_dash_ended(_start: Vector2, _end: Vector2) -> void: pass
func sweep(_start: Vector2, _end: Vector2) -> void: pass
func on_weapon_hit(_enemy: Enemy, _weapon: WeaponData, _dealt: float) -> void: pass
func on_enemy_died(_enemy: Enemy) -> void: pass
func on_loot_collected(_kind: StringName, _amount: int, _drop: Loot) -> void: pass
func on_shield_blocked() -> void: pass

func move_factor() -> float: return 1.0
func attack_speed_bonus() -> float: return 0.0
func weapon_interval_factor(_weapon: WeaponInstance) -> float: return 1.0
func damage_bonus(_enemy: Enemy, _weapon: WeaponData) -> float: return 0.0
func pickup_factor() -> float: return 1.0

func save_data() -> Dictionary: return {}
func restore(_saved: Dictionary) -> void: reset_wave()
func save_with_enemies(_indices: Dictionary) -> Dictionary: return save_data()
func restore_with_enemies(saved: Dictionary, _enemies: Array[Node]) -> void: restore(saved)

# --- Shared helpers ---------------------------------------------------------

## Generic snapshot validation: finite non-negative numbers, vectors and small
## arrays/dictionaries of those. Modules clamp values again in restore().
static func valid_state(value: Variant, depth: int = 0) -> bool:
	if depth > 6: return false
	if value is int or value is float: return is_finite(float(value))
	if value is String: return value.length() <= 64
	if value is Array:
		if value.size() > MAX_STATE_ITEMS: return false
		for entry in value:
			if not valid_state(entry, depth + 1): return false
		return true
	if value is Dictionary:
		if value.size() > MAX_STATE_ITEMS: return false
		for key in value:
			if not valid_state(value[key], depth + 1): return false
		return true
	return false

func scaled(amount: float) -> float:
	return player.stats.scale_damage(amount)

func nearest_enemy(at: Vector2, radius: float, excluded: Enemy = null) -> Enemy:
	var result := EnemySpatialIndex.nearest(get_tree(), player.enemy_index, at, radius, true, excluded)
	return result if result != null and result.global_position.distance_squared_to(at) <= radius * radius else null

func push_from(at: Vector2, radius: float, distance: float) -> void:
	for enemy in player.nearby_enemies(at, radius):
		if not enemy.is_targetable(): continue
		var away := at.direction_to(enemy.global_position)
		if away.is_zero_approx(): away = Vector2.RIGHT
		enemy.global_position += away * distance * (1.0 - clampf(enemy.data.knockback_resistance, 0.0, 1.0))

func shatter_projectiles(at: Vector2, radius: float) -> int:
	var count := 0
	var projectiles := player.get_parent().get_node_or_null("EnemyProjectiles")
	if projectiles == null: return 0
	for projectile in projectiles.get_children():
		if projectile is AcidProjectile and projectile.is_physics_processing() and projectile.global_position.distance_squared_to(at) <= radius * radius:
			projectile.shatter()
			count += 1
	return count

func support(kind: StringName, amount: float = 1.0) -> void:
	player.items.enchantment_support.emit(kind, amount)

func flash(at: Vector2, radius: float, color: Color) -> void:
	flashes.append({"at": at, "radius": radius, "color": color, "time": FLASH_SECONDS})
	if flashes.size() > 24: flashes.pop_front()

func beam(from: Vector2, to: Vector2, color: Color, width: float = 3.0) -> void:
	lines.append({"a": from, "b": to, "color": color, "width": width, "time": 0.18})
	if lines.size() > 32: lines.pop_front()

func draw_effects() -> void:
	for entry in flashes:
		var progress := 1.0 - float(entry.time) / FLASH_SECONDS
		draw_arc(to_local(entry.at), float(entry.radius) * (0.35 + 0.65 * progress), 0.0, TAU, 40, Color(entry.color, 0.85 * (1.0 - progress)), 4.0, true)
	for entry in lines:
		var alpha := clampf(float(entry.time) / 0.18, 0.0, 1.0)
		draw_line(to_local(entry.a), to_local(entry.b), Color(entry.color, alpha), float(entry.width), true)

func _draw() -> void:
	draw_effects()
