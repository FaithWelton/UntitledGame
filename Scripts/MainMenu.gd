extends Control

@onready var continue_button: Button = $VBoxContainer/ContinueButton
@onready var load_button: Button = $VBoxContainer/LoadGameButton
@onready var save_management_menu: Control = $SaveManagementMenu

func _ready() -> void:
	# Enable/disable continue button based on save file existence
	_update_button_states()

	# Connect to save management menu signals
	if save_management_menu:
		save_management_menu.saves_changed.connect(_update_button_states)

func _update_button_states() -> void:
	var has_save = SaveSystem.any_save_exists()
	continue_button.disabled = not has_save
	load_button.disabled = not has_save

func _on_new_game_pressed() -> void:
	# Find next available save slot, or set to -1 if all full
	var slot = SaveSystem.get_next_available_slot()

	# Set the current slot (or -1 if full, which will trigger prompt on first save)
	SaveSystem.current_save_slot = slot

	# Reset player stats to defaults
	PlayerStats.health = PlayerStats.base_health
	PlayerStats.max_health = PlayerStats.base_max_health
	PlayerStats.strength = PlayerStats.base_strength
	PlayerStats.armor = PlayerStats.base_armor
	PlayerStats.crit_chance = PlayerStats.base_crit_chance
	PlayerStats.crit_multiplier = PlayerStats.base_crit_multiplier
	PlayerStats.dead = false
	PlayerStats.level = 1

	# Reset game stats
	GameStats.live_enemies = 0

	# Start the game
	get_tree().change_scene_to_file("res://main.tscn")

func _on_continue_pressed() -> void:
	# Load most recent save and start game
	var slot = SaveSystem.get_most_recent_save_slot()

	if slot == -1:
		push_error("No save file found")
		return

	if SaveSystem.load_game(slot):
		get_tree().change_scene_to_file("res://main.tscn")
	else:
		push_error("Failed to load save file")

func _on_load_game_pressed() -> void:
	# Same as continue for now
	_on_continue_pressed()

func _on_manage_saves_pressed() -> void:
	if save_management_menu:
		save_management_menu.show_menu()

func _on_quit_pressed() -> void:
	get_tree().quit()
