extends Label3D
class_name DamageNumber

@export var float_speed: float = 1.0
@export var lifetime: float = 1.0
@export var fade_start: float = 0.5

var elapsed_time: float = 0.0

func _ready() -> void:
	billboard = BaseMaterial3D.BILLBOARD_ENABLED
	no_depth_test = true
	modulate = Color.WHITE

func initialize(damage_amount: int, spawn_position: Vector3, is_critical: bool = false) -> void:
	global_position = spawn_position

	if is_critical:
		text = "CRIT! " + str(damage_amount)
		modulate = Color(1.0, 0.3, 0.0)  # Bright orange for crits
		font_size = 120
		outline_size = 8
		outline_modulate = Color.BLACK
	else:
		text = str(damage_amount)
		modulate = Color.WHITE
		font_size = 50
		outline_size = 4
		outline_modulate = Color.BLACK

func _process(delta: float) -> void:
	elapsed_time += delta

	# Float upward
	position.y += float_speed * delta

	# Fade out
	if elapsed_time >= fade_start:
		var fade_progress = (elapsed_time - fade_start) / (lifetime - fade_start)
		modulate.a = 1.0 - fade_progress

	# Remove when lifetime expires
	if elapsed_time >= lifetime:
		queue_free()
