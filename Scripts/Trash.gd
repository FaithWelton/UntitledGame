extends MarginContainer

@onready var trash = $TextureRect

func _process(delta: float) -> void:
	if is_mouse_over_trash():
		trash.texture = load("res://Assets/Inventory/trash-open.png")
	else:
		trash.texture = load("res://Assets/Inventory/trash.png")

func is_mouse_over_trash():
	var position = get_global_mouse_position()
	return trash.get_global_rect().has_point(position)
