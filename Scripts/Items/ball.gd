extends PickupItem

func _ready() -> void:
	# Set the specific resource path for ball items
	resource = "res://Items/Resources/ball.tres"
	# Call parent _ready to handle setup
	super._ready()
