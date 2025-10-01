extends Node
class_name CameraShake

@export var camera: Camera3D
@export var decay_rate: float = 2.0

var trauma: float = 0.0
var max_offset: Vector3 = Vector3(0.1, 0.1, 0.05)
var max_rotation: Vector3 = Vector3(0.05, 0.05, 0.1)

func _ready() -> void:
	add_to_group("camera_shake")

func add_trauma(amount: float) -> void:
	trauma = min(trauma + amount, 1.0)

func _process(delta: float) -> void:
	if trauma > 0:
		trauma = max(trauma - decay_rate * delta, 0.0)
		_apply_shake()
	else:
		_reset_camera()

func _apply_shake() -> void:
	if not camera:
		return

	var shake = trauma * trauma  # Square for smoother falloff

	# Random offset
	var offset = Vector3(
		randf_range(-max_offset.x, max_offset.x) * shake,
		randf_range(-max_offset.y, max_offset.y) * shake,
		randf_range(-max_offset.z, max_offset.z) * shake
	)

	# Random rotation
	var rotation = Vector3(
		randf_range(-max_rotation.x, max_rotation.x) * shake,
		randf_range(-max_rotation.y, max_rotation.y) * shake,
		randf_range(-max_rotation.z, max_rotation.z) * shake
	)

	camera.h_offset = offset.x
	camera.v_offset = offset.y
	camera.rotation = rotation

func _reset_camera() -> void:
	if not camera:
		return

	camera.h_offset = 0
	camera.v_offset = 0
	camera.rotation = Vector3.ZERO
