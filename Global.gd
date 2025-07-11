extends Node

var items

func _ready() -> void:
	items = read_JSON("res://Assets/Json/items.json")
	for key in items.keys():
		items[key]["key"] = key

func read_JSON(path: String):
	var file = FileAccess.open(path, FileAccess.READ)
	var content = file.get_as_text()
	var data = JSON.parse_string(content)
	return data

func get_item_by_key(key):
	if items and items.has(key):
		return items[key].duplicate(true)

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
	if mesh_instance: mesh_instance.material_override = new_material
	else: print_rich("[color=red][b]ERROR:[/b] MeshInstance3D not found in scene[/color]")
	
	return scene_instance
