extends Node

signal health_changed(new_health: int)
signal strength_changed(new_strength: int)
signal armor_changed(new_armor: int)
signal player_died()
signal player_revived()
signal player_respawned()
signal stats_updated(stats: Dictionary)

@export_group("Base Stats")
@export var level: int = 1
@export var base_health: int = 100
@export var base_max_health: int = 500
@export var base_strength: int = 50
@export var base_armor: int = 100
@export var base_crit_chance: float = 0.05  # 5% base crit chance
@export var base_crit_multiplier: float = 2.0  # 2x damage on crit

@export_group("Equipment Bonuses")
var equipment_health: int = 0
var equipment_strength: int = 0
var equipment_armor: int = 0
var equipment_crit_chance: float = 0.0
var equipment_crit_multiplier: float = 0.0

@export_group("Current Stats") # Base + Equipment
@export var health: int = 100
@export var max_health: int = 500
@export var strength: int = 50
@export var armor: int = 100
@export var crit_chance: float = 0.05
@export var crit_multiplier: float = 2.0
@export var dead: bool = false

var death_reason: String = "unknown"  # Track how the player died

func update_equipment_stats(equipment_bonuses: Dictionary) -> void:
	var old_strength = strength
	var old_armor = armor

	# Store equipment bonuses
	equipment_health = equipment_bonuses.get("health", 0)
	equipment_strength = equipment_bonuses.get("strength", 0)
	equipment_armor = equipment_bonuses.get("armor", 0)
	equipment_crit_chance = equipment_bonuses.get("crit_chance", 0.0)
	equipment_crit_multiplier = equipment_bonuses.get("crit_multiplier", 0.0)

	# Calculate new stats (base + equipment)
	max_health = base_max_health + equipment_health
	strength = base_strength + equipment_strength
	armor = base_armor + equipment_armor
	crit_chance = clamp(base_crit_chance + equipment_crit_chance, 0.0, 1.0)  # Max 100%
	crit_multiplier = base_crit_multiplier + equipment_crit_multiplier

	# Make sure current health doesn't exceed new max
	health = min(max_health, health)

	# Emit signals for changed stats
	health_changed.emit(health)

	if strength != old_strength:
		strength_changed.emit(strength)

	if armor != old_armor:
		armor_changed.emit(armor)

	stats_updated.emit(get_current_stats())

func increment_health(amount: int) -> void:
	if dead:
		return

	health = min(max_health, health + amount)
	health_changed.emit(health)

func decrement_health(amount: int, reason: String = "combat") -> void:
	if dead:
		return

	health -= amount
	health_changed.emit(health)

	if health <= 0:
		health = 0
		dead = true
		death_reason = reason
		player_died.emit()

func revive() -> void:
	health = max_health
	dead = false
	health_changed.emit(health)
	player_revived.emit()

func respawn() -> void:
	health = max_health
	dead = false
	health_changed.emit(health)
	player_respawned.emit()
	#TODO: Position at start of level/checkpoint/whatever
	#TODO: Remove a life?

func has_revive_item() -> bool:
	var inventory = get_tree().get_first_node_in_group("inventory")
	if not inventory:
		return false

	return inventory.has_item_with_effect("revive")

func get_current_stats() -> Variant:
	return {
		"health": health,
		"max_health": max_health,
		"strength": strength,
		"armor": armor,
		"crit_chance": crit_chance,
		"crit_multiplier": crit_multiplier,
	}
