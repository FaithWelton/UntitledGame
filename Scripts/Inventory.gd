extends Control

@onready var backpack = $TextureRect/Backpack
@onready var toolbar = $TextureRect/Toolbar
@onready var equip_left = $TextureRect/EquipLeft
@onready var equip_right = $TextureRect/EquipRight

var inv_dictionary = {}
var items = ["res://Resources/potion_health.tres"]

func _ready() -> void:
	inv_dictionary = {
		"Backpack": backpack,
		"Toolbar": toolbar,
		"EquipLeft": equip_left,
		"EquipRight": equip_right,
	}
	
	_refresh_ui()

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
	if drag_slot_node == null || drag_slot_node.texture == null:
		return

	var drag_preview_node = drag_slot_node.duplicate()
	drag_preview_node.custom_minimum_size = Vector2(60, 60)
	set_drag_preview(drag_preview_node)

	return drag_slot_node

func _can_drop_data(at_position: Vector2, data: Variant) -> bool:
	var target_slot_node = get_slot_node_at_position(at_position)
	return target_slot_node != null

func _drop_data(at_position: Vector2, drag_slot_node: Variant) -> void:
	var target_slot_node = get_slot_node_at_position(at_position)
	var target_texture = target_slot_node.texture
	var target_resource = target_slot_node.item_resource
	
	target_slot_node.set_new_data(drag_slot_node.item_resource)
	drag_slot_node.set_new_data(target_resource)

func get_slot_node_at_position(position: Vector2):
	var all_slot_nodes = (
		backpack.get_children()
		+ toolbar.get_children()
		+ equip_left.get_children()
		+ equip_right.get_children()
	)

	for node in all_slot_nodes:
		var nodeRect = node.get_global_rect()
		if nodeRect.has_point(position): return node

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
