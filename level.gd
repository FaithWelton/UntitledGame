extends Node3D

var player_score = 0
@onready var score: Label = %Score

func increase_score():
	player_score += 1
	score.text = "Score: " + str(player_score)

func do_poof(mob_global_position):
	const SMOKE_PUFF = preload("res://mob/smoke_puff/smoke_puff.tscn")
	var poof = SMOKE_PUFF.instantiate()
	add_child(poof)
	poof.global_position = mob_global_position

func _on_mob_spawner_mob_spawned(mob: Variant) -> void:
	mob.died.connect(func on_mob_died():
		increase_score()
		do_poof(mob.global_position)
	)
	
	do_poof(mob.global_position)

func _on_kill_plane_body_entered(body: Node3D) -> void:
	get_tree().reload_current_scene.call_deferred()
