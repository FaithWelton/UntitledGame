extends RigidBody3D

const MIN_ATTACK_DISTANCE: float = 1.25
const ATTACK_DURATION: float = 1.0
const ATTACK_COOLDOWN: float = 10.0
const KNOCKBACK_FORCE: float = 10.0
const UPWARD_FORCE_RANGE: Vector2 = Vector2(1.0, 5.0)

@export var speed_range: Vector2 = Vector2(1.0, 3.0)
@export var max_health: int = 30
@export var damage: int = 100
@export var ai_type: String = "hit_and_run" # "aggressive" | "hit_and_run" | "coward"
@export var flee_health_threshold: int = 1

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
	_handle_ai_movement()
	_update_rotation()

func _update_timers(delta: float) -> void:
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			is_attacking = false
	
	if attack_cooldown > 0.0:
		attack_cooldown -= delta

func _handle_ai_movement() -> void:
	if is_attacking:
		linear_velocity = Vector3.ZERO
		return
	
	if should_flee():
		_flee_from_player()
		return
	
	if should_start_attack():
		attack()
		return
	
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
	if is_player_in_attack_range():
		_retreat_from_player()
	else:
		_chase_player()

func _handle_coward_ai() -> void:
	if is_player_in_attack_range():
		_flee_from_player()
	elif get_distance_to_player() < MIN_ATTACK_DISTANCE * 2:
		_retreat_from_player()
	else:
		_chase_player()

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

func _chase_player() -> void:
	var direction = get_direction_to_player()
	linear_velocity = direction * speed

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
	
	if should_flee():
		return get_direction_away_from_player()
	
	if ai_type == "hit_and_run" and is_player_in_attack_range():
		return get_direction_away_from_player()
	
	if ai_type == "coward" and (is_player_in_attack_range() or get_distance_to_player() < MIN_ATTACK_DISTANCE * 2):
		return get_direction_away_from_player()
	
	return get_direction_to_player()

func attack() -> void:
	if not can_attack():
		return
	
	linear_velocity = Vector3.ZERO
	print("Mob attacking Player")
	
	is_attacking = true
	attack_timer = ATTACK_DURATION
	attack_cooldown = ATTACK_COOLDOWN

func take_damage(amount: int = 1) -> void:
	if health <= 0:
		return

	mob_model.hurt()
	health = max(0, health - amount)

	if health <= 0:
		_die()

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
	var loot_item_path = "res://Items/Resources/ball.tres" # TODO: Make real Loot for Mob
	var loot_resource = load(loot_item_path)
	
	if not loot_resource:
		push_error("Failed to load loot resource: " + loot_item_path)
		return false
	
	if not world_node:
		push_error("World node not found!")
		return false

	var spawn_position = _calculate_loot_spawn_position()
	var loot_3D = Global.create_3d_item_node(loot_resource, spawn_position)
	
	if not loot_3D:
		push_error("Failed to create 3D loot item: " + loot_resource.name)
		return false
	
	world_node.add_child(loot_3D)
	print("Mob dropped loot: %s at %s" % [loot_resource.name, spawn_position])
	
	queue_free()
	return true

func _calculate_loot_spawn_position() -> Vector3:
	var base_position = mob_model.global_position + mob_model.global_basis.z
	var random_offset = Vector3(randf_range(-0.5, 0.5), randf_range(0, 0.5), randf_range(-0.5, 0.5))
	return base_position + random_offset

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("player"):
		attack()
		
		if body.has_method("take_damage"):
			body.take_damage(damage)

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
