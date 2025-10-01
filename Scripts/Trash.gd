extends MarginContainer

@onready var poof_particles: GPUParticles2D = $TrashArea/SmokePoof
@onready var swirl_particles: GPUParticles2D = $Swirl

func activate_poof() -> void:
	if poof_particles:
		poof_particles.emitting = true

func activate_swirl() -> void:
	if swirl_particles:
		swirl_particles.emitting = true

func deactivate_swirl() -> void:
	if swirl_particles:
		swirl_particles.emitting = false
