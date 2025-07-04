extends CharacterBody3D

@export var player_speed: float = 5.0
@export var rotation_speed: float = 10.0
@export var jump_height: float = 1.0
@export var gravity_value: float = -9.81

@onready var follow_camera: Camera3D = get_node("../CameraController/Camera3D")
@onready var global: Global = get_node("/root/Global")
@onready var inventory: Inventory = get_node("../UI/Inventory")

var objects_in_range := []

func _ready():
	if not is_on_floor():
		velocity.y = gravity_value

func _process(_delta: float) -> void:
	_set_nearest_object()
	
	if Input.is_action_just_pressed("Interact"):
		interact()

func interact():
	if objects_in_range == []: return
	
	var nearest_object = null
	for object in objects_in_range:
		# Check if object is still valid before accessing properties
		if is_instance_valid(object) and object.selected:
			nearest_object = object
			break
	
	if nearest_object and is_instance_valid(nearest_object):
		var item_resource = load(nearest_object.resource)
		if item_resource:
			if inventory:
				var success = inventory.add_item(item_resource)
				if success:
					nearest_object.queue_free()
					objects_in_range.erase(nearest_object)
				else:
					print_rich("[color=red][b]ERROR:[/b] Failed to add item to inventory![/color]")
			else:
				print_rich("[color=red][b]ERROR:[/b] Inventory not found![/color]")
		else:
			print_rich("[color=red][b]ERROR:[/b] Failed to load item resource: " + nearest_object.resource + "![/color]")

func _set_nearest_object():
	if objects_in_range.is_empty(): return
	
	# Clean up invalid objects first
	objects_in_range = objects_in_range.filter(func(obj): return is_instance_valid(obj))
	
	if objects_in_range.is_empty(): return
	
	var nearest_object = null
	for object in objects_in_range:
		if is_instance_valid(object):
			object.set_selection(false)
			if not nearest_object:
				nearest_object = object
			elif nearest_object.global_position.distance_to(global_position) > object.global_position.distance_to(global_position):
				nearest_object = object
	
	if nearest_object and is_instance_valid(nearest_object):
		nearest_object.set_selection(true)

func _physics_process(delta):
	movement(delta)

func movement(delta):
	if not is_on_floor():
		velocity.y += gravity_value * delta
	else:
		if velocity.y < 0:
			velocity.y = 0

	var horizontal_input = Input.get_axis("move_left", "move_right")
	var vertical_input = Input.get_axis("move_forward", "move_back")
	var camera_transform = follow_camera.global_transform
	var camera_basis = camera_transform.basis
	var movement_input = camera_basis * Vector3(horizontal_input, 0, vertical_input)
	movement_input.y = 0  # Ensure we don't move vertically based on camera angle
	var movement_direction = movement_input.normalized()
	
	velocity.x = movement_direction.x * player_speed
	velocity.z = movement_direction.z * player_speed
	
	if movement_direction != Vector3.ZERO:
		var desired_rotation = transform.looking_at(global_position + movement_direction, Vector3.UP)
		transform.basis = transform.basis.slerp(desired_rotation.basis, rotation_speed * delta)
	
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = sqrt(jump_height * -3.0 * gravity_value)
	
	move_and_slide()

func _on_interaction_area_body_entered(body: Node3D) -> void:
	if body in get_tree().get_nodes_in_group("object"):
		objects_in_range.append(body)

func _on_interaction_area_body_exited(body: Node3D) -> void:
	if body in get_tree().get_nodes_in_group("object"):
		# Check if the object is still valid before calling methods
		if is_instance_valid(body):
			body.set_selection(false)
		# Remove from array regardless of validity
		objects_in_range.erase(body)
