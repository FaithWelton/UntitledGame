extends Node

signal stats_updated(stats: Dictionary)
signal live_enemies_changed(count: int)

const MIN_ENEMIES: int = 0

@export_group("Current Stats")
@export var live_enemies: int = 0

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
