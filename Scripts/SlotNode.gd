extends TextureRect

@export var item_resource: Item

func set_new_data(resource: Item) -> void:
	item_resource = resource
	
	if item_resource != null:
		texture = item_resource.icon
		item_resource.inv_slot = get_parent().name
		item_resource.inv_position = int(name.split("Slot")[1])
	else:
		texture = null

func _on_gui_input(event: InputEvent) -> void:
	if (event is InputEventMouseButton && event.pressed && event.double_click && event.button_index == 1):
		_use_item_effect()

func _use_item_effect() -> void:
	if !item_resource: return
	
	var item_use_effect = item_resource.use_effect
	
	if item_use_effect:
		print(item_use_effect + " " + item_resource.name)
		delete_resource()
	else:
		print("Trying to use " + item_resource.name)

func delete_resource() -> void:
	texture = null
	item_resource = null

func get_slot_name():
	var parent_name = get_parent().name
	var slot_number = name.split("Slot")[1]
	
	return parent_name + slot_number
