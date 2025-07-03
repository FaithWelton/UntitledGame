extends Node3D

@export var mouse_sensitivity: float = 3.0
@export var distance_from_target: float = 1.0
@export var smooth_time: float = 0.2
@export var rotation_x_min: float = -40.0
@export var rotation_x_max: float = 40.0

@onready var target: Node3D = get_node("../Player")
@onready var camera: Camera3D = $Camera3D

var rotation_y: float = 0.0
var rotation_x: float = 0.0
var current_rotation: Vector3 = Vector3.ZERO
var smooth_velocity: Vector3 = Vector3.ZERO

func _ready():
	# Capture mouse for camera control
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	process_mode = Node.PROCESS_MODE_PAUSABLE

func _input(event):
	if event is InputEventMouseMotion:
		var mouse_delta = event.relative
		
		rotation_y += mouse_delta.x * mouse_sensitivity * 0.01
		rotation_x -= mouse_delta.y * mouse_sensitivity * 0.01
		
		# Clamp vertical rotation
		rotation_x = clamp(rotation_x, deg_to_rad(rotation_x_min), deg_to_rad(rotation_x_max))

func _process(delta):
	# Create target rotation
	var next_rotation = Vector3(rotation_x, rotation_y, 0)
	
	# Smooth the rotation
	current_rotation = smooth_damp_vector3(current_rotation, next_rotation, smooth_velocity, smooth_time, delta)
	
	# Apply rotation to the camera controller
	transform.basis = Basis.from_euler(current_rotation)
	
	# Position camera behind target
	if target:
		global_position = target.global_position - transform.basis.z * distance_from_target

# Custom smooth damp function for Vector3 (similar to Unity's SmoothDamp)
func smooth_damp_vector3(current: Vector3, target: Vector3, current_velocity: Vector3, smooth_time: float, delta: float) -> Vector3:
	var omega = 2.0 / smooth_time
	var x = omega * delta
	var expo = 1.0 / (1.0 + x + 0.48 * x * x + 0.235 * x * x * x)
	
	var change = current - target
	var max_change = INF
	
	change = change.limit_length(max_change)
	target = current - change
	
	var temp = (current_velocity + omega * change) * delta
	current_velocity = (current_velocity - omega * temp) * expo
	var result = target + (change + temp) * expo
	
	smooth_velocity = current_velocity
	return result
