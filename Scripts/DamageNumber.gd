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

func initialize(damage_amount: int, position: Vector3, is_critical: bool = false) -> void:
	text = str(damage_amount)
	global_position = position

	if is_critical:
		modulate = Color(1.0, 0.5, 0.0)  # Orange for crits
		font_size = 100
	else:
		modulate = Color.WHITE
		font_size = 50

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
