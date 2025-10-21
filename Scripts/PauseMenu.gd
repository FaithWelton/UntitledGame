extends Control

@onready var load_button: Button = $Panel/VBoxContainer/LoadButton
@onready var status_label: Label = $Panel/VBoxContainer/StatusLabel

func _ready() -> void:
	_update_button_states()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("pause_menu"):
		_toggle_pause()

func _toggle_pause() -> void:
	visible = not visible
	get_tree().paused = visible

	if visible:
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		_update_button_states()
		status_label.text = ""
	else:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _update_button_states() -> void:
	var has_save = SaveSystem.save_exists()
	load_button.disabled = not has_save

func _on_resume_pressed() -> void:
	_toggle_pause()

func _on_save_pressed() -> void:
	# Check if we need to confirm overwrite
	if SaveSystem.current_save_slot < 0 or SaveSystem.current_save_slot >= SaveSystem.MAX_SAVES:
		_show_overwrite_confirmation()
		return

	if SaveSystem.save_game():
		status_label.text = "Game Saved!"
		status_label.modulate = Color.GREEN
		_update_button_states()

		# Clear status after 2 seconds
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(status_label):
			status_label.text = ""
	else:
		status_label.text = "Save Failed!"
		status_label.modulate = Color.RED

func _show_overwrite_confirmation() -> void:
	var oldest_slot = SaveSystem.get_oldest_save_slot()

	if oldest_slot == -1:
		status_label.text = "No save slots available!"
		status_label.modulate = Color.RED
		return

	# Get info about the save that will be overwritten
	var save_path = SaveSystem.SAVE_DIR + "save_slot_%d.json" % oldest_slot
	var file = FileAccess.open(save_path, FileAccess.READ)
	var save_info = ""

	if file:
		var json_string = file.get_as_text()
		file.close()

		var json = JSON.new()
		if json.parse(json_string) == OK:
			var data = json.data
			var timestamp = data.get("timestamp", 0)
			if timestamp > 0:
				var datetime = Time.get_datetime_dict_from_unix_time(timestamp)
				save_info = "\n\nSlot %d - Saved: %04d-%02d-%02d %02d:%02d:%02d" % [
					oldest_slot + 1,
					datetime.year, datetime.month, datetime.day,
					datetime.hour, datetime.minute, datetime.second
				]

	var dialog = ConfirmationDialog.new()
	dialog.dialog_text = "All save slots are full!\n\nOverwrite the oldest save?%s" % save_info
	dialog.ok_button_text = "Overwrite"
	dialog.cancel_button_text = "Cancel"

	add_child(dialog)
	dialog.popup_centered()

	dialog.confirmed.connect(func():
		if SaveSystem.save_game(oldest_slot, true):
			status_label.text = "Game Saved!"
			status_label.modulate = Color.GREEN
			_update_button_states()
			await get_tree().create_timer(2.0).timeout
			if is_instance_valid(status_label):
				status_label.text = ""
		else:
			status_label.text = "Save Failed!"
			status_label.modulate = Color.RED
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		status_label.text = "Save Cancelled"
		status_label.modulate = Color.YELLOW
		await get_tree().create_timer(2.0).timeout
		if is_instance_valid(status_label):
			status_label.text = ""
		dialog.queue_free()
	)

func _on_load_pressed() -> void:
	if SaveSystem.load_game():
		status_label.text = "Game Loaded!"
		status_label.modulate = Color.GREEN

		# Close pause menu and resume after short delay
		await get_tree().create_timer(0.5).timeout
		_toggle_pause()
	else:
		status_label.text = "Load Failed!"
		status_label.modulate = Color.RED

func _on_main_menu_pressed() -> void:
	get_tree().paused = false
	get_tree().change_scene_to_file("res://UI/MainMenu.tscn")

func _on_quit_pressed() -> void:
	get_tree().quit()
