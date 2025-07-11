extends RigidBody3D

@onready var bat_model = %bat_model
@onready var player = %Player
@onready var timer = %Timer
@onready var inventory = %Inventory
@onready var world_node = get_node("../..")

var speed = randf_range(2.0, 4.0)
var health = 5
var damage = 2

var is_attacking = false
var attack_timer = 0.0
var attack_duration = 1.0
var min_distance = 1.25
var attack_cooldown = 0.0

func _ready() -> void:
	add_to_group("mob")

func _physics_process(delta: float) -> void:
	var distance_to_player = global_position.distance_to(player.global_position)
	
	if is_attacking:
		attack_timer -= delta
		if attack_timer <= 0.0:
			is_attacking = false
	
	if attack_cooldown > 0.0: attack_cooldown -= delta
	
	if not is_attacking and distance_to_player > min_distance:
		var direction = global_position.direction_to(player.global_position)
		direction.y = 0.0
		linear_velocity = direction * speed
	elif distance_to_player <= min_distance and not is_attacking:
		var direction = (global_position - player.global_position).normalized()
		direction.y = 0.0
		linear_velocity = direction * speed
	
	var velocity_direction = linear_velocity.normalized()
	if velocity_direction != Vector3.ZERO:
		bat_model.rotation.y = Vector3.FORWARD.signed_angle_to(velocity_direction, Vector3.UP) + PI

func attack() -> void:
	if attack_cooldown > 0.0: return
		
	linear_velocity = Vector3.ZERO
	
	print("ATTACKING")
	
	is_attacking = true
	attack_timer = attack_duration
	attack_cooldown = 10.0

func take_damage() -> void:
	if health == 0: return
	
	bat_model.hurt()
	health -= 1
	
	if health == 0: dead()

func dead() -> void:
	set_physics_process(false)
	gravity_scale = 1.0
	var direction = -1.0 * global_position.direction_to(player.global_position)
	var random_upward_force = Vector3.UP * randf_range(1.0, 5.0)
	apply_central_impulse(direction * 10.0 + random_upward_force)
	timer.start()

func _on_timer_timeout() -> void:
	drop_loot()

func drop_loot() -> bool:
	var item_resource = load("res://Items/Resources/ball.tres")
	var spawn_position = bat_model.global_position + bat_model.global_basis.z
	
	var random_offset = Vector3(randf_range(-0.5, 0.5), randf_range(0, 0.5), randf_range(-0.5, 0.5))
	spawn_position += random_offset
	
	var item_3d = Global._create_3d_item_node(item_resource, spawn_position)
	if not item_3d: return false
	
	queue_free()
	world_node.add_child(item_3d)
	print_rich("[color=green][b]SPAWNED 3D ITEM:[/b][/color] [color=light_green]" + item_resource.name + "[/color] at position [color=light_blue]" + str(spawn_position) + "[/color]")
	return true

func _on_interaction_area_body_entered(body: Node3D) -> void:	
	if body in get_tree().get_nodes_in_group("player"):
		attack()
