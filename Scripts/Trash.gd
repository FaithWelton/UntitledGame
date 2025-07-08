extends MarginContainer

@onready var trash = $TextureRect

@onready var texture_open = load("res://Assets/Inventory/trash-open.png")
@onready var texture_closed = load("res://Assets/Inventory/trash.png")

func _process(_delta: float) -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	
	if is_mouse_over_trash(): trash.texture = texture_open
	else: trash.texture = texture_closed

func is_mouse_over_trash() -> bool:
	var mouse_position = get_global_mouse_position()
	return trash.get_global_rect().has_point(mouse_position)
