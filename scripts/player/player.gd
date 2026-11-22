class_name Player
extends CharacterBody2D

signal attack_performed(kind: StringName)
signal damaged(position: Vector2, amount: float)

const MIN_IFRAMES := 0.2
const MAX_IFRAMES := 0.4
const FULL_IFRAMES_DAMAGE_FRACTION := 0.15
const ATTACK_ANIMATION_DURATION := 0.18
const DODGE_IFRAMES := 0.15
const DASH_PULSE_RADIUS := 110.0

@onready var stats: PlayerStats = $Stats
@onready var loadout: WeaponLoadout = $Weapons
@onready var items: ItemInventory = get_node("../Items")
@onready var sprite: Sprite2D = $Sprite2D
@onready var sprite_base_scale: Vector2 = sprite.scale
## The expressive base Denti; class looks are normalized against it.
@onready var base_body_texture: Texture2D = sprite.texture
@onready var base_body_scale: Vector2 = sprite.scale
var class_look: Texture2D
static var used_rects: Dictionary = {}
@onready var expressions: DentiExpressions = $Sprite2D/Expressions
@onready var status_effects: PlayerStatusEffects = $StatusEffects
@onready var arena: DentiArena = get_node("../Arena")
@onready var mobile_controls: MobileControls = get_node("../MobileControls/Root")
@onready var enemy_index: EnemySpatialIndex = get_node("../Enemies") as EnemySpatialIndex

var hurt_time: float = 0.0
var dodge_time: float = 0.0
var animation_time: float = 0.0
var attack_time: float = 0.0
var attack_direction: Vector2 = Vector2.RIGHT
var is_moving: bool = false
var dash := PlayerDash.new()
var class_combat := ClassCombatEffects.new()
var motion_start := Vector2.ZERO
var motion_end := Vector2.ZERO
var motion_tick := -1
var motion_serial := 0
var dash_motion_seconds := 0.0
var dash_moved := false
var _dash_held := false
var dash_trail: DashTrail
var dash_cut: ClassDashCut
var molar_skills: MolarSkills
var assassin_skills: AssassinSkills
## Verb/skill modules of the other classes; each acts only for its own class.
var skill_modules: Array[ClassSkillModule] = []
## Set by the game; class relics change the class modules' verbs.
var relics: RelicInventory
var dash_origin := Vector2.ZERO


func nearby_enemies(at: Vector2, radius: float, include_radius: bool = true) -> Array[Enemy]:
	return EnemySpatialIndex.circle(get_tree(), enemy_index, at, radius, include_radius)


func enemies_on_segment(start: Vector2, end: Vector2, radius: float) -> Array[Enemy]:
	return EnemySpatialIndex.segment(get_tree(), enemy_index, start, end, radius)


func _ready() -> void:
	mobile_controls.player = self
	expressions.configure(stats)
	status_effects.configure(self)
	stats.dodged.connect(_on_dodged)
	loadout.stats = stats
	dash.stats = stats
	dash.config = stats.class_data.dash_config()
	class_combat.profile = stats.class_data
	class_combat.loadout = loadout
	dash.started.connect(class_combat.on_dash)
	dash_cut = ClassDashCut.new()
	dash_cut.player = self
	# Ground layer of the arena (below enemy bodies at z 3), not a child of Denti:
	# drawing under the player node never reached the screen.
	_attach_dash_cut.call_deferred()
	dash.started.connect(dash_cut.on_dash_started)
	molar_skills = MolarSkills.new()
	molar_skills.player = self
	add_child(molar_skills)
	stats.shield_blocked.connect(molar_skills.on_shield_blocked)
	assassin_skills = AssassinSkills.new()
	assassin_skills.player = self
	add_child(assassin_skills)
	dash.started.connect(assassin_skills.on_dash_started)
	dash.started.connect(assassin_skills.on_dash)
	dash.started.connect(func() -> void: dash_origin = global_position)
	for script in ClassSkillRegistry.MODULES:
		var module: ClassSkillModule = script.new()
		module.player = self
		add_child(module)
		skill_modules.append(module)
		dash.started.connect(module.on_dash_started)
		stats.shield_blocked.connect(module.on_shield_blocked)
	stats.changed.connect(dash.clamp_charge)
	stats.changed.connect(apply_class_look)
	apply_class_look()
	get_node("/root/GameInput").changed.connect(_sync_dash_input)
	dash_trail = DashTrail.new()
	dash_trail.z_index = -1
	add_child(dash_trail)


## Shows the chosen class on the combat sprite. A class look is scaled so its
## tooth matches the base body height and stands on the same foot line; the
## face overlay is hidden because the class art carries its own face.
func apply_class_look() -> void:
	var look: Texture2D = stats.class_data.combat_sprite if stats.class_data != null else null
	if look == class_look: return
	class_look = look
	if look == null:
		sprite.texture = base_body_texture
		sprite.offset = Vector2.ZERO
		sprite_base_scale = base_body_scale
		expressions.visible = true
		return
	var source := _used_rect(base_body_texture)
	var target := _used_rect(look)
	var factor := float(source.size.y) / maxf(float(target.size.y), 1.0)
	var new_scale := base_body_scale * factor
	# Bottom centre of the visible pixels, relative to each texture's centre.
	var source_foot := Vector2(source.get_center().x, source.end.y) - Vector2(base_body_texture.get_size()) * 0.5
	var target_foot := Vector2(target.get_center().x, target.end.y) - Vector2(look.get_size()) * 0.5
	sprite.texture = look
	sprite.offset = source_foot * base_body_scale / new_scale - target_foot
	sprite_base_scale = new_scale
	sprite.scale = new_scale
	expressions.visible = false

static func _used_rect(texture: Texture2D) -> Rect2i:
	var key := texture.resource_path
	if not used_rects.has(key):
		var image := texture.get_image()
		if image != null and image.is_compressed(): image.decompress()
		used_rects[key] = image.get_used_rect() if image != null else Rect2i(Vector2i.ZERO, Vector2i(texture.get_size()))
	return used_rects[key]

func _physics_process(delta: float) -> void:
	var direction := movement_direction()
	if not direction.is_zero_approx():
		dash.last_direction = direction.normalized()
	var before_move := global_position
	motion_serial += 1
	motion_tick = Engine.get_physics_frames()
	motion_start = before_move
	dash_moved = false
	dash_motion_seconds = 0.0
	var was_dashing := dash.active
	if combat_active():
		class_combat.advance(delta)
		dash_cut.advance(delta)
		molar_skills.advance(delta)
		assassin_skills.advance(delta)
		for module in skill_modules: module.advance(delta)
		dash_moved = was_dashing
		dash.advance(self, delta)
	else:
		dash.finish()
		dash_cut.release()
	if not was_dashing:
		velocity = direction * stats.move_speed * floor_movement_factor()
		move_and_slide()
	global_position = global_position.clamp(Vector2.ONE * DentiArena.PLAYER_MARGIN, arena.arena_size - Vector2.ONE * DentiArena.PLAYER_MARGIN)
	motion_end = global_position
	if dash_moved:
		dash_trail.add_segment(motion_start, motion_end)
		dash_cut.extend(motion_end)
		assassin_skills.sweep(motion_start, motion_end)
		for module in skill_modules: module.sweep(motion_start, motion_end)
		if not dash.active:
			dash_cut.release()
			_dash_pulse()
			for module in skill_modules: module.on_dash_ended(dash_origin, motion_end)
	is_moving = global_position.distance_squared_to(before_move) > 0.01
	_animate_sprite(dash.direction if was_dashing else direction, delta)
	hurt_time = maxf(hurt_time - delta, 0.0)
	dodge_time = maxf(dodge_time - delta, 0.0)
	sprite.modulate = Color(1.0, 0.55, 0.55) if hurt_time > 0.0 else (Color(0.72, 0.94, 1.0) if dodge_time > 0.0 else Color.WHITE)


## Rückstoßpuls talent: the end of a dash shoves nearby enemies away.
func _dash_pulse() -> void:
	var push := class_combat.power("dash_pulse")
	if push <= 0.0: return
	for enemy in nearby_enemies(global_position, DASH_PULSE_RADIUS):
		if not enemy.is_targetable(): continue
		var away := global_position.direction_to(enemy.global_position)
		if away.is_zero_approx(): away = dash.direction
		enemy.global_position += away * push * (1.0 - clampf(enemy.data.knockback_resistance, 0.0, 1.0))
	ElementImpactBatch.emit_from(self, &"water", global_position, dash.direction, DASH_PULSE_RADIUS, true)
	items.enchantment_support.emit(&"class_dash_pulses", 1)


# --- Class skill modules ------------------------------------------------------

func reset_skill_modules() -> void:
	for module in skill_modules: module.reset_wave()

func notify_weapon_hit(enemy: Enemy, weapon: WeaponData, dealt: float) -> void:
	molar_skills.on_weapon_hit(enemy, weapon, dealt)
	assassin_skills.on_weapon_hit(enemy, weapon, dealt)
	for module in skill_modules: module.on_weapon_hit(enemy, weapon, dealt)

## Owned class relic of the class being played.
func has_class_relic(id: StringName) -> bool:
	return relics != null and relics.has_relic(id)

func notify_enemy_died(enemy: Enemy, _amount: float = 0.0) -> void:
	for module in skill_modules: module.on_enemy_died(enemy)

func notify_loot(kind: StringName, amount: int, drop: Loot) -> void:
	for module in skill_modules: module.on_loot_collected(kind, amount, drop)

func module_attack_speed_bonus() -> float:
	var total := 0.0
	for module in skill_modules: total += module.attack_speed_bonus()
	return total

func module_interval_factor(weapon: WeaponInstance) -> float:
	var factor := 1.0
	for module in skill_modules: factor *= module.weapon_interval_factor(weapon)
	return factor

func module_damage_bonus(enemy: Enemy, weapon: WeaponData) -> float:
	var total := assassin_skills.damage_bonus(enemy, weapon)
	for module in skill_modules: total += module.damage_bonus(enemy, weapon)
	return total

func module_pickup_factor() -> float:
	var factor := 1.0
	for module in skill_modules: factor *= module.pickup_factor()
	return factor

func skill_module(id: StringName) -> ClassSkillModule:
	for module in skill_modules:
		if module.class_id() == id: return module
	return null

func save_skill_modules(enemy_indices: Dictionary = {}) -> Dictionary:
	var result := {}
	for module in skill_modules:
		var state := module.save_with_enemies(enemy_indices)
		if not state.is_empty(): result[module.state_key()] = state
	return result

func restore_skill_modules(saved: Variant, enemies: Array[Node] = []) -> void:
	var states: Dictionary = saved if saved is Dictionary else {}
	for module in skill_modules:
		var state: Variant = states.get(module.state_key(), {})
		module.restore_with_enemies(state if state is Dictionary else {}, enemies)


func movement_direction() -> Vector2:
	if mobile_controls.visible and mobile_controls.combat_active and mobile_controls.touch_index >= 0:
		return mobile_controls.movement_direction(0.0)
	return Input.get_vector("move_left", "move_right", "move_up", "move_down")


func floor_movement_factor() -> float:
	# Environmental slow is positional, never a permanent change to PlayerStats.
	# Overlapping fields use the strongest effect, without multiplying slows.
	var factor := 1.0
	for encounter: CaramelEncounter in get_tree().get_nodes_in_group("caramel_encounters"):
		factor = minf(factor, encounter.speed_factor_at(global_position))
	# Assassin sugar crash after a Rausch, plus class module movement rules.
	if assassin_skills != null: factor *= assassin_skills.move_factor()
	for module in skill_modules: factor *= module.move_factor()
	return factor


func combat_active() -> bool:
	var game := get_parent()
	return not get_tree().paused and stats.health > 0.0 and game.run_flow.is_combat() and (game.wave.active or game.boss_pending)


func try_dash() -> bool:
	return dash.request(movement_direction(), combat_active())


func _input(event: InputEvent) -> void:
	if event.is_action_released("dash"):
		_dash_held = false


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed("dash") and not _dash_held:
		_dash_held = true
		try_dash()
		get_viewport().set_input_as_handled()


func _notification(what: int) -> void:
	if what in [NOTIFICATION_APPLICATION_FOCUS_IN, NOTIFICATION_UNPAUSED]:
		_dash_held = Input.is_action_pressed("dash")
	elif what == NOTIFICATION_PREDELETE and is_instance_valid(dash_cut) and dash_cut.get_parent() == null:
		# Never attached (player freed first or used outside the arena): free it here.
		dash_cut.free()


## The trail lives in the arena root so it draws as ground beneath enemies.
func _attach_dash_cut() -> void:
	if is_instance_valid(dash_cut) and dash_cut.get_parent() == null and get_parent() != null:
		get_parent().add_child(dash_cut)


func _sync_dash_input() -> void:
	if not Input.is_action_pressed("dash"):
		_dash_held = false


func swept_dash_this_frame() -> bool:
	return dash_moved and motion_tick == Engine.get_physics_frames()


func damage_circle_at(centre: Vector2, radius: float, seconds_into_frame: float = -1.0) -> bool:
	var at := global_position
	if seconds_into_frame >= 0.0 and swept_dash_this_frame():
		at = motion_start.lerp(motion_end, clampf(seconds_into_frame / maxf(dash_motion_seconds, 0.000001), 0, 1))
	return at.distance_squared_to(centre) <= radius * radius


func projectile_crosses(start: Vector2, end: Vector2, radius: float, delta: float, launch_serial: int) -> bool:
	if not swept_dash_this_frame() or launch_serial == motion_serial:
		return Geometry2D.get_closest_point_to_segment(global_position, start, end).distance_squared_to(global_position) <= radius * radius
	# Split at dash end/wall: the player can stop early in a long frame.
	var middle := start.lerp(end, clampf(dash_motion_seconds / maxf(delta, 0.000001), 0, 1))
	var relative := Geometry2D.get_closest_point_to_segment(Vector2.ZERO, start - motion_start, middle - motion_end)
	var after := Geometry2D.get_closest_point_to_segment(motion_end, middle, end)
	return relative.length_squared() <= radius * radius or after.distance_squared_to(motion_end) <= radius * radius


func _animate_sprite(direction: Vector2, delta: float) -> void:
	var moving := direction.length_squared() > 0.01
	animation_time += delta * (10.0 if moving else 3.0)
	attack_time = maxf(attack_time - delta, 0.0)
	var attack_pulse := sin(attack_time / ATTACK_ANIMATION_DURATION * PI)
	var sway := sin(animation_time)
	var stretch := sway * (0.035 if moving else 0.012)
	sprite.position.y = -2.0 - absf(sway) * (2.5 if moving else 1.4) - attack_pulse * 4.0
	sprite.scale = sprite_base_scale * Vector2(1.0 + stretch + attack_pulse * 0.12, 1.0 - stretch - attack_pulse * 0.09)
	var target_rotation := -direction.x * 0.08 + sway * 0.025 + attack_direction.x * attack_pulse * 0.14
	sprite.rotation = lerp_angle(sprite.rotation, target_rotation, minf(delta * 14.0, 1.0))


func play_attack_animation(aim: Vector2, kind: StringName = &"brush") -> void:
	attack_time = ATTACK_ANIMATION_DURATION
	attack_direction = aim
	attack_performed.emit(kind)


func take_contact_hit(amount: float, inflicted_statuses: Array[Dictionary] = [], during_dash: bool = false) -> float:
	if during_dash or dash.active:
		dash.contacted.emit()
		# A zero multiplier means a true pass-through: no damage, no shield or dodge roll.
		if dash.config.contact_damage_multiplier <= 0.0: return 0.0
		amount *= dash.config.contact_damage_multiplier
	return take_hit(amount, inflicted_statuses)


func take_hit(amount: float, inflicted_statuses: Array[Dictionary] = []) -> float:
	if hurt_time > 0.0 or dodge_time > 0.0 or stats.health <= 0.0:
		return 0.0
	var actual := stats.take_damage(amount)
	if actual > 0.0:
		hurt_time = clampf(MAX_IFRAMES * actual / (stats.max_health * FULL_IFRAMES_DAMAGE_FRACTION), MIN_IFRAMES, MAX_IFRAMES)
		damaged.emit(global_position + Vector2(0.0, -28.0), actual)
		status_effects.apply_attacks(inflicted_statuses)
	return actual


func _on_dodged() -> void:
	dodge_time = DODGE_IFRAMES
