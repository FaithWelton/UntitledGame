extends RigidBody3D

@export var resource: String = ""

@onready var label: Label3D = $Label3D
@onready var mesh_instance: MeshInstance3D = $MeshInstance3D
var selected = false

func _ready() -> void:
	add_to_group("object")
	if label:
		label.hide()
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		label.top_level = true

func set_selection(boolean: bool) -> void:
	selected = boolean
	if label: label.visible = boolean

func _process(_delta: float) -> void:
	if label and label.visible:
		label.global_position = global_position + Vector3(0, 0.75, 0)
