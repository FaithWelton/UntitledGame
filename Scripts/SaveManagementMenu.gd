extends Control

signal saves_changed()

@onready var save_list: VBoxContainer = $Panel/VBoxContainer/ScrollContainer/SaveList
@onready var no_saves_label: Label = $Panel/VBoxContainer/ScrollContainer/SaveList/NoSavesLabel

const SaveEntry = preload("res://UI/SaveEntry.tscn")

func _ready() -> void:
	_refresh_save_list()

func show_menu() -> void:
	visible = true
	_refresh_save_list()

func hide_menu() -> void:
	visible = false

func _refresh_save_list() -> void:
	# Clear existing entries (except the "no saves" label)
	for child in save_list.get_children():
		if child != no_saves_label:
			child.queue_free()

	# Get all save files
	var saves = _get_all_saves()

	if saves.is_empty():
		no_saves_label.visible = true
	else:
		no_saves_label.visible = false

		for save_info in saves:
			var entry = SaveEntry.instantiate()
			save_list.add_child(entry)
			entry.setup(save_info)
			entry.delete_requested.connect(_on_delete_save_requested)

func _get_all_saves() -> Array[Dictionary]:
	var saves: Array[Dictionary] = []

	for i in range(SaveSystem.MAX_SAVES):
		if SaveSystem.save_exists(i):
			var save_path = SaveSystem.SAVE_DIR + "save_slot_%d.json" % i
			var save_info = _load_save_info(save_path)
			if save_info:
				save_info["slot"] = i
				save_info["file_name"] = "save_slot_%d.json" % i
				saves.append(save_info)

	# Sort by timestamp (newest first)
	saves.sort_custom(func(a, b): return a.get("timestamp", 0) > b.get("timestamp", 0))

	return saves

func _load_save_info(file_path: String) -> Dictionary:
	var file = FileAccess.open(file_path, FileAccess.READ)
	if not file:
		return {}

	var json_string = file.get_as_text()
	file.close()

	var json = JSON.new()
	var parse_result = json.parse(json_string)

	if parse_result != OK:
		return {}

	var data = json.data
	if typeof(data) != TYPE_DICTIONARY:
		return {}

	return data

func _on_delete_save_requested(slot: int) -> void:
	SaveSystem.delete_save(slot)
	_refresh_save_list()
	saves_changed.emit()

func _on_refresh_pressed() -> void:
	_refresh_save_list()

func _on_close_pressed() -> void:
	hide_menu()
