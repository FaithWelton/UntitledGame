extends Area3D
class_name DeathZone

signal player_entered_zone(player: Node3D)
signal item_entered_zone(item: Node3D)

enum HazardType {
	WATER,      # Floats, pushes to shore, no damage
	LAVA,       # Floats slightly, damage over time
	QUICKSAND,  # Pulls down, damage when fully submerged
	VOID        # Instant death
}

@export var hazard_type: HazardType = HazardType.WATER
@export var surface_height: float = -0.1#-0.3  # Y position of hazard surface
@export var buoyancy_force: float = 20.0  # Upward force (ignored for VOID)
@export var drag_force: float = 0.95  # Movement dampening
@export var push_to_shore_force: float = 2.0  # Force pushing items toward center
@export var damage_per_second: int = 10  # For LAVA or QUICKSAND
@export var pull_down_force: float = 5.0  # For QUICKSAND

var bodies_in_zone: Array = []
var player_damage_timer: float = 0.0

func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)

func _physics_process(delta: float) -> void:
	for body in bodies_in_zone:
		if not is_instance_valid(body):
			continue

		if body.is_in_group("player"):
			_apply_hazard_physics_to_player(body, delta)
		elif body.is_in_group("object"):
			_apply_hazard_physics_to_item(body, delta)
		elif body.is_in_group("mob"):
			_apply_hazard_physics_to_mob(body, delta)

func _on_body_entered(body: Node3D) -> void:
	if body in bodies_in_zone:
		return

	# VOID instantly kills everything
	if hazard_type == HazardType.VOID:
		_handle_void_death(body)
		return

	bodies_in_zone.append(body)

	if body.is_in_group("player"):
		player_entered_zone.emit(body)
		print("Player entered %s zone!" % HazardType.keys()[hazard_type])
		if body.has_method("enter_water"):
			body.enter_water()
		player_damage_timer = 0.0  # Reset damage timer
	elif body.is_in_group("object"):
		item_entered_zone.emit(body)

func _on_body_exited(body: Node3D) -> void:
	if body in bodies_in_zone:
		bodies_in_zone.erase(body)

	if body.is_in_group("player"):
		if body.has_method("exit_water"):
			body.exit_water()
		player_damage_timer = 0.0

func _handle_void_death(body: Node3D) -> void:
	if body.is_in_group("player"):
		if body.has_method("die_from_falling"):
			body.die_from_falling()
	elif body.is_in_group("mob"):
		if body.has_method("drop_loot_at_safe_position"):
			body.drop_loot_at_safe_position()
		body.queue_free()
	elif body.is_in_group("object"):
		body.queue_free()  # Items are lost in void

func _apply_hazard_physics_to_player(player: Node3D, delta: float) -> void:
	if not player is CharacterBody3D:
		return

	match hazard_type:
		HazardType.WATER:
			_apply_water_physics(player, delta)
		HazardType.LAVA:
			_apply_lava_physics(player, delta)
		HazardType.QUICKSAND:
			_apply_quicksand_physics(player, delta)

func _apply_hazard_physics_to_item(item: Node3D, _delta: float) -> void:
	if not item is RigidBody3D:
		return

	match hazard_type:
		HazardType.WATER, HazardType.LAVA:
			# Apply buoyancy to keep item floating
			if item.global_position.y < surface_height:
				item.apply_central_force(Vector3.UP * buoyancy_force)
			# Push item toward center (shore)
			var direction_to_center = Vector3(-item.global_position.x, 0, -item.global_position.z).normalized()
			item.apply_central_force(direction_to_center * push_to_shore_force)
			# Apply drag
			item.linear_velocity *= drag_force
			item.angular_velocity *= drag_force
		HazardType.QUICKSAND:
			# Pull down in quicksand
			item.apply_central_force(Vector3.DOWN * pull_down_force)
			item.linear_velocity *= 0.8  # Heavy drag

func _apply_hazard_physics_to_mob(mob: Node3D, _delta: float) -> void:
	# Mobs die in all hazards - drop loot and delete
	if mob.has_method("drop_loot_at_safe_position"):
		mob.drop_loot_at_safe_position()
	mob.queue_free()
	bodies_in_zone.erase(mob)

func _apply_water_physics(player: CharacterBody3D, delta: float) -> void:
	# Apply buoyancy - keep player floating at surface
	if player.global_position.y < surface_height:
		var buoyancy = Vector3.UP * buoyancy_force
		player.velocity += buoyancy * delta
	# Apply drag
	player.velocity *= drag_force

func _apply_lava_physics(player: CharacterBody3D, delta: float) -> void:
	# Less buoyancy than water
	if player.global_position.y < surface_height:
		var buoyancy = Vector3.UP * (buoyancy_force * 0.5)
		player.velocity += buoyancy * delta
	player.velocity *= drag_force

	# Apply damage over time
	player_damage_timer += delta
	if player_damage_timer >= 1.0:
		if player.has_method("take_damage"):
			player.take_damage(damage_per_second, "lava")
		player_damage_timer = 0.0

func _apply_quicksand_physics(player: CharacterBody3D, delta: float) -> void:
	# Pull player down
	player.velocity += Vector3.DOWN * pull_down_force * delta
	# Heavy drag
	player.velocity *= 0.7

	# Apply damage if fully submerged
	if player.global_position.y < surface_height - 1.0:
		player_damage_timer += delta
		if player_damage_timer >= 1.0:
			if player.has_method("take_damage"):
				player.take_damage(damage_per_second, "quicksand")
			player_damage_timer = 0.0
