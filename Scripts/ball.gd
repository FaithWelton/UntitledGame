extends RigidBody3D

@export var resource: String = "res://Resources/ball.tres"

@onready var label: Label3D = $Label3D

var selected = false

func _ready() -> void:
	add_to_group("object")
	label.hide()
	label.top_level = true

func set_selection(boolean: bool) -> void:
	selected = boolean
	label.visible = boolean

func _process(_delta: float) -> void:
	label.global_position = global_position + Vector3(0, 0.75, 0)
