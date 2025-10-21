extends Control
class_name Inventory

const SPAWN_DISTANCE: float = 2.0
const RANDOM_OFFSET_RANGE: float = 0.5

@onready var inventory_panel: TextureRect = $TextureRect
@onready var backpack: GridContainer = $TextureRect/Backpack
@onready var toolbar: GridContainer = $TextureRect/Toolbar
@onready var equip_left: GridContainer = $TextureRect/EquipLeft
@onready var equip_right: GridContainer = $TextureRect/EquipRight
@onready var trash: MarginContainer = $Trash

@onready var health_label: Label = $PlayerStatsLabel/Health
@onready var ui_health_label: Label = $"../Stats/Health"
@onready var strength_label: Label = $PlayerStatsLabel/Strength
@onready var armor_label: Label = $PlayerStatsLabel/Armor

var player: Node3D
var world_node: Node3D

var inventory_sections: Dictionary = {}
var currently_dragging_slot: Node = null
var starting_items: Array[Dictionary] = [
	{
		"name": "potion_health",
		"display_name": "Health Potion",
		"path": "res://Items/Resources/potion_health.tres",
		"position": "Toolbar",
	},
	{
		"name": "potion_health_2",
		"display_name": "Health Potion",
		"path": "res://Items/Resources/potion_health.tres",
		"position": "Toolbar",
	},
	{
		"name": "potion_revive",
		"display_name": "Revive Potion",
		"path": "res://Items/Resources/potion_revive.tres",
		"position": "Toolbar",
	},
	{
		"name": "armor_shield",
		"display_name": "Shield",
		"path": "res://Items/Resources/armor_shield.tres",
		"position": "Backpack",
	},
	{
		"name": "weapon_sword",
		"display_name": "Sword",
		"path": "res://Items/Resources/weapon_sword.tres",
		"position": "Backpack",
	},
]

var is_inventory_open: bool = false
var on_inventory: bool = false

func _ready() -> void:
	add_to_group("inventory")

	# Allow inventory to process even when game is paused
	process_mode = Node.PROCESS_MODE_ALWAYS

	_find_player()
	_find_world_node()
	_initialize_inventory_sections()
	_connect_slot_signals()
	_add_starting_items()
	_refresh_player_stats()

	PlayerStats.health_changed.connect(_on_player_health_changed)

func _connect_slot_signals() -> void:
	var all_slots = _get_all_inventory_slots()
	for slot in all_slots:
		if slot.has_signal("item_used"):
			slot.item_used.connect(_on_item_used)

func _find_player() -> void:
	var players = get_tree().get_nodes_in_group("player")

	if players.is_empty():
		return

	player = players[0]

func _ensure_player_found() -> bool:
	if player:
		return true

	_find_player()
	return player != null

func _find_world_node() -> void:
	var worlds = get_tree().get_nodes_in_group("world")

	if worlds.is_empty():
		push_error("No world node found! Make sure the world/level node is in the 'world' group")
		return

	world_node = worlds[0]

func _initialize_inventory_sections() -> void:
	inventory_sections = {
		"Backpack": backpack,
		"Toolbar": toolbar,
		"EquipLeft": equip_left,
		"EquipRight": equip_right,
	}

func _add_starting_items() -> void:
	for item_data in starting_items:
		var resource = load(item_data["path"])
		if resource and resource is Item:
			add_item(resource, item_data["position"])
		else:
			push_error("Failed to load starting item: " + item_data["display_name"])
	
func _notification(what: int) -> void:
	# NOTIFICATION_DRAG_END is called when drag ends without a successful drop
	if what == NOTIFICATION_DRAG_END:
		if currently_dragging_slot:
			var mouse_pos = get_global_mouse_position()
			var is_over_inventory_panel = inventory_panel.get_global_rect().has_point(mouse_pos)

			if not is_over_inventory_panel:
				_handle_world_drop(currently_dragging_slot)

			currently_dragging_slot = null

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_inventory"):
		toggle_inventory()

func toggle_inventory() -> void:
	visible = not visible
	is_inventory_open = visible

	_set_game_paused(is_inventory_open)
	_set_mouse_mode(is_inventory_open)

func _set_game_paused(paused: bool) -> void:
	# Use Godot's built-in pause system
	get_tree().paused = paused

func _set_mouse_mode(show_cursor: bool) -> void:
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE if show_cursor else Input.MOUSE_MODE_CAPTURED

func add_item(item: Item, preferred_slot: String = "Backpack") -> bool:
	if not _validate_item(item):
		return false

	# Always duplicate the item to avoid shared resources
	var item_copy = item.duplicate(true)

	# Try to stack with existing items first
	if item_copy.is_stackable():
		var stacked_slot = _try_stack_item(item_copy, preferred_slot)
		if stacked_slot:
			_refresh_player_stats()
			return true

	# If can't stack, find empty slot
	var slot_node = _get_next_empty_slot_node(preferred_slot)
	if not slot_node:
		push_error("No empty slots in " + preferred_slot)
		return false

	# Initialize stack size if not set
	if item_copy.stack_size <= 0:
		item_copy.stack_size = 1

	slot_node.set_new_data(item_copy)
	_refresh_player_stats()

	return true

func _try_stack_item(item: Item, preferred_slot: String) -> SlotNode:
	if not item.is_stackable():
		return null

	var section = inventory_sections.get(preferred_slot)
	if not section:
		return null

	# Look for existing stacks of this item
	for slot in section.get_children():
		if not slot.item_resource:
			continue

		if slot.item_resource.can_stack_with(item) and not slot.item_resource.is_stack_full():
			var remaining = slot.item_resource.add_to_stack(item.stack_size)
			slot._update_stack_display()

			# If we couldn't add everything, keep trying other slots
			if remaining > 0:
				item.stack_size = remaining
				continue

			return slot

	return null

func _validate_item(item: Resource) -> bool:
	if not item:
		push_error("Cannot add null item")
		return false
	
	if not item is Item:
		push_error("Resource is not an Item: " + str(item.get_class()))
		return false
	
	return true

func _get_next_empty_slot_node(slot_type: String = "Backpack") -> Node:
	if not slot_type in inventory_sections:
		push_error("Invalid slot type: " + slot_type)
		return null
	
	var section = inventory_sections[slot_type]
	for slot in section.get_children():
		if slot.texture == null:
			return slot
	
	return null

func _refresh_player_stats() -> void:
	var equipment_bonuses = _calculate_equipment_bonuses()
	PlayerStats.update_equipment_stats(equipment_bonuses)
	_update_stat_labels()

func _calculate_equipment_bonuses() -> Dictionary:
	var bonuses = {
		"health": 0,
		"strength": 0,
		"armor": 0,
		"crit_chance": 0.0,
		"crit_multiplier": 0.0
	}
	var equipment_slots = equip_left.get_children() + equip_right.get_children()

	for slot in equipment_slots:
		var item = slot.item_resource
		if not item:
			continue

		bonuses.health += item.health
		bonuses.strength += item.strength
		bonuses.armor += item.armor
		bonuses.crit_chance += item.crit_chance
		bonuses.crit_multiplier += item.crit_multiplier

	return bonuses

func _update_stat_labels() -> void:
	if health_label:
		health_label.text = "Health: %d/%d" % [PlayerStats.health, PlayerStats.max_health]
	if ui_health_label:
		ui_health_label.text = "Player Health: %d/%d" % [PlayerStats.health, PlayerStats.max_health]
	if strength_label:
		strength_label.text = "Strength: %d" % PlayerStats.strength
	if armor_label:
		armor_label.text = "Armor: %d" % PlayerStats.armor

func remove_item(item_slot_node: Node) -> bool:
	if not item_slot_node or not item_slot_node.item_resource:
		push_error("Cannot remove invalid item")
		return false

	item_slot_node.delete_resource()
	_refresh_player_stats()
	return true

func clear_inventory() -> void:
	# Clear all backpack slots
	for slot in backpack.get_children():
		if slot.item_resource:
			slot.delete_resource()

	# Clear all left equipment slots
	for slot in equip_left.get_children():
		if slot.item_resource:
			slot.delete_resource()

	# Clear all right equipment slots
	for slot in equip_right.get_children():
		if slot.item_resource:
			slot.delete_resource()

	_refresh_player_stats()

func _get_drag_data(at_position: Vector2) -> Variant:
	var drag_slot_node = get_slot_node_at_position(at_position)

	if not drag_slot_node or not drag_slot_node.texture:
		currently_dragging_slot = null
		return null

	# Check for shift key to split stack
	if Input.is_key_pressed(KEY_SHIFT) and drag_slot_node.item_resource and drag_slot_node.item_resource.is_stackable() and drag_slot_node.item_resource.stack_size > 1:
		_show_stack_split_dialog(drag_slot_node)
		return null

	var drag_preview_node = drag_slot_node.duplicate()
	drag_preview_node.custom_minimum_size = Vector2(60, 60)
	set_drag_preview(drag_preview_node)

	currently_dragging_slot = drag_slot_node
	return drag_slot_node

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	if not data:
		return false

	var target_slot_node = get_slot_node_at_position(at_position)
	var drag_item = data.item_resource
	var is_over_trash = _is_over_trash(at_position)
	var is_over_inventory_panel = inventory_panel.get_global_rect().has_point(at_position)

	if is_over_trash:
		trash.activate_swirl()
	else:
		trash.deactivate_swirl()

	# Allow dropping on trash
	if is_over_trash:
		return true

	# Allow dropping outside inventory panel (to world)
	if not is_over_inventory_panel:
		return true

	# If no target slot, deny drop (item inside inventory but not on a slot)
	if not target_slot_node:
		return false

	# Validate slot compatibility
	return _can_item_go_in_slot(drag_item, target_slot_node) and _can_swap_items(data, target_slot_node)

func _can_item_go_in_slot(item: Item, slot_node: Node) -> bool:
	if not item or not slot_node:
		return false
	
	return _is_item_allowed_in_slot(item, slot_node)

func _can_swap_items(drag_slot: Node, target_slot: Node) -> bool:
	if not target_slot.item_resource:
		return true
	
	return _is_item_allowed_in_slot(target_slot.item_resource, drag_slot)

func _drop_data(at_position: Vector2, drag_slot_node: Variant) -> void:
	var is_over_trash = _is_over_trash(at_position)
	var target_slot_node = get_slot_node_at_position(at_position)
	var is_over_inventory_panel = inventory_panel.get_global_rect().has_point(at_position)

	if is_over_trash:
		# Drop on trash - delete item
		_handle_trash_drop(drag_slot_node)
	elif target_slot_node:
		# Drop on valid inventory slot - swap/move items
		_handle_slot_drop(at_position, drag_slot_node)
	elif not is_over_inventory_panel:
		# Drop outside inventory panel - drop to world
		_handle_world_drop(drag_slot_node)
	# else: Drop on empty area inside inventory - do nothing (item returns to original slot)

	currently_dragging_slot = null
	_refresh_player_stats()

func _handle_trash_drop(drag_slot_node: Node) -> void:
	trash.activate_poof()
	remove_item(drag_slot_node)
	trash.deactivate_swirl()

func _handle_world_drop(drag_slot_node: Node) -> void:
	var item = drag_slot_node.item_resource
	if not item:
		return

	# Spawn items based on stack size
	var stack_size = item.stack_size if item.is_stackable() else 1

	for i in range(stack_size):
		# Create a single item (stack_size = 1) for each drop
		var single_item = item.duplicate(true)
		single_item.stack_size = 1

		if not _spawn_3d_item(single_item):
			push_error("Failed to spawn item %d of %d" % [i + 1, stack_size])
			break

	# Remove the entire stack from inventory
	remove_item(drag_slot_node)

func _handle_slot_drop(at_position: Vector2, drag_slot_node: Node) -> void:
	var target_slot_node = get_slot_node_at_position(at_position)
	if not target_slot_node:
		return

	var target_item = target_slot_node.item_resource
	var drag_item = drag_slot_node.item_resource

	# Check if we should try to stack
	var should_stack = (drag_item and target_item
		and drag_item.can_stack_with(target_item)
		and not drag_item == target_item
		and not target_item.is_stack_full())

	if should_stack:
		var amount_to_add = drag_item.stack_size
		var space_available = target_item.max_stack_size - target_item.stack_size
		var amount_actually_added = min(amount_to_add, space_available)

		# Add to target stack
		target_item.stack_size += amount_actually_added
		target_slot_node._update_stack_display()

		# Update source stack
		var remaining = amount_to_add - amount_actually_added
		if remaining == 0:
			# All items stacked, clear source slot
			drag_slot_node.delete_resource()
		else:
			# Partial stack, update source slot with remaining
			drag_item.stack_size = remaining
			drag_slot_node._update_stack_display()
	else:
		# Normal swap - need to duplicate to avoid shared resources
		var drag_item_copy = drag_item.duplicate(true) if drag_item else null
		var target_item_copy = target_item.duplicate(true) if target_item else null

		target_slot_node.set_new_data(drag_item_copy)
		drag_slot_node.set_new_data(target_item_copy)

func _show_stack_split_dialog(source_slot: Node) -> void:
	var item = source_slot.item_resource
	if not item:
		return

	var dialog = AcceptDialog.new()
	dialog.title = "Split Stack"
	dialog.dialog_text = ""  # Clear default text to avoid overlap

	var vbox = VBoxContainer.new()
	vbox.add_theme_constant_override("separation", 10)

	var title_label = Label.new()
	title_label.text = "How many %s to take?" % item.name
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	var stack_label = Label.new()
	stack_label.text = "Current stack: %d" % item.stack_size
	stack_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	stack_label.add_theme_color_override("font_color", Color(0.7, 0.7, 0.7))

	vbox.add_child(title_label)
	vbox.add_child(stack_label)

	var slider = HSlider.new()
	slider.min_value = 1
	slider.max_value = item.stack_size - 1
	slider.value = floor(item.stack_size / 2.0)
	slider.step = 1
	slider.custom_minimum_size = Vector2(300, 0)

	var amount_label = Label.new()
	amount_label.text = "Amount: %d" % slider.value
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	slider.value_changed.connect(func(value):
		amount_label.text = "Amount: %d" % int(value)
	)

	vbox.add_child(amount_label)
	vbox.add_child(slider)

	dialog.add_child(vbox)
	add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(func():
		_split_stack(source_slot, int(slider.value))
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)

func _split_stack(source_slot: Node, amount: int) -> void:
	var source_item = source_slot.item_resource
	if not source_item or amount <= 0 or amount >= source_item.stack_size:
		return

	# Find empty slot in same section as source
	var section_name = _get_slot_section_name(source_slot)
	var empty_slot = _get_next_empty_slot_node(section_name)

	if not empty_slot:
		push_warning("No empty slot to split stack into")
		return

	# Create duplicate item for new stack
	var new_item = source_item.duplicate(true)
	new_item.stack_size = amount

	# Reduce source stack
	source_item.stack_size -= amount

	# Update displays
	source_slot._update_stack_display()
	empty_slot.set_new_data(new_item)

func _get_slot_section_name(slot: Node) -> String:
	# Find which section this slot belongs to
	if slot.get_parent() == backpack:
		return "Backpack"
	elif slot.get_parent() == equip_left:
		return "EquipLeft"
	elif slot.get_parent() == equip_right:
		return "EquipRight"
	return "Backpack"

func _spawn_3d_item(item_resource: Item) -> bool:
	if not item_resource:
		push_error("Cannot spawn null item")
		return false

	if not _ensure_player_found():
		push_error("Player not found! Cannot calculate spawn position")
		return false

	if not world_node:
		push_error("World node not found!")
		return false

	var spawn_position = _calculate_spawn_position()
	var item_3D = Global.create_3d_item_node(item_resource, spawn_position)
	
	if not item_3D:
		push_error("Failed to create 3D Item Node: " + item_resource.name)
		return false
	
	world_node.add_child(item_3D)
	print("Spawned 3D Item: %s at %s" % [item_resource.name, spawn_position])
	return true

func _calculate_spawn_position() -> Vector3:
	var base_position = player.global_position + player.global_basis.z * -SPAWN_DISTANCE
	var random_offset = Vector3(
		randf_range(-RANDOM_OFFSET_RANGE, RANDOM_OFFSET_RANGE),
		randf_range(0, RANDOM_OFFSET_RANGE),
		randf_range(-RANDOM_OFFSET_RANGE, RANDOM_OFFSET_RANGE)
	)
	
	return base_position + random_offset

func get_slot_node_at_position(at_position: Vector2) -> Variant:
	var all_slots = _get_all_inventory_slots()

	for slot in all_slots:
		if slot.get_global_rect().has_point(at_position):
			return slot

	return null

func _get_all_inventory_slots() -> Array[Node]:
	var all_slots: Array[Node] = []
	
	for section in inventory_sections.values():
		all_slots.append_array(section.get_children())
	
	return all_slots

func _is_over_trash(at_position: Vector2) -> bool:
	return trash.get_global_rect().has_point(at_position)

func _is_item_allowed_in_slot(item: Item, slot_node: Node) -> bool:
	if not item or not slot_node:
		return false

	var slot_name = slot_node.get_slot_name()
	var item_type = item.get_type_string()

	if not "Equip" in slot_name:
		return true

	var allowed_combinations = {
		"EquipLeft1": ["Weapon"],
		"EquipLeft2": ["Armor"],
		"EquipLeft3": ["Armor"],

		"EquipRight1": ["Ring"],
		"EquipRight2": ["Ring"],
		"EquipRight3": ["Shoe"],
	}

	if slot_name in allowed_combinations:
		return item_type in allowed_combinations[slot_name]

	return false

func has_item_with_effect(effect_name: String) -> bool:
	var all_slots = _get_all_inventory_slots()
	
	for slot in all_slots:
		if slot.item_resource and slot.item_resource.use_effect == effect_name:
			return true
	
	return false

func use_revive_item() -> bool:
	var all_slots = _get_all_inventory_slots()

	for slot in all_slots:
		if slot.item_resource and slot.item_resource.use_effect == "revive":
			print("Using revive item: " + slot.item_resource.name)
			slot.delete_resource()
			_refresh_player_stats()
			return true

	return false

func _on_item_used(item: Item, slot: SlotNode) -> void:
	if not item:
		return

	var effect = item.use_effect

	# Handle different item effects
	match effect:
		"revive":
			_handle_revive_item(item, slot)
		"drink":
			_handle_drink_item(item, slot)
		_:
			# Generic consumable - just consume it if it's useable
			if item.type == Item.ItemType.USEABLE and not effect.is_empty():
				slot.decrement_stack()
				_refresh_player_stats()

func _handle_revive_item(item: Item, slot: SlotNode) -> void:
	if PlayerStats.dead:
		PlayerStats.revive()
		slot.decrement_stack()
		_refresh_player_stats()
		print("Player revived using: " + item.name)
	else:
		push_warning("Cannot use revive item - player is not dead!")

func _handle_drink_item(item: Item, slot: SlotNode) -> void:
	if item.health > 0:
		PlayerStats.increment_health(item.health)
		slot.decrement_stack()
		_refresh_player_stats()
		print("Player drank: " + item.name + " (+%d health)" % item.health)
func _on_player_health_changed(new_health: int) -> void:
	if ui_health_label:
		ui_health_label.text = "Player Health: %d/%d" % [new_health, PlayerStats.max_health]
