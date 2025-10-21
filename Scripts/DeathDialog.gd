extends Control
class_name DeathDialog

@onready var message_label: Label = $VBoxContainer/Message
@onready var revive_button: Button = $VBoxContainer/ButtonContainer/ReviveButton
@onready var respawn_button: Button = $VBoxContainer/ButtonContainer/RespawnButton

func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	PlayerStats.player_died.connect(_on_player_died)
	PlayerStats.player_revived.connect(_on_player_revived)
	PlayerStats.player_respawned.connect(_on_player_respawned)
	
	revive_button.pressed.connect(_on_revive_button_pressed)
	respawn_button.pressed.connect(_on_respawn_button_pressed)
	
func _on_player_died() -> void:
	var death_message = _get_death_message(PlayerStats.death_reason)

	if PlayerStats.has_revive_item():
		message_label.text = death_message + "\nYou have a revive item in your inventory..."
		revive_button.visible = true
		revive_button.text = "Use Revive Item"
	else:
		message_label.text = death_message + "\nYou have no revive items available..."
		revive_button.visible = false

	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)

func _get_death_message(reason: String) -> String:
	match reason:
		"falling":
			return "OH NO! You fell off the edge!"
		"combat":
			return "OH NO! You were defeated in battle!"
		"lava":
			return "OH NO! You burned in lava!"
		"quicksand":
			return "OH NO! You were swallowed by quicksand!"
		_:
			return "OH NO! You died!"

func _on_revive_button_pressed() -> void:
	print("REVIVE BUTTON PRESSED...")
	var inventory = get_tree().get_first_node_in_group("inventory")
	if inventory and inventory.use_revive_item():
		PlayerStats.revive()

func _on_respawn_button_pressed() -> void:
	print("RESPAWN BUTTON PRESSED...")
	PlayerStats.respawn()

func _on_player_revived() -> void:
	print("PLAYER HAS REVIVED")
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _on_player_respawned() -> void:
	print("PLAYER HAS RESPAWNED")
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
