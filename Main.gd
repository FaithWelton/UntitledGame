extends Node3D

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("quick_save"):
		_quick_save()
	elif event.is_action_pressed("quick_load"):
		_quick_load()

func _quick_save() -> void:
	# Check if we need to confirm overwrite
	if SaveSystem.current_save_slot < 0 or SaveSystem.current_save_slot >= SaveSystem.MAX_SAVES:
		_show_quick_save_overwrite_confirmation()
		return

	if SaveSystem.save_game():
		print("Quick Save: Game saved successfully (F5)")
	else:
		print("Quick Save: Failed to save game")

func _show_quick_save_overwrite_confirmation() -> void:
	var oldest_slot = SaveSystem.get_oldest_save_slot()

	if oldest_slot == -1:
		print("Quick Save: No save slots available!")
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
			print("Quick Save: Game saved successfully (F5)")
		else:
			print("Quick Save: Failed to save game")
		dialog.queue_free()
	)

	dialog.canceled.connect(func():
		print("Quick Save: Cancelled")
		dialog.queue_free()
	)

func _quick_load() -> void:
	if SaveSystem.load_game():
		print("Quick Load: Game loaded successfully (F6)")
	else:
		print("Quick Load: No save file found or failed to load")
