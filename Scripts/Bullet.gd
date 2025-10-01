extends Area3D
class_name Bullet

@export var speed: float = 20.0
@export var max_range: float = 40.0
@export var damage: int = 10
@export var friendly_fire: bool = false

var travelled_distance: float = 0.0
var shooter: Node3D = null
var pool: BulletPool = null

func _ready() -> void:
	add_to_group("projectile")

func initialize(from: Node3D, bullet_damage: int = 10, bullet_pool: BulletPool = null) -> void:
	shooter = from
	damage = bullet_damage
	pool = bullet_pool
	travelled_distance = 0.0

func _physics_process(delta: float) -> void:
	var distance_this_frame = speed * delta
	position += -transform.basis.z * distance_this_frame
	travelled_distance += distance_this_frame

	if travelled_distance > max_range:
		_deactivate()

func _on_body_entered(body: Node3D) -> void:
	# Don't hit the shooter
	if body == shooter:
		return

	# Don't hit teammates unless friendly fire is enabled
	if not friendly_fire and _is_same_team(body):
		return

	# Apply damage if the body can take damage
	if body.has_method("take_damage"):
		body.take_damage(damage)

	_deactivate()

func _is_same_team(body: Node3D) -> bool:
	if not shooter:
		return false

	# Both player or both mob = same team
	var shooter_is_player = shooter.is_in_group("player")
	var body_is_player = body.is_in_group("player")
	var shooter_is_mob = shooter.is_in_group("mob")
	var body_is_mob = body.is_in_group("mob")

	return (shooter_is_player and body_is_player) or (shooter_is_mob and body_is_mob)

func _deactivate() -> void:
	if pool:
		pool.return_bullet(self)
	else:
		queue_free()
