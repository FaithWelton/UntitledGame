extends MarginContainer

@onready var poof_particles = $TrashArea/SmokePoof
@onready var swirl = $Swirl

func activate_poof() -> void:
	poof_particles.emitting = true

func activate_swirl() -> void:
	swirl.emitting = true

func deactivate_swirl() -> void:
	swirl.emitting = false
