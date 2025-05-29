extends Node3D

var player_score = 0
@onready var score: Label = %Score

func increase_score():
	player_score += 1
	score.text = "Score: " + str(player_score)
	
func _on_mob_spawner_mob_spawned(mob: Variant) -> void:
	mob.died.connect(increase_score)
