extends PickupItem

func _ready() -> void:
	# Set the specific resource path for health potion items
	resource = "res://Items/Resources/potion_health.tres"
	# Call parent _ready to handle setup
	super._ready()
