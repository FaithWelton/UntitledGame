extends RigidBody3D

@export var item_name: String = "Ball"
@export_multiline var description: String = "It bounces."
@export var icon: CompressedTexture2D = load("res://Assets/Items/ball.png")
@export var use_effect: String = ""
@export_enum("Weapon", "Armor", "Useable", "Interactable") var type: String = "Interactable"

@export var resource = "res://Resources/ball.tres"

@onready var label: Label3D = $Label3D

var selected = false

func _ready() -> void:
	add_to_group("object")
	label.hide()
	label.top_level = true

func set_selection(boolean: bool) -> void:
	selected = boolean
	label.visible = boolean

func _process(delta: float) -> void:
	label.global_position = global_position + Vector3(0, 0.75, 0)
