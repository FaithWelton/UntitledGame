extends Node

@export_group("Basic Stats")
@export var level = 1
@export var basic_health = 500
@export var basic_strength = 50
@export var basic_armor = 100

@export_group("Final Stats")
@export var health: int
@export var strength: int
@export var armor: int

func update_equipment_stats(equip_stats) -> void:
	health = basic_health + equip_stats.health
	strength = basic_strength + equip_stats.strength
	armor = basic_armor + equip_stats.armor

func get_equipment_stats() -> Variant:
	return {
		"health": health,
		"strength": strength,
		"armor": armor,
	}
