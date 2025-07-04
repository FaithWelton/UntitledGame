extends MarginContainer

@onready var trash = $TextureRect

func _process(_delta: float) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if is_mouse_over_trash():
		trash.texture = load("res://Assets/Inventory/trash-open.png")
	else:
		trash.texture = load("res://Assets/Inventory/trash.png")

func is_mouse_over_trash():
	var mouse_position = get_global_mouse_position()
	return trash.get_global_rect().has_point(mouse_position)
