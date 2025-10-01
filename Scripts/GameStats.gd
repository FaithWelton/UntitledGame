extends Node

signal stats_updated(stats: Dictionary)
signal live_enemies_changed(count: int)

const MIN_ENEMIES: int = 0

@export_group("Current Stats")
@export var live_enemies: int = 0

func update_ui_stats(stats: Dictionary) -> void:
	live_enemies = stats.get("live_enemies", 0)
	stats_updated.emit(get_current_stats())

func update_live_enemy_count(count: int) -> void:
	live_enemies = count
	_emit_stat_changes()

func increment_live_enemies() -> void:
	live_enemies += 1
	_emit_stat_changes()

func decrement_live_enemies() -> void:
	live_enemies = max(MIN_ENEMIES, live_enemies - 1)
	_emit_stat_changes()

func _emit_stat_changes() -> void:
	live_enemies_changed.emit(live_enemies)
	stats_updated.emit(get_current_stats())

func get_current_stats() -> Dictionary:
	return {
		"live_enemies": live_enemies,
	}
