extends PickupItem

func _ready() -> void:
	# Set the specific resource path for revive potion items
	resource = "res://Items/Resources/potion_revive.tres"
	# Call parent _ready to handle setup
	super._ready()
