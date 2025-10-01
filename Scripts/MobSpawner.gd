extends Node3D

@export var mob_to_spawn: PackedScene = null
@export var pause: bool = false

@onready var marker: Marker3D = %Marker3D
@onready var timer: Timer = %Timer

var ai_types = ["aggressive", "hit_and_run", "coward"]

func _ready() -> void:
	if not mob_to_spawn:
		push_error("No Mob Scene assigned to MobSpawner")
		return
	
	if not marker:
		push_error("No Marker3D found on MobSpawner")

func _on_timer_timeout() -> void:
	if not mob_to_spawn or pause:
		return
		
	var mob = mob_to_spawn.instantiate()
	if not mob:
		push_error("Failed to instantiate Mob")
		return
	
	if not mob.has_method("attack") or not "ai_type" in mob:
		push_error("Spawned mob is not a valid mob")
		mob.queue_free()
		return
	
	mob.ai_type = ai_types.pick_random()
	
	var scene_name = mob_to_spawn.resource_path.get_file().get_basename()
	mob.name = scene_name + "_" + mob.ai_type + "_" + str(randi() % 1000)
	
	add_child(mob)
	print("Spawning ", mob.ai_type, " ", mob.name)
	
	GameStats.increment_live_enemies()
	
	if marker:
		mob.global_position = marker.global_position
