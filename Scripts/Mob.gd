extends RigidBody3D
class_name Mob

# Base constants - can be overridden by child classes
const MIN_ATTACK_DISTANCE: float = 1.5
const ATTACK_DURATION: float = 1.0
const ATTACK_COOLDOWN: float = 3.0
const KNOCKBACK_FORCE: float = 10.0
const UPWARD_FORCE_RANGE: Vector2 = Vector2(0.3, 1.5)
const MOB_SEPARATION_DISTANCE: float = 2.0
const SEPARATION_FORCE: float = 3.0
const MIN_DISTANCE_TO_PLAYER: float = 1.0

@export var speed_range: Vector2 = Vector2(1.0, 3.0)
@export var max_health: int = 30
@export var damage: int = 10
@export var ai_types_available: Array[String] = ["hit_and_run"] # Which AI types this mob can use
@export var flee_health_threshold: int = 1

var ai_type: String = "hit_and_run"
var loot_table: LootTable = null

@onready var mob_model: Node3D = %bat_model
@onready var timer: Timer = %Timer

var world_node: Node3D
var player: Node3D
var speed: float
var health: int
var is_attacking: bool = false
var attack_timer: float = 0.0
var attack_cooldown: float = 0.0

func _ready() -> void:
	add_to_group("mob")
	_initialize_mob()
	_find_player()
	_find_world_node()

func _initialize_mob() -> void:
	speed = randf_range(speed_range.x, speed_range.y)
	health = max_health

	# Randomly pick from available AI types for this mob
	if not ai_types_available.is_empty():
		ai_type = ai_types_available.pick_random()

	# Child classes can override this to add specific initialization

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")

	if players.is_empty():
		push_error("No Players found!")
		return

	if players.size() > 1:
		push_warning("Multiple Players found. Targeting Closest!") # TODO: Add check to confirm player is closest?

	player = players[0]
	if not is_instance_valid(player):
		push_error("Invalid player reference found")
		player = null

func _find_world_node() -> void:
	var worlds = get_tree().get_nodes_in_group("world")

	if worlds.is_empty():
		push_error("No world node found! Make sure the world/level node is in the 'world' group")
		return

	world_node = worlds[0]

func _physics_process(delta: float) -> void:
	if not player or health <= 0:
		return

	_update_timers(delta)
	_handle_movement(delta)
	_update_rotation()

func _update_timers(delta: float) -> void:
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			is_attacking = false

	if attack_cooldown > 0.0:
		attack_cooldown -= delta

# To be overridden by child classes
func _handle_movement(_delta: float) -> void:
	_handle_ai_movement()

func _handle_ai_movement() -> void:
	# Always check for attack opportunity first (unless currently attacking)
	if not is_attacking and should_start_attack():
		attack()
		return

	# If currently attacking, don't move
	if is_attacking:
		linear_velocity = Vector3.ZERO
		return

	# Handle fleeing if low health
	if should_flee():
		_flee_from_player()
		return

	# Normal AI behavior
	match ai_type:
		"aggressive":
			_handle_aggressive_ai()
		"hit_and_run":
			_handle_hit_and_run_ai()
		"coward":
			_handle_coward_ai()
		_:
			_handle_hit_and_run_ai()

func _handle_aggressive_ai() -> void:
	_chase_player()

func _handle_hit_and_run_ai() -> void:
	# After attacking, retreat briefly, otherwise chase
	if is_player_in_attack_range() and attack_cooldown > ATTACK_COOLDOWN * 0.5:
		# Just attacked, retreat while cooldown is high
		_retreat_from_player()
	else:
		_chase_player()

func _handle_coward_ai() -> void:
	# Cowards are very cautious
	var distance = get_distance_to_player()

	# If damaged at all, flee
	if health < max_health:
		_flee_from_player()
	# If in attack range, flee even when healthy
	elif is_player_in_attack_range():
		_flee_from_player()
	# Only approach when far away and at full health
	elif distance > MIN_ATTACK_DISTANCE * 2:
		_chase_player()
	# Otherwise retreat slowly
	else:
		_retreat_from_player()

func should_flee() -> bool:
	return health <= flee_health_threshold

func should_start_attack() -> bool:
	if not is_player_in_attack_range():
		return false

	if not can_attack():
		return false

	match ai_type:
		"aggressive":
			return true
		"hit_and_run":
			return true
		"coward":
			return health >= max_health * 0.8
		_:
			return true

# Basic chase - can be overridden by child classes
func _chase_player() -> void:
	var direction = get_direction_to_player()
	var separation = _get_separation_vector()
	var final_direction = (direction + separation * SEPARATION_FORCE).normalized()
	linear_velocity = final_direction * speed

func _retreat_from_player() -> void:
	# Slow Retreat
	var direction = get_direction_away_from_player()
	linear_velocity = direction * speed * 0.8

func _flee_from_player() -> void:
	# Fast Retreat
	var direction = get_direction_away_from_player()
	linear_velocity = direction * speed * 1.5

func _update_rotation() -> void:
	var target_direction = _get_desired_facing_direction()
	if target_direction != Vector3.ZERO:
		mob_model.rotation.y = Vector3.FORWARD.signed_angle_to(target_direction, Vector3.UP) + PI

func _get_desired_facing_direction() -> Vector3:
	if not player:
		return Vector3.ZERO

	# Only face away when actively fleeing
	if should_flee():
		return get_direction_away_from_player()

	# Otherwise, always face the player (even when orbiting or retreating)
	return get_direction_to_player()

func attack() -> void:
	if not can_attack():
		return

	linear_velocity = Vector3.ZERO
	print("Mob attacking Player")

	is_attacking = true
	attack_timer = ATTACK_DURATION
	attack_cooldown = ATTACK_COOLDOWN

	# Deal damage to player
	if player and player.has_method("take_damage"):
		player.take_damage(damage)

func take_damage(amount: int = 1) -> void:
	if health <= 0:
		return

	mob_model.hurt()
	health = max(0, health - amount)

	_spawn_damage_number(amount, false)

	if health <= 0:
		_die()

func take_damage_with_crit(amount: int, is_critical: bool) -> void:
	if health <= 0:
		return

	mob_model.hurt()
	health = max(0, health - amount)

	_spawn_damage_number(amount, is_critical)

	if health <= 0:
		_die()

func _spawn_damage_number(damage_amount: int, is_critical: bool = false) -> void:
	const DAMAGE_NUMBER_SCENE = preload("res://UI/DamageNumber.tscn")
	var damage_number = DAMAGE_NUMBER_SCENE.instantiate()
	get_tree().root.add_child(damage_number)

	# Position slightly above the mob
	var spawn_pos = global_position + Vector3(0, 1.5, 0)
	damage_number.initialize(damage_amount, spawn_pos, is_critical)

func _die() -> void:
	set_physics_process(false)

	var knockback_direction = -global_position.direction_to(player.global_position)
	var upward_force = Vector3.UP * randf_range(UPWARD_FORCE_RANGE.x, UPWARD_FORCE_RANGE.y)

	apply_central_impulse(knockback_direction * KNOCKBACK_FORCE + upward_force)
	timer.start()
	GameStats.decrement_live_enemies()

func _on_timer_timeout() -> void:
	drop_loot()

func drop_loot() -> bool:
	if not world_node:
		push_error("World node not found!")
		queue_free()
		return false

	# If no loot table, don't drop anything
	if not loot_table:
		queue_free()
		return true

	# Roll for loot
	var dropped_items = loot_table.roll_loot()

	# Spawn each dropped item
	for item_data in dropped_items:
		var loot_resource = load(item_data.item_path)

		if not loot_resource:
			push_error("Failed to load loot resource: " + item_data.item_path)
			continue

		# Spawn multiple items if quantity > 1
		for i in range(item_data.quantity):
			var spawn_position = _calculate_loot_spawn_position()
			var loot_3D = Global.create_3d_item_node(loot_resource, spawn_position)

			if not loot_3D:
				push_error("Failed to create 3D loot item: " + loot_resource.name)
				continue

			world_node.add_child(loot_3D)

	queue_free()
	return true

func _calculate_loot_spawn_position() -> Vector3:
	var base_position = mob_model.global_position + mob_model.global_basis.z
	var random_offset = Vector3(randf_range(-0.5, 0.5), randf_range(0, 0.5), randf_range(-0.5, 0.5))
	return base_position + random_offset

func drop_loot_at_safe_position() -> bool:
	# Called by DeathZone when mob falls off - spawn loot near player instead
	if not world_node or not player or not loot_table:
		return false

	var dropped_items = loot_table.roll_loot()

	for item_data in dropped_items:
		var loot_resource = load(item_data.item_path)
		if not loot_resource:
			continue

		for i in range(item_data.quantity):
			# Spawn near player at a safe location
			var safe_position = player.global_position + Vector3(randf_range(-2.0, 2.0), 0.5, randf_range(-2.0, 2.0))
			var loot_3D = Global.create_3d_item_node(loot_resource, safe_position)

			if loot_3D:
				world_node.add_child(loot_3D)

	return true

func get_distance_to_player() -> float:
	if not player:
		return INF

	return global_position.distance_to(player.global_position)

func is_player_in_attack_range() -> bool:
	return get_distance_to_player() <= MIN_ATTACK_DISTANCE

func can_attack() -> bool:
	return attack_cooldown <= 0.0 and not is_attacking and health > 0

func get_direction_to_player() -> Vector3:
	if not player:
		return Vector3.ZERO

	var direction = global_position.direction_to(player.global_position)
	direction.y = 0.0

	return direction

func get_direction_away_from_player() -> Vector3:
	if not player:
		return Vector3.ZERO

	var direction = (global_position - player.global_position).normalized()
	direction.y = 0.0

	return direction

func _get_separation_vector() -> Vector3:
	var separation = Vector3.ZERO
	var nearby_mobs = get_tree().get_nodes_in_group("mob")

	for other_mob in nearby_mobs:
		if other_mob == self or not is_instance_valid(other_mob):
			continue

		var distance = global_position.distance_to(other_mob.global_position)
		if distance < MOB_SEPARATION_DISTANCE and distance > 0:
			var push_away = (global_position - other_mob.global_position).normalized()
			push_away.y = 0  # Keep on same plane
			# Stronger separation when closer
			var strength = 1.0 - (distance / MOB_SEPARATION_DISTANCE)
			separation += push_away * strength

	return separation.normalized() if separation.length() > 0 else Vector3.ZERO
