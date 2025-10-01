extends Node3D

@onready var animation_tree: AnimationTree = %AnimationTree
@onready var bat_mesh: MeshInstance3D = %bat

func hurt() -> void:
	if not animation_tree:
		push_error("AnimationTree not found on BatModel")
		return

	animation_tree.set("parameters/OneShot/request", true)
