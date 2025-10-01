extends Control

@onready var live_enemies_label: Label = $"EnemyStatsLabel/LiveEnemies"
@onready var player_health_label: Label = $PlayerStatsLabel/Health

func _ready() -> void:
	GameStats.live_enemies_changed.connect(_on_live_enemies_changed)
	GameStats.stats_updated.connect(_on_stats_updated)
	
	PlayerStats.health_changed.connect(_on_player_health_changed)
	PlayerStats.strength_changed.connect(_on_player_strength_changed)
	PlayerStats.armor_changed.connect(_on_player_armor_changed)
	PlayerStats.stats_updated.connect(_on_player_stats_updated)
	
	refresh_ui()

func refresh_ui() -> void:
	update_stat_labels()

func update_stat_labels() -> void:
	if live_enemies_label:
		live_enemies_label.text = "Live Enemies: %d" % GameStats.live_enemies
	
	if player_health_label:
		player_health_label.text = "Player Health: %d" % PlayerStats.health

func _on_stats_updated(stats: Dictionary) -> void:
	print("Stats Updated: ", stats)
	update_stat_labels()

func _on_live_enemies_changed(count: int) -> void:
	print("Live enemies changed to: ", count)
	if live_enemies_label:
		live_enemies_label.text = "Live Enemies: %d" % count

func _on_player_health_changed(new_health: int) -> void:
	print("Player health changed to: ", new_health)
	if player_health_label:
		player_health_label.text = "Player Health: %d" % new_health

func _on_player_strength_changed(new_strength: int) -> void:
	print("Player strength changed to: ", new_strength)
	#TODO: UI Component for displaying strength

func _on_player_armor_changed(new_armor: int) -> void:
	print("Player armor changed to: ", new_armor)
	#TODO: UI Component for displaying armor

func _on_player_stats_updated(stats: Dictionary) -> void:
	print("Player Stats Updated: ", stats)
	update_stat_labels()
