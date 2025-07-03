extends CharacterBody3D

@export var player_speed: float = 5.0
@export var rotation_speed: float = 10.0
@export var jump_height: float = 1.0
@export var gravity_value: float = -9.81

@onready var follow_camera: Camera3D = get_node("../CameraController/Camera3D")
@onready var global: Global = get_node("/root/Global")

func _ready():
	# Ensure we're using the default gravity if not set
	if not is_on_floor():
		velocity.y = gravity_value
	
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _physics_process(delta):
	movement(delta)

func movement(delta):
	# Handle gravity
	if not is_on_floor():
		velocity.y += gravity_value * delta
	else:
		# Reset vertical velocity when grounded
		if velocity.y < 0:
			velocity.y = 0

	# Get input
	var horizontal_input = Input.get_axis("move_left", "move_right")
	var vertical_input = Input.get_axis("move_forward", "move_back")
	
	# Calculate movement direction relative to camera
	var camera_transform = follow_camera.global_transform
	var camera_basis = camera_transform.basis
	
	# Remove Y rotation from camera basis for movement calculation
	var movement_input = camera_basis * Vector3(horizontal_input, 0, vertical_input)
	movement_input.y = 0  # Ensure we don't move vertically based on camera angle
	var movement_direction = movement_input.normalized()
	
	# Apply horizontal movement
	velocity.x = movement_direction.x * player_speed
	velocity.z = movement_direction.z * player_speed
	
	# Handle rotation
	if movement_direction != Vector3.ZERO:
		var desired_rotation = transform.looking_at(global_position + movement_direction, Vector3.UP)
		transform.basis = transform.basis.slerp(desired_rotation.basis, rotation_speed * delta)
	
	# Handle jumping
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = sqrt(jump_height * -3.0 * gravity_value)
	
	# Move the character
	move_and_slide()
