extends CharacterBody3D
class_name Player

@export var player_speed: float = 5.0
@export var rotation_speed: float = 10.0
@export var jump_height: float = 1.0
@export var gravity_value: float = -9.81
@export var mouse_sensitivity: float = 0.003
@export var zoom_sensitivity: float = 0.5
@export var min_zoom: float = 2.0
@export var max_zoom: float = 8.0

@onready var shoot_timer: Timer = %Timer
@onready var projectile_spawner: Node3D = %ProjectileSpawner
@onready var spring_arm: SpringArm3D = $SpringArm3D
@onready var camera: Camera3D = $SpringArm3D/Camera3D

var inventory: Inventory
var objects_in_range: Array[Node3D] = []
var camera_rotation: Vector2 = Vector2.ZERO

func _ready() -> void:
	add_to_group("player")
	_find_inventory()
	_initialize_player()
	_setup_spring_arm()
	capture_mouse()

	PlayerStats.player_revived.connect(_revive)
	PlayerStats.player_respawned.connect(_respawn)

func _find_inventory() -> void:
	var inventories = get_tree().get_nodes_in_group("inventory")

	if inventories.is_empty():
		push_warning("No inventory found! Make sure the inventory node is in the 'inventory' group")
		return

	inventory = inventories[0]

func _setup_spring_arm() -> void:
	if not spring_arm:
		push_error("SpringArm3D not found")
		return
	
	spring_arm.spring_length = 5.0  # Default zoom distance
	spring_arm.collision_mask = 1  # Adjust based on your collision layers

func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func free_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _initialize_player() -> void:
	if not is_on_floor():
		velocity.y = gravity_value

func _input(event: InputEvent) -> void:	
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_mouse_look(event.relative)
	elif event is InputEventMouseButton and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_zoom(event)
	elif event is InputEventPanGesture and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		_handle_pan_zoom(event)

func _handle_mouse_look(mouse_delta: Vector2) -> void:
	camera_rotation.x -= mouse_delta.y * mouse_sensitivity
	camera_rotation.y -= mouse_delta.x * mouse_sensitivity
	
	camera_rotation.x = clamp(camera_rotation.x, -1.2, 0.5)
	
	if spring_arm:
		spring_arm.rotation.x = camera_rotation.x
	
	rotation.y = camera_rotation.y

func _handle_zoom(event: InputEventMouseButton) -> void:
	if not spring_arm:
		return
		
	var zoom_delta = 0.0
	
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_delta = -zoom_sensitivity
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_delta = zoom_sensitivity
	
	if zoom_delta != 0.0:
		var new_length = spring_arm.spring_length + zoom_delta
		spring_arm.spring_length = clamp(new_length, min_zoom, max_zoom)

func _handle_pan_zoom(event: InputEventPanGesture) -> void:
	if not spring_arm:
		return
	
	var zoom_delta = event.delta.y * zoom_sensitivity * 0.1
	var new_length = spring_arm.spring_length + zoom_delta
	spring_arm.spring_length = clamp(new_length, min_zoom, max_zoom)

func _process(_delta: float) -> void:
	_handle_input()
	_update_object_selection()

func _handle_input() -> void:
	if PlayerStats.dead:
		return
	
	if Input.is_action_just_pressed("interact"):
		interact()
	
	if Input.is_action_just_pressed("shoot") and shoot_timer.is_stopped():
		shoot_bullet()
		
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			free_mouse()
		else:
			capture_mouse()

func _update_object_selection() -> void:
	_clear_invalid_objects()
	
	if objects_in_range.is_empty():
		return
	
	var nearest_object = _find_nearest_object()
	_set_all_objects_unselected()
	
	if nearest_object and is_instance_valid(nearest_object):
		nearest_object.set_selection(true)

func _clear_invalid_objects() -> void:
	objects_in_range = objects_in_range.filter(func(obj): return is_instance_valid(obj))

func _find_nearest_object() -> Node3D:
	var nearest: Node3D = null
	var nearest_distance: float = INF
	
	for obj in objects_in_range:
		if not is_instance_valid(obj):
			continue
		
		var distance = global_position.distance_to(obj.global_position)
		if distance < nearest_distance:
			nearest = obj
			nearest_distance = distance
	
	return nearest

func _set_all_objects_unselected() -> void:
	for obj in objects_in_range:
		if is_instance_valid(obj):
			obj.set_selection(false)

func interact() -> void:
	var target_object = _get_selected_object()
	if not target_object or not is_instance_valid(target_object):
		return
	
	if not "resource" in target_object or target_object.resource.is_empty():
		push_error("Target object has no resource path")
		return
	
	var item_resource = _load_item_resource(target_object.resource)
	if not item_resource:
		return
	
	if _add_to_inventory(item_resource):
		_remove_object(target_object)

func _get_selected_object() -> Node3D:
	for obj in objects_in_range:
		if is_instance_valid(obj) and obj.selected:
			return obj
	
	return null

func _load_item_resource(resource_path: String) -> Resource:
	var resource = load(resource_path)
	if not resource:
		push_error("Failed to load item resource: " + resource_path)
		return null
	
	return resource

func _add_to_inventory(item: Item) -> bool:
	if not inventory:
		push_error("Inventory not found!")
		return false
	
	if not item:
		push_error("Cannot add null item to inventory!")
		return false
	
	return inventory.add_item(item)

func _remove_object(obj: Node3D) -> void:
	obj.queue_free()
	objects_in_range.erase(obj)

func shoot_bullet() -> void:
	const BULLET_SCENE = preload("res://Projectiles/Bullet.tscn")
	var bullet = BULLET_SCENE.instantiate()

	projectile_spawner.add_child(bullet)
	bullet.global_transform = projectile_spawner.global_transform

	# Initialize bullet with shooter reference and damage based on player strength
	var bullet_damage = max(10, PlayerStats.strength / 5)
	bullet.initialize(self, bullet_damage)

	shoot_timer.start()

func _physics_process(delta) -> void:
	_handle_movement(delta)

func _handle_movement(delta) -> void:
	if PlayerStats.dead:
		velocity = Vector3.ZERO
		return
	
	if not is_on_floor():
		velocity.y += gravity_value * delta
	elif velocity.y < 0:
		velocity.y = 0

	var input_vector = Vector2.ZERO
	
	if Input.is_action_pressed("move_forward"):
		input_vector.y += 1
		
	if Input.is_action_pressed("move_back"):
		input_vector.y -= 1
	
	if Input.is_action_pressed("move_left"):
		input_vector.x -= 1
	
	if Input.is_action_pressed("move_right"):
		input_vector.x += 1
		
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = sqrt(jump_height * -3.0 * gravity_value)
	
	input_vector = input_vector.normalized()
	
	var direction = Vector3.ZERO
	
	if input_vector.length() > 0 and camera:
		var camera_forward = -camera.global_transform.basis.z
		var camera_right = camera.global_transform.basis.x
		
		camera_forward.y = 0
		camera_right.y = 0
		camera_forward = camera_forward.normalized()
		camera_right = camera_right.normalized()
		
		direction = camera_forward * input_vector.y + camera_right * input_vector.x
	
	velocity.x = direction.x * player_speed
	velocity.z = direction.z * player_speed
	
	move_and_slide()

func take_damage(amount: int) -> void:	
	if PlayerStats.dead: # Exit early if already dead
		return
	
	#player.hurt() # TODO: Create Hurt Animation for Player
	PlayerStats.decrement_health(amount)
	
	if PlayerStats.dead:
		_die()

func _die() -> void:
	set_physics_process(false)
	# TODO: Play Death Animation
	# TODO: Change Player Appearance to Dead

func _revive() -> void:
	set_physics_process(true)
	# TODO: Play Revival Animation
	# TODO: Restore Player Appearance

func _respawn() -> void:
	set_physics_process(true)
	# TODO: Play Respawn Animation
	# TODO: Restore Player Appearance

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body in get_tree().get_nodes_in_group("object"):
		objects_in_range.append(body)

func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body in get_tree().get_nodes_in_group("object"):
		if is_instance_valid(body): body.set_selection(false)
		objects_in_range.erase(body)
