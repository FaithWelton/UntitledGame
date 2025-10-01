extends Node
class_name BulletPool

const BULLET_SCENE = preload("res://Projectiles/Bullet.tscn")

@export var pool_size: int = 50
@export var auto_expand: bool = true

var available_bullets: Array[Bullet] = []
var active_bullets: Array[Bullet] = []

func _ready() -> void:
	add_to_group("bullet_pool")
	_initialize_pool()

func _initialize_pool() -> void:
	for i in range(pool_size):
		var bullet = BULLET_SCENE.instantiate() as Bullet
		bullet.process_mode = Node.PROCESS_MODE_DISABLED
		bullet.hide()
		add_child(bullet)
		available_bullets.append(bullet)

func get_bullet() -> Bullet:
	var bullet: Bullet = null

	if available_bullets.is_empty():
		if auto_expand:
			bullet = BULLET_SCENE.instantiate() as Bullet
			add_child(bullet)
		else:
			push_warning("Bullet pool exhausted and auto_expand is disabled")
			return null
	else:
		bullet = available_bullets.pop_back()

	if bullet:
		active_bullets.append(bullet)
		bullet.process_mode = Node.PROCESS_MODE_INHERIT
		bullet.show()

	return bullet

func return_bullet(bullet: Bullet) -> void:
	if not bullet or not is_instance_valid(bullet):
		return

	var index = active_bullets.find(bullet)
	if index >= 0:
		active_bullets.remove_at(index)

	# Reset bullet state
	bullet.travelled_distance = 0.0
	bullet.shooter = null
	bullet.damage = 10
	bullet.position = Vector3.ZERO
	bullet.rotation = Vector3.ZERO
	bullet.process_mode = Node.PROCESS_MODE_DISABLED
	bullet.hide()

	if not available_bullets.has(bullet):
		available_bullets.append(bullet)

func get_stats() -> Dictionary:
	return {
		"total": available_bullets.size() + active_bullets.size(),
		"available": available_bullets.size(),
		"active": active_bullets.size()
	}
