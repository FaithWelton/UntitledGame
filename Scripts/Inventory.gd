extends Control

signal drop_out
# TODO: Make item dropped outside of inventory appear on ground

@onready var inventory = self
@onready var player = get_node("../../Player")

@onready var backpack = $TextureRect/Backpack
@onready var toolbar = $TextureRect/Toolbar
@onready var equip_left = $TextureRect/EquipLeft
@onready var equip_right = $TextureRect/EquipRight
@onready var trash = $Trash

@onready var health_label: Label = $PlayerStatsLabel/Health
@onready var strength_label: Label = $PlayerStatsLabel/Strength
@onready var armor_label: Label = $PlayerStatsLabel/Armor

var inv_dictionary = {}
var items = [
	"res://Resources/potion_health.tres",
	"res://Resources/armor_shield.tres",
	"res://Resources/weapon_sword.tres"
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

func _physics_process(delta):
	if Input.is_action_just_pressed("toggle_inventory"): toggle_inventory()

func toggle_inventory():
	inventory.visible = !inventory.visible
	get_tree().paused = inventory.visible # Pause Player and Camera Movement
	Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

func add_item(item: Item):
	item.inv_slot = "backpack"
	item.inv_position = _get_next_empty_bag_slot()

func _get_next_empty_bag_slot():
	for slot in inv_dictionary["backpack"].get_children():
		if slot.texture == null:
			var slot_number = int(slot.name.split("Slot")[1])
			return slot_number

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
		drop_out.emit(drag_slot_node.item_resource, at_position)
		drag_slot_node.delete_resource()
	else:
		var target_slot_node = get_slot_node_at_position(at_position)
		var target_texture = target_slot_node.texture
		var target_resource = target_slot_node.item_resource

		target_slot_node.set_new_data(drag_slot_node.item_resource)
		drag_slot_node.set_new_data(target_resource)
	
	_refresh_player_stats()

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

func get_slot_node_at_position(position: Vector2):
	var all_slot_nodes = (
		backpack.get_children()
		+ toolbar.get_children()
		+ equip_left.get_children()
		+ equip_right.get_children()
	)
	
	for node in all_slot_nodes:
		var nodeRect = node.get_global_rect()
		if nodeRect.has_point(position):
			return node

func _on_trash(position: Vector2) -> bool:
	return trash.get_global_rect().has_point(position)

func _refresh_ui():
	for item in items:
		item = load(item)
		
		var inv_slot = item["inv_slot"]
		var inv_position = item["inv_position"]
		var icon = item["icon"]
		
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
