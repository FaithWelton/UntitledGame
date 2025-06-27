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
