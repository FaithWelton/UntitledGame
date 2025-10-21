extends Node

const SAVE_DIR = "user://saves/"
const MAX_SAVES = 10

var current_save_slot: int = 0  # Currently active save slot

func _ready() -> void:
	# Ensure save directory exists
	if not DirAccess.dir_exists_absolute(SAVE_DIR):
		DirAccess.make_dir_absolute(SAVE_DIR)

func save_game(slot: int = -1, skip_confirmation: bool = false) -> bool:
	# If no slot specified, use current slot
	if slot == -1:
		slot = current_save_slot

	# If current slot is invalid (new game with all slots full), find oldest
	if slot < 0 or slot >= MAX_SAVES:
		if not skip_confirmation:
			# Don't save yet, return false to trigger confirmation in caller
			return false
		else:
			# Confirmation already done, use oldest slot
			slot = get_oldest_save_slot()
			if slot == -1:
				push_error("Failed to find save slot")
				return false

	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"slot": slot,
		"player_stats": _get_player_stats_data(),
		"player_position": _get_player_position_data(),
		"inventory": _get_inventory_data(),
		"game_stats": _get_game_stats_data()
	}

	var save_path = SAVE_DIR + "save_slot_%d.json" % slot
	var file = FileAccess.open(save_path, FileAccess.WRITE)

	if not file:
		push_error("Failed to open save file for writing: " + save_path)
		return false

	var json_string = JSON.stringify(save_data, "\t")
	file.store_string(json_string)
	file.close()

	current_save_slot = slot
	return true

func load_game(slot: int = -1) -> bool:
	# If no slot specified, use current slot
	if slot == -1:
		slot = current_save_slot

	if slot < 0 or slot >= MAX_SAVES:
		push_error("Invalid save slot: " + str(slot))
		return false

	var save_path = SAVE_DIR + "save_slot_%d.json" % slot

	if not FileAccess.file_exists(save_path):
		push_warning("No save file found at: " + save_path)
		return false

	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("Failed to open save file for reading: " + save_path)
		return false

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		push_error("Failed to parse save file JSON")
		return false

	var save_data = json.data

	# Apply loaded data
	_apply_player_stats_data(save_data.get("player_stats", {}))
	_apply_player_position_data(save_data.get("player_position", {}))
	_apply_inventory_data(save_data.get("inventory", {}))
	_apply_game_stats_data(save_data.get("game_stats", {}))

	current_save_slot = slot
	return true

func save_exists(slot: int = -1) -> bool:
	if slot == -1:
		slot = current_save_slot

	if slot < 0 or slot >= MAX_SAVES:
		return false

	return FileAccess.file_exists(SAVE_DIR + "save_slot_%d.json" % slot)

func delete_save(slot: int) -> bool:
	if slot < 0 or slot >= MAX_SAVES:
		return false

	var save_path = SAVE_DIR + "save_slot_%d.json" % slot

	if not FileAccess.file_exists(save_path):
		return false

	DirAccess.remove_absolute(save_path)
	return true

func get_next_available_slot() -> int:
	for i in range(MAX_SAVES):
		if not save_exists(i):
			return i
	return -1  # All slots full

func any_save_exists() -> bool:
	for i in range(MAX_SAVES):
		if save_exists(i):
			return true
	return false

func get_most_recent_save_slot() -> int:
	var most_recent_slot = -1
	var most_recent_time = 0

	for i in range(MAX_SAVES):
		if not save_exists(i):
			continue

		var save_path = SAVE_DIR + "save_slot_%d.json" % i
		var file = FileAccess.open(save_path, FileAccess.READ)
		if not file:
			continue

		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		if json.parse(json_string) == OK:
			var data = json.data
			var timestamp = data.get("timestamp", 0)
			if timestamp > most_recent_time:
				most_recent_time = timestamp
				most_recent_slot = i

	return most_recent_slot

func get_oldest_save_slot() -> int:
	var oldest_slot = -1
	var oldest_time = 9999999999999  # Very large number

	for i in range(MAX_SAVES):
		if not save_exists(i):
			continue

		var save_path = SAVE_DIR + "save_slot_%d.json" % i
		var file = FileAccess.open(save_path, FileAccess.READ)
		if not file:
			continue

		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		if json.parse(json_string) == OK:
			var data = json.data
			var timestamp = data.get("timestamp", 0)
			if timestamp < oldest_time:
				oldest_time = timestamp
				oldest_slot = i

	return oldest_slot

# ===== SAVE DATA COLLECTION =====

func _get_player_stats_data() -> Dictionary:
	return {
		"health": PlayerStats.health,
		"max_health": PlayerStats.max_health,
		"base_health": PlayerStats.base_health,
		"base_max_health": PlayerStats.base_max_health,
		"strength": PlayerStats.strength,
		"base_strength": PlayerStats.base_strength,
		"armor": PlayerStats.armor,
		"base_armor": PlayerStats.base_armor,
		"crit_chance": PlayerStats.crit_chance,
		"base_crit_chance": PlayerStats.base_crit_chance,
		"crit_multiplier": PlayerStats.crit_multiplier,
		"base_crit_multiplier": PlayerStats.base_crit_multiplier,
		"level": PlayerStats.level,
		"dead": PlayerStats.dead
	}

func _get_player_position_data() -> Dictionary:
	var player = get_tree().get_first_node_in_group("player")

	if not player:
		return {}

	return {
		"x": player.global_position.x,
		"y": player.global_position.y,
		"z": player.global_position.z,
		"rotation_y": player.rotation.y
	}

func _get_inventory_data() -> Dictionary:
	var inventory = get_tree().get_first_node_in_group("inventory")

	if not inventory:
		return {}

	var inventory_data = {
		"backpack": [],
		"equip_left": [],
		"equip_right": []
	}

	# Save backpack items
	for slot in inventory.backpack.get_children():
		if slot.item_resource:
			inventory_data.backpack.append(_serialize_item(slot.item_resource))
		else:
			inventory_data.backpack.append(null)

	# Save left equipment
	for slot in inventory.equip_left.get_children():
		if slot.item_resource:
			inventory_data.equip_left.append(_serialize_item(slot.item_resource))
		else:
			inventory_data.equip_left.append(null)

	# Save right equipment
	for slot in inventory.equip_right.get_children():
		if slot.item_resource:
			inventory_data.equip_right.append(_serialize_item(slot.item_resource))
		else:
			inventory_data.equip_right.append(null)

	return inventory_data

func _serialize_item(item: Item) -> Dictionary:
	return {
		"resource_path": item.resource_path,
		"stack_size": item.stack_size,
		"inv_slot": item.inv_slot,
		"inv_position": item.inv_position
	}

func _get_game_stats_data() -> Dictionary:
	return {
		"live_enemies": GameStats.live_enemies
	}

# ===== LOAD DATA APPLICATION =====

func _apply_player_stats_data(data: Dictionary) -> void:
	if data.is_empty():
		return

	PlayerStats.health = data.get("health", PlayerStats.base_health)
	PlayerStats.max_health = data.get("max_health", PlayerStats.base_max_health)
	PlayerStats.base_health = data.get("base_health", 100)
	PlayerStats.base_max_health = data.get("base_max_health", 500)
	PlayerStats.strength = data.get("strength", PlayerStats.base_strength)
	PlayerStats.base_strength = data.get("base_strength", 50)
	PlayerStats.armor = data.get("armor", PlayerStats.base_armor)
	PlayerStats.base_armor = data.get("base_armor", 100)
	PlayerStats.crit_chance = data.get("crit_chance", PlayerStats.base_crit_chance)
	PlayerStats.base_crit_chance = data.get("base_crit_chance", 0.05)
	PlayerStats.crit_multiplier = data.get("crit_multiplier", PlayerStats.base_crit_multiplier)
	PlayerStats.base_crit_multiplier = data.get("base_crit_multiplier", 2.0)
	PlayerStats.level = data.get("level", 1)
	PlayerStats.dead = data.get("dead", false)

	PlayerStats.health_changed.emit(PlayerStats.health)

func _apply_player_position_data(data: Dictionary) -> void:
	if data.is_empty():
		return

	var player = get_tree().get_first_node_in_group("player")

	if not player:
		push_warning("Player not found when loading position")
		return

	player.global_position = Vector3(
		data.get("x", 0.0),
		data.get("y", 1.0),
		data.get("z", 0.0)
	)
	player.rotation.y = data.get("rotation_y", 0.0)

func _apply_inventory_data(data: Dictionary) -> void:
	if data.is_empty():
		return

	var inventory = get_tree().get_first_node_in_group("inventory")

	if not inventory:
		push_warning("Inventory not found when loading")
		return

	# Clear current inventory
	inventory.clear_inventory()

	# Load backpack items
	var backpack_data = data.get("backpack", [])
	var backpack_slots = inventory.backpack.get_children()
	for i in range(min(backpack_data.size(), backpack_slots.size())):
		if backpack_data[i]:
			var item = _deserialize_item(backpack_data[i])
			if item:
				backpack_slots[i].set_new_data(item)

	# Load left equipment
	var equip_left_data = data.get("equip_left", [])
	var equip_left_slots = inventory.equip_left.get_children()
	for i in range(min(equip_left_data.size(), equip_left_slots.size())):
		if equip_left_data[i]:
			var item = _deserialize_item(equip_left_data[i])
			if item:
				equip_left_slots[i].set_new_data(item)

	# Load right equipment
	var equip_right_data = data.get("equip_right", [])
	var equip_right_slots = inventory.equip_right.get_children()
	for i in range(min(equip_right_data.size(), equip_right_slots.size())):
		if equip_right_data[i]:
			var item = _deserialize_item(equip_right_data[i])
			if item:
				equip_right_slots[i].set_new_data(item)

	# Refresh player stats after loading equipment
	inventory._refresh_player_stats()

func _deserialize_item(item_data: Dictionary) -> Item:
	var resource_path = item_data.get("resource_path", "")

	if resource_path.is_empty():
		return null

	var item = load(resource_path)

	if not item:
		push_error("Failed to load item resource: " + resource_path)
		return null

	# Create a duplicate to avoid modifying the original resource
	item = item.duplicate(true)
	item.stack_size = item_data.get("stack_size", 1)
	item.inv_slot = item_data.get("inv_slot", "")
	item.inv_position = item_data.get("inv_position", -1)

	return item

func _apply_game_stats_data(data: Dictionary) -> void:
	if data.is_empty():
		return

	GameStats.live_enemies = data.get("live_enemies", 0)
	GameStats.stats_updated.emit(GameStats.get_current_stats())
