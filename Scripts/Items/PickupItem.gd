extends RigidBody3D
class_name PickupItem

const LABEL_HEIGHT_OFFSET: float = 0.75

@export var resource: String = ""

@onready var label: Label3D = $Label3D

var selected: bool = false

func _ready() -> void:
	add_to_group("object")
	_setup_label()

func _setup_label() -> void:
	if not label:
		push_warning("No Label3D found on %s" % get_class())
		return

	label.hide()
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.top_level = true

func set_selection(is_selected: bool) -> void:
	selected = is_selected
	if label:
		label.visible = is_selected

func _process(_delta: float) -> void:
	if label and label.visible and is_instance_valid(label):
		label.global_position = global_position + Vector3(0, LABEL_HEIGHT_OFFSET, 0)
