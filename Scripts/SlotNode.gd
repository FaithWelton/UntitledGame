extends TextureRect
class_name SlotNode

signal item_used(item: Item, slot: SlotNode)

@export var item_resource: Item

@onready var stack_label: Label = $StackLabel

var tooltip: ItemTooltip

func _ready() -> void:
	if stack_label:
		stack_label.hide()

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

func _on_mouse_entered() -> void:
	if not item_resource:
		return

	_find_tooltip()
	if tooltip:
		tooltip.show_tooltip(item_resource, get_global_mouse_position())

func _on_mouse_exited() -> void:
	if tooltip:
		tooltip.hide_tooltip()

func _find_tooltip() -> void:
	if tooltip:
		return

	# Look for tooltip in the scene tree
	var tooltips = get_tree().get_nodes_in_group("item_tooltip")
	if not tooltips.is_empty():
		tooltip = tooltips[0]

func set_new_data(resource: Item) -> void:
	item_resource = resource

	if item_resource:
		texture = item_resource.icon
		_update_item_inventory_data()
		_update_stack_display()
	else:
		texture = null
		if stack_label:
			stack_label.hide()

func _update_stack_display() -> void:
	if not item_resource or not stack_label:
		return

	if item_resource.is_stackable() and item_resource.stack_size > 1:
		stack_label.text = str(item_resource.stack_size)
		stack_label.show()
	else:
		stack_label.hide()

func _update_item_inventory_data() -> void:
	if not item_resource:
		return
	
	var parent = get_parent()
	if not parent:
		push_warning("SlotNode has no parent")
		return
	
	item_resource.inv_slot = parent.name
	
	var slot_number = _get_slot_number()
	if slot_number >= 0:
		item_resource.inv_position = slot_number

func _get_slot_number() -> int:
	var parts = name.split("Slot")
	if parts.size() >= 2:
		return int(parts[1])
	
	return -1
	
func _on_gui_input(event: InputEvent) -> void:
	if _is_double_click(event):
		_use_item()

func _is_double_click(event: InputEvent) -> bool:
	return (event is InputEventMouseButton
		and event.pressed
		and event.double_click
		and event.button_index == MOUSE_BUTTON_LEFT)

func _use_item() -> void:
	if not item_resource:
		return

	# Emit signal - let the inventory or game manager handle the actual effect
	item_used.emit(item_resource, self)

func delete_resource() -> void:
	texture = null
	item_resource = null
	if stack_label:
		stack_label.hide()

func decrement_stack(amount: int = 1) -> bool:
	if not item_resource:
		return false

	item_resource.remove_from_stack(amount)

	if item_resource.is_stack_empty():
		delete_resource()
		return true

	_update_stack_display()
	return false  # Stack still has items

func get_slot_name() -> String:
	var parent_name = get_parent().name
	var slot_number = name.split("Slot")[1]
	return parent_name + str(slot_number)
