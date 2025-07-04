extends Control
class_name Inventory

@onready var inventory = self
@onready var player = get_node("../../Player")
@onready var camera = get_node("../../CameraController")

@onready var backpack = $TextureRect/Backpack
@onready var toolbar = $TextureRect/Toolbar
@onready var equip_left = $TextureRect/EquipLeft
@onready var equip_right = $TextureRect/EquipRight
@onready var trash = $Trash

@onready var health_label: Label = $PlayerStatsLabel/Health
@onready var strength_label: Label = $PlayerStatsLabel/Strength
@onready var armor_label: Label = $PlayerStatsLabel/Armor

@onready var world_node = get_node("../..")

var inv_dictionary = {}
var items = [
	"res://Resources/potion_health.tres",
	"res://Resources/armor_shield.tres",
	"res://Resources/weapon_sword.tres",
]
var on_inventory = false

func _ready() -> void:	
	inv_dictionary = {
		"Backpack": backpack,
		"Toolbar": toolbar,
		"EquipLeft": equip_left,
		"EquipRight": equip_right,
	}

	_refresh_ui()
	_refresh_player_stats()

func _process(_delta: float) -> void:
	if Input.is_action_just_pressed("toggle_inventory"): toggle_inventory()

func toggle_inventory():
	inventory.visible = !inventory.visible

	if inventory.visible:
		player.process_mode = Node.PROCESS_MODE_DISABLED
		camera.process_mode = Node.PROCESS_MODE_DISABLED
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
	else:
		player.process_mode = Node.PROCESS_MODE_INHERIT
		camera.process_mode = Node.PROCESS_MODE_INHERIT
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func add_item(item) -> bool:	
	if not item:
		print_rich("[color=red][b]ERROR:[/b] Invalid Item![/color]")
		return false

	if not item is Item:
		print_rich("[color=red][b]ERROR:[/b] Item is not of type 'Item'. Actual type: " + item.get_class() + "[/color]")
		return false

	item.inv_slot = "Backpack"
	var next_slot = _get_next_empty_bag_slot()
	if next_slot == null:
		print_rich("[color=red][b]ERROR:[/b] Inventory full![/color]")
		return false

	item.inv_position = next_slot

	var item_path = item.resource_path	
	if item_path == "":
		print_rich("[color=red][b]ERROR:[/b] Item has no resource path![/color]")
		return false

	items.append(item_path)

	_refresh_ui()
	_refresh_player_stats()

	print_rich("[color=green][b]ADD ITEM:[/b][/color] [color=light_green]" + item.name + "[/color] to [color=light_blue]Inventory Slot" + str(next_slot) + "[/color]")
	return true

func _get_next_empty_bag_slot():
	for slot in inv_dictionary["Backpack"].get_children():
		if slot.texture == null:
			var slot_number = int(slot.name.split("Slot")[1])
			return slot_number
	return null # No empty slots found

func _get_drag_data(at_position: Vector2) -> Variant:
	var drag_slot_node = get_slot_node_at_position(at_position)
	if drag_slot_node == null || drag_slot_node.texture == null: return

	var drag_preview_node = drag_slot_node.duplicate()
	drag_preview_node.custom_minimum_size = Vector2(60, 60)
	set_drag_preview(drag_preview_node)

	return drag_slot_node

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var target_slot_node = get_slot_node_at_position(at_position)
	var drag_item = data.item_resource
	
	var on_trash = _on_trash(at_position)
	var item_allowed = _is_item_allowed(drag_item, target_slot_node)
	
	return (target_slot_node != null && item_allowed) || on_trash || not on_inventory

func _drop_data(at_position: Vector2, drag_slot_node: Variant) -> void:
	var on_trash = _on_trash(at_position)

	if on_trash:
		drag_slot_node.delete_resource()
	elif not on_inventory:
		_spawn_3d_item(drag_slot_node.item_resource)
		drag_slot_node.delete_resource()
	else:
		var target_slot_node = get_slot_node_at_position(at_position)
		var target_resource = target_slot_node.item_resource

		target_slot_node.set_new_data(drag_slot_node.item_resource)
		drag_slot_node.set_new_data(target_resource)
	
	_refresh_player_stats()

func _spawn_3d_item(item_resource: Item) -> void:
	var spawn_distance = 2.0
	var spawn_position = player.global_position + player.global_basis.z * -spawn_distance
	
	var random_offset = Vector3(randf_range(-0.5, 0.5), randf_range(0, 0.5), randf_range(-0.5, 0.5))
	spawn_position += random_offset
	
	var item_3d = _create_3d_item_node(item_resource, spawn_position)
	if item_3d:
		world_node.add_child(item_3d)
		print_rich("[color=green][b]SPAWNED 3D ITEM:[/b][/color] [color=light_green]" + item_resource.name + "[/color] at position [color=light_blue]" + str(spawn_position) + "[/color]")

func _create_3d_item_node(item_resource: Item, spawn_position: Vector3) -> Node3D:
	var scene = load("res://Items/" + item_resource.name.to_lower() + ".tscn")
	var scene_instance = scene.instantiate()
	scene_instance.set_name(item_resource.name)
	
	var item_3d = scene_instance
	item_3d.name = item_resource.name + "_3D"
	item_3d.global_position = spawn_position

	return item_3d

func _refresh_player_stats():
	var equip_stats = {
		"health": 0,
		"strength": 0,
		"armor": 0,
	}
	
	for slot in equip_left.get_children() + equip_right.get_children():
		var item = slot.item_resource
		if not item: continue
		
		equip_stats.health += item.health
		equip_stats.strength += item.strength
		equip_stats.armor += item.armor
	
	PlayerStats.update_equipment_stats(equip_stats)
	
	health_label.set_text("Health: " + str(PlayerStats.health))
	strength_label.set_text("Strength: " + str(PlayerStats.strength))
	armor_label.set_text("Armor: " + str(PlayerStats.armor))

func get_slot_node_at_position(node_at_position: Vector2):
	var all_slot_nodes = (
		backpack.get_children()
		+ toolbar.get_children()
		+ equip_left.get_children()
		+ equip_right.get_children()
	)
	
	for node in all_slot_nodes:
		var nodeRect = node.get_global_rect()
		if nodeRect.has_point(node_at_position):
			return node

func _on_trash(at_position: Vector2) -> bool:
	return trash.get_global_rect().has_point(at_position)

func _refresh_ui():
	for item in items:
		item = load(item)
	
		var inv_slot = item["inv_slot"]
		var inv_position = item["inv_position"]
				
		for slot in inv_dictionary[inv_slot].get_children():
			var slot_number = int(slot.name.split("Slot")[1])
			
			if slot_number == inv_position:
				slot.set_new_data(item)

func _is_item_allowed(item, slot_node):
	if slot_node == null: return
	
	var slot_name = slot_node.get_slot_name()
	var item_type = item.type
	
	var is_equipment_slot = "Equip" in slot_name
	if not is_equipment_slot: return true
	
	var access_left_1 = slot_name == "EquipLeft1" && item_type == "Weapon"
	var access_left_2 = slot_name == "EquipLeft2" && item_type == "Armor"
	var access_left_3 = slot_name == "EquipLeft3" && item_type == "Armor"
	
	var access_right_1 = slot_name == "EquipRight1" && item_type == "Ring"
	var access_right_2 = slot_name == "EquipRight2" && item_type == "Ring"
	var access_right_3 = slot_name == "EquipRight3" && item_type == "Shoe"
	
	if access_left_1 || access_left_2 || access_left_3 || access_right_1 || access_right_2 || access_right_3:
		return true
	else:
		return false

func _on_texture_rect_mouse_entered() -> void:
	on_inventory = true

func _on_texture_rect_mouse_exited() -> void:
	on_inventory = false
