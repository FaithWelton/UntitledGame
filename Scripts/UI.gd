extends Control

@onready var live_enemies_label: Label = $Stats/LiveEnemies
@onready var player_health_label: Label = $Stats/Health
@onready var bullet_stats_label: Label = $Stats/BulletsFired

var bullet_pool: BulletPool

func _ready() -> void:
	GameStats.live_enemies_changed.connect(_on_live_enemies_changed)
	GameStats.stats_updated.connect(_on_stats_updated)

	PlayerStats.health_changed.connect(_on_player_health_changed)
	PlayerStats.stats_updated.connect(_on_player_stats_updated)

	# Defer finding bullet pool to ensure scene tree is ready
	call_deferred("_find_bullet_pool")
	refresh_ui()

func _find_bullet_pool() -> void:
	var pools = get_tree().get_nodes_in_group("bullet_pool")
	if not pools.is_empty():
		bullet_pool = pools[0]

func _process(_delta: float) -> void:
	_update_bullet_stats()

func refresh_ui() -> void:
	update_stat_labels()

func update_stat_labels() -> void:
	if live_enemies_label:
		live_enemies_label.text = "Live Enemies: %d" % GameStats.live_enemies

	if player_health_label:
		player_health_label.text = "Player Health: %d/%d" % [PlayerStats.health, PlayerStats.max_health]

	_update_bullet_stats()

func _update_bullet_stats() -> void:
	if not bullet_stats_label:
		return

	if bullet_pool:
		var stats = bullet_pool.get_stats()
		bullet_stats_label.text = "Bullets: %d active / %d available" % [stats.active, stats.available]
	else:
		bullet_stats_label.text = "Bullets: Pool not found"

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
		player_health_label.text = "Player Health: %d/%d" % [new_health, PlayerStats.max_health]

func _on_player_stats_updated(stats: Dictionary) -> void:
	print("Player Stats Updated: ", stats)
	update_stat_labels()
