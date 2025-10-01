extends Node

var items

func _ready() -> void:
	items = read_JSON("res://Assets/Json/items.json")
	for key in items.keys():
		items[key]["key"] = key

func read_JSON(path: String):
	if not FileAccess.file_exists(path):
		push_error("JSON file not found: " + path)
		return {}
	
	var file = FileAccess.open(path, FileAccess.READ)
	if not file:
		push_error("Failed to open JSON file: " + path)
		return {}
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var parse_result = json.parse(content)
	if parse_result != OK:
		push_error("Failed to parse JSON: " + path + " - Error: " + str(parse_result))
		return {}
	
	return json.data

func get_item_by_key(key):
	if not items:
		push_error("Items not loaded")
		return null
	
	if items.has(key):
		return items[key].duplicate(true)
	else:
		push_warning("Item key not found: " + str(key))
		return null

func create_3d_item_node(item_resource: Item, spawn_position: Vector3) -> Node3D:
	var scene_path = "res://Items/" + item_resource.name.to_lower() + ".tscn"
	if not FileAccess.file_exists(scene_path):
		push_warning(item_resource.name + " scene file not found! Loading Generic")
		return create_generic_item(item_resource, spawn_position)

	var scene = load(scene_path)
	var scene_instance = scene.instantiate()
	scene_instance.set_name(item_resource.name)
	scene_instance.position = spawn_position

	return scene_instance

func create_generic_item(item_resource: Item, spawn_position: Vector3) -> Node3D:
	var scene_path = "res://Items/generic_item.tscn"
	if not FileAccess.file_exists(scene_path):
		push_error("Generic item scene not found: " + scene_path)
		return null
	
	var scene = load(scene_path)
	if not scene:
		push_error("Failed to load generic item scene")
		return null
		
	var scene_instance = scene.instantiate()
	scene_instance.set_name(item_resource.name)
	scene_instance.resource = item_resource.resource_path
	scene_instance.position = spawn_position
		
	var texture = item_resource.icon
	if not texture:
		push_warning("Item has no icon: " + item_resource.name)
		return scene_instance
	
	var new_material = StandardMaterial3D.new()
	new_material.albedo_texture = texture
	
	var mesh_instance = scene_instance.get_node("MeshInstance3D")
	if mesh_instance:
		mesh_instance.material_override = new_material
	else:
		push_error("MeshInstance3D not found in generic item scene")
	
	return scene_instance
