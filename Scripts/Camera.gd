extends Camera3D

@export var lerp_speed: float

var offset: Vector3 = Vector3(0, 3, -3)
var target: CharacterBody3D

func _ready() -> void:
	target = get_parent() as CharacterBody3D

func _process(delta: float) -> void:
	if not target or not is_instance_valid(target):
		return
	
	global_position = global_position.lerp(target.global_position + offset, lerp_speed * delta)
