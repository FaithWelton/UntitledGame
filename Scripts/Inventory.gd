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
var starting_items = [
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

	_add_starting_items()
	_refresh_player_stats()

func _add_starting_items():
	# Add health potion to toolbar
	var health_potion = load("res://Resources/potion_health.tres")
	if health_potion:
		add_item(health_potion, "Toolbar")
	else:
		print_rich("[color=red][b]ERROR:[/b] Failed to load health potion[/color]")
	
	# Add shield and sword to backpack
	var shield = load("res://Resources/armor_shield.tres")
	if shield:
		add_item(shield, "Backpack")
	else:
		print_rich("[color=red][b]ERROR:[/b] Failed to load shield[/color]")
	
	var sword = load("res://Resources/weapon_sword.tres")
	if sword:
		add_item(sword, "Backpack")
	else:
		print_rich("[color=red][b]ERROR:[/b] Failed to load sword[/color]")

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

func add_item(item, preferred_slot: String = "Backpack") -> bool:	
	if not item:
		print_rich("[color=red][b]ERROR:[/b] Invalid Item![/color]")
		return false

	if not item is Item:
		print_rich("[color=red][b]ERROR:[/b] Item is not of type 'Item'. Actual type: " + item.get_class() + "[/color]")
		return false

	var next_slot_node = _get_next_empty_slot_node(preferred_slot)
	if next_slot_node == null:
		print_rich("[color=red][b]ERROR:[/b] No empty slots in " + preferred_slot + "![/color]")
		return false

	next_slot_node.set_new_data(item)
	
	_refresh_player_stats()

	var slot_number = int(next_slot_node.name.split("Slot")[1])
	print_rich("[color=green][b]ADD ITEM:[/b][/color] [color=light_green]" + item.name + "[/color] to [color=light_blue]" + preferred_slot + " Slot" + str(slot_number) + "[/color]")
	return true

func _get_next_empty_slot_node(slot_type: String = "Backpack"):
	if slot_type in inv_dictionary:
		for slot in inv_dictionary[slot_type].get_children():
			if slot.texture == null:
				return slot
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
		var spawned = _spawn_3d_item(drag_slot_node.item_resource)
		if spawned: drag_slot_node.delete_resource()
	else:
		var target_slot_node = get_slot_node_at_position(at_position)
		var target_resource = target_slot_node.item_resource

		target_slot_node.set_new_data(drag_slot_node.item_resource)
		drag_slot_node.set_new_data(target_resource)
	
	_refresh_player_stats()

func _spawn_3d_item(item_resource: Item) -> bool:
	var spawn_distance = 2.0
	var spawn_position = player.global_position + player.global_basis.z * -spawn_distance
	
	var random_offset = Vector3(randf_range(-0.5, 0.5), randf_range(0, 0.5), randf_range(-0.5, 0.5))
	spawn_position += random_offset
	
	var item_3d = _create_3d_item_node(item_resource, spawn_position)
	if not item_3d: return false
	
	world_node.add_child(item_3d)
	print_rich("[color=green][b]SPAWNED 3D ITEM:[/b][/color] [color=light_green]" + item_resource.name + "[/color] at position [color=light_blue]" + str(spawn_position) + "[/color]")
	return true

func _create_3d_item_node(item_resource: Item, spawn_position: Vector3) -> Node3D:
	var scene_path = "res://Items/" + item_resource.name.to_lower() + ".tscn"
	if not FileAccess.file_exists(scene_path):
		print_rich("[color=red][b]ERROR:[/b] No scene file found! Loading Generic[/color]")
		return _create_generic_item(item_resource, spawn_position)
	
	var scene = load(scene_path)
	var scene_instance = scene.instantiate()
	scene_instance.set_name(item_resource.name)
	scene_instance.position = spawn_position
	
	return scene_instance

func _create_generic_item(item_resource: Item, spawn_position: Vector3) -> Node3D:
	var scene = load("res://Items/generic_item.tscn")
	
	var scene_instance = scene.instantiate()
	scene_instance.set_name(item_resource.name)
	scene_instance.resource = item_resource.resource_path
	scene_instance.position = spawn_position
		
	var texture = item_resource.icon
	var new_material = StandardMaterial3D.new()
	new_material.albedo_texture = texture
	
	var mesh_instance = scene_instance.get_node("MeshInstance3D")
	if mesh_instance:
		mesh_instance.material_override = new_material
	else:
		print_rich("[color=red][b]ERROR:[/b] MeshInstance3D not found in scene[/color]")
	
	return scene_instance

func _refresh_player_stats():
	var equip_stats = { "health": 0, "strength": 0, "armor": 0, }
	
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
	var all_slot_nodes = (backpack.get_children() + toolbar.get_children() + equip_left.get_children() + equip_right.get_children())

	for node in all_slot_nodes:
		var nodeRect = node.get_global_rect()
		if nodeRect.has_point(node_at_position):
			return node

func _on_trash(at_position: Vector2) -> bool:
	return trash.get_global_rect().has_point(at_position)

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
