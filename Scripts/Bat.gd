extends Mob
class_name Bat

func _init() -> void:
	# Bats can only be aggressive or hit_and_run (not coward)
	ai_types_available = ["aggressive", "hit_and_run"]

	# Setup loot table
	loot_table = LootTable.new()
	# 60% chance to drop 1-2 health potions
	loot_table.add_loot("res://Items/Resources/potion_health.tres", 0.6, 1, 2)
	# 10% chance to drop a revive potion (rare!)
	loot_table.add_loot("res://Items/Resources/potion_revive.tres", 0.1, 1, 1)

# Bat-specific flying constants
const HOVER_HEIGHT: float = 1.0  # Desired flying height
const MAX_HEIGHT: float = 3.5  # Maximum height before forcing down
const MIN_HEIGHT: float = 0.5  # Minimum height to avoid death zone
const HEIGHT_CORRECTION_FORCE: float = 5.0
const HEIGHT_AVOIDANCE_RANGE: float = 1.5  # Distance to check for vertical avoidance
const PLATFORM_EDGE: float = 25.0  # Platform edge (actual boundary)
const EDGE_COMFORT_ZONE: float = 2.0  # Can go this far past edge
const SHORE_PUSH_FORCE: float = 3.0  # Force to push away from edge

# Bat-specific movement variables
var orbit_direction_modifier: float = 1.0  # Randomized orbit direction
var orbit_speed_modifier: float = 1.0  # Randomized orbit speed
var orbit_change_timer: float = 0.0
var preferred_orbit_angle: float = 0.0  # Preferred angle around player (0-360)

func _initialize_mob() -> void:
	super._initialize_mob()
	preferred_orbit_angle = randf_range(0, TAU)  # Random angle around player
	_randomize_orbit_behavior()

func _handle_movement(delta: float) -> void:
	_handle_height_control(delta)
	_handle_ai_movement()

func _update_timers(delta: float) -> void:
	super._update_timers(delta)

	# Periodically change orbit behavior for variety
	orbit_change_timer -= delta
	if orbit_change_timer <= 0.0:
		_randomize_orbit_behavior()

func _handle_height_control(_delta: float) -> void:
	var current_height = global_position.y

	# Check if there are nearby bats at similar height - fly up/down to avoid
	var should_adjust_height = _should_adjust_height_for_avoidance()

	# CRITICAL: Prevent falling into death zone (highest priority)
	if current_height < MIN_HEIGHT:
		apply_central_force(Vector3.UP * HEIGHT_CORRECTION_FORCE * 2.0)  # Strong upward force
		if linear_velocity.y < 0:
			linear_velocity.y = 0  # Cancel downward velocity
	elif should_adjust_height != 0:
		# Apply vertical force to fly over/under nearby bats
		apply_central_force(Vector3.UP * should_adjust_height * HEIGHT_CORRECTION_FORCE * 0.3)
	# If too high, apply strong downward force
	elif current_height > MAX_HEIGHT:
		apply_central_force(Vector3.DOWN * HEIGHT_CORRECTION_FORCE)
		# Also dampen upward velocity
		if linear_velocity.y > 0:
			linear_velocity.y *= 0.5
	# If too low, apply gentle upward force to maintain hover
	elif current_height < HOVER_HEIGHT:
		var lift_force = (HOVER_HEIGHT - current_height) * HEIGHT_CORRECTION_FORCE * 0.5
		apply_central_force(Vector3.UP * lift_force)
	# At good height, dampen vertical movement to stabilize
	else:
		linear_velocity.y *= 0.85

func _chase_player() -> void:
	var distance_to_player = get_distance_to_player()
	var direction = get_direction_to_player()
	var separation = _get_separation_vector()

	# Check if near edge and push back toward center
	var boundary_push = _get_boundary_push_force()
	if boundary_push.length() > 0:
		# Prioritize staying on shore
		var final_direction = (direction * 0.3 + boundary_push * SHORE_PUSH_FORCE + separation * SEPARATION_FORCE).normalized()
		linear_velocity = final_direction * speed * 0.6
		return

	# If separation force is strong (crowded), prioritize getting around other bats
	if separation.length() > 0.5:
		# Move in separation direction to get around other bats
		var final_direction = (direction * 0.3 + separation * SEPARATION_FORCE).normalized()
		linear_velocity = final_direction * speed * 0.8
		return

	# If at ideal attack distance, orbit around player instead of stopping
	if distance_to_player >= MIN_DISTANCE_TO_PLAYER and distance_to_player <= MIN_ATTACK_DISTANCE:
		# Calculate desired position based on preferred angle
		var desired_direction = _get_preferred_orbit_direction()

		# Create orbit vector (perpendicular to direction, moving toward preferred angle)
		var orbit_direction = Vector3(-direction.z * orbit_direction_modifier, 0, direction.x * orbit_direction_modifier).normalized()

		# Blend orbit with movement toward preferred angle
		var move_to_preferred = (desired_direction - direction).normalized()
		orbit_direction = (orbit_direction * 0.6 + move_to_preferred * 0.4).normalized()

		# Add some wobble by mixing in forward/backward movement
		var wobble_amount = randf_range(-0.2, 0.2)
		var wobble_direction = direction * wobble_amount

		var final_direction = (orbit_direction + wobble_direction + separation * SEPARATION_FORCE).normalized()
		linear_velocity = final_direction * speed * 0.6 * orbit_speed_modifier
		return

	# Too close, back away slightly
	if distance_to_player < MIN_DISTANCE_TO_PLAYER:
		var away_direction = get_direction_away_from_player()
		linear_velocity = away_direction * speed * 0.3
		return

	# Approach player
	var final_direction = (direction + separation * SEPARATION_FORCE).normalized()

	# Slow down as we get closer
	var speed_multiplier = 1.0
	if distance_to_player < MIN_ATTACK_DISTANCE * 1.2:
		speed_multiplier = 0.7

	linear_velocity = final_direction * speed * speed_multiplier

func _randomize_orbit_behavior() -> void:
	# Randomize orbit direction (clockwise or counterclockwise)
	orbit_direction_modifier = 1.0 if randf() > 0.5 else -1.0

	# Randomize orbit speed (0.8 to 1.2x normal)
	orbit_speed_modifier = randf_range(0.8, 1.2)

	# Set next time to change orbit behavior (2-5 seconds)
	orbit_change_timer = randf_range(2.0, 5.0)

func _get_preferred_orbit_direction() -> Vector3:
	if not player:
		return Vector3.ZERO

	# Calculate direction from player to preferred angle
	var x = cos(preferred_orbit_angle)
	var z = sin(preferred_orbit_angle)
	return Vector3(x, 0, z).normalized()

func _should_adjust_height_for_avoidance() -> float:
	# Returns: 1.0 to fly up, -1.0 to fly down, 0.0 to stay at current height
	var nearby_mobs = get_tree().get_nodes_in_group("mob")
	var current_height = global_position.y

	var bats_above = 0
	var bats_below = 0

	for other_mob in nearby_mobs:
		if other_mob == self or not is_instance_valid(other_mob):
			continue

		# Check horizontal distance
		var horizontal_distance = Vector2(global_position.x, global_position.z).distance_to(
			Vector2(other_mob.global_position.x, other_mob.global_position.z)
		)

		# Only consider bats that are close horizontally
		if horizontal_distance < HEIGHT_AVOIDANCE_RANGE:
			var height_diff = other_mob.global_position.y - current_height

			# If another bat is at similar height (within 0.5 units)
			if abs(height_diff) < 0.5:
				# Count bats above and below to decide which way to go
				if height_diff > 0:
					bats_above += 1
				else:
					bats_below += 1

	# If there are bats blocking at similar height, fly up or down
	if bats_above > 0 or bats_below > 0:
		# Fly up if more bats below, down if more bats above
		if bats_below > bats_above:
			return 1.0  # Fly up
		elif bats_above > bats_below:
			return -1.0  # Fly down
		else:
			# Equal number above and below, choose randomly
			return 1.0 if randf() > 0.5 else -1.0

	return 0.0  # No avoidance needed

func _get_boundary_push_force() -> Vector3:
	var pos = global_position
	var push = Vector3.ZERO
	var max_boundary = PLATFORM_EDGE + EDGE_COMFORT_ZONE

	# Check each axis independently - only push if beyond comfort zone
	# X axis
	if pos.x > max_boundary:
		push.x = -1.0 * (pos.x - max_boundary)  # Push left
	elif pos.x < -max_boundary:
		push.x = 1.0 * (-max_boundary - pos.x)  # Push right

	# Z axis
	if pos.z > max_boundary:
		push.z = -1.0 * (pos.z - max_boundary)  # Push forward
	elif pos.z < -max_boundary:
		push.z = 1.0 * (-max_boundary - pos.z)  # Push backward

	# Normalize and return if there's any push force
	if push.length() > 0:
		return push.normalized()

	return Vector3.ZERO
