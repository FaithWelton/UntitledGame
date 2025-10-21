extends PanelContainer

signal delete_requested(slot: int)

@onready var file_name_label: Label = $MarginContainer/HBoxContainer/InfoContainer/FileName
@onready var stats_label: Label = $MarginContainer/HBoxContainer/InfoContainer/StatsLabel

var save_slot: int = -1
var save_file_name: String = ""
var save_data: Dictionary = {}

func setup(save_info: Dictionary) -> void:
	save_slot = save_info.get("slot", -1)
	save_file_name = save_info.get("file_name", "")
	save_data = save_info

	# Display timestamp as save name
	var timestamp = save_info.get("timestamp", 0)
	if timestamp > 0:
		var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
		file_name_label.text = "%04d-%02d-%02d %02d:%02d:%02d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute, datetime.second
		]
	else:
		file_name_label.text = "Unknown Save"

	# Display player stats
	var player_stats = save_info.get("player_stats", {})
	var health = player_stats.get("health", 0)
	var max_health = player_stats.get("max_health", 0)
	var level = player_stats.get("level", 1)

	stats_label.text = "Health: %d/%d | Level: %d" % [health, max_health, level]

func _on_load_pressed() -> void:
	if SaveSystem.load_game(save_slot):
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		push_error("Failed to load save from slot %d" % save_slot)

func _on_delete_pressed() -> void:
	# Show confirmation dialog
	var timestamp = save_data.get("timestamp", 0)
	var timestamp_text = ""

	if timestamp > 0:
		var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
		timestamp_text = "%04d-%02d-%02d %02d:%02d:%02d" % [
			datetime.year, datetime.month, datetime.day,
			datetime.hour, datetime.minute, datetime.second
		]
	else:
		timestamp_text = "Unknown Save"

	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "Are you sure you want to delete this save?\n\n%s" % timestamp_text
	dialog.ok_button_text = "Delete"
	dialog.cancel_button_text = "Cancel"

	add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(func():
		delete_requested.emit(save_slot)
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		dialog.queue_free()
	)
