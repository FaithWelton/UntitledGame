extends Resource
class_name Item

enum ItemType {
	WEAPON,
	ARMOR,
	USEABLE,
	INTERACTABLE
}

enum Rarity {
	COMMON,
	UNCOMMON,
	RARE,
	EPIC,
	LEGENDARY
}

@export_group("Basic Info")
@export var name: String = ""
@export_multiline var description: String = ""
@export var icon: CompressedTexture2D
@export var use_effect: String = ""
@export var type: ItemType = ItemType.USEABLE
@export var rarity: Rarity = Rarity.COMMON

@export_group("Stats")
@export var health: int = 0
@export var strength: int = 0
@export var armor: int = 0

@export_group("Inventory Data")
@export var inv_slot: String = ""
@export var inv_position: int = -1
@export var max_stack_size: int = 1
@export var stack_size: int = 1

func get_type_string() -> String:
	match type:
		ItemType.WEAPON:
			return "Weapon"
		ItemType.ARMOR:
			return "Armor"
		ItemType.USEABLE:
			return "Useable"
		ItemType.INTERACTABLE:
			return "Interactable"
		_:
			return "Unknown"

func is_stackable() -> bool:
	return max_stack_size > 1

func can_stack_with(other: Item) -> bool:
	if not other or not is_stackable():
		return false

	# Items can stack if they have the same resource path
	return resource_path == other.resource_path

func add_to_stack(amount: int) -> int:
	var space_available = max_stack_size - stack_size
	var amount_to_add = min(amount, space_available)
	stack_size += amount_to_add
	return amount - amount_to_add  # Return remaining amount that couldn't be added

func remove_from_stack(amount: int) -> int:
	var amount_to_remove = min(amount, stack_size)
	stack_size -= amount_to_remove
	return amount_to_remove

func is_stack_full() -> bool:
	return stack_size >= max_stack_size

func is_stack_empty() -> bool:
	return stack_size <= 0

func get_rarity_string() -> String:
	match rarity:
		Rarity.COMMON:
			return "Common"
		Rarity.UNCOMMON:
			return "Uncommon"
		Rarity.RARE:
			return "Rare"
		Rarity.EPIC:
			return "Epic"
		Rarity.LEGENDARY:
			return "Legendary"
		_:
			return "Common"

func get_rarity_color() -> Color:
	match rarity:
		Rarity.COMMON:
			return Color(0.6, 0.6, 0.6)  # Gray
		Rarity.UNCOMMON:
			return Color(0.2, 0.8, 0.2)  # Green
		Rarity.RARE:
			return Color(0.2, 0.5, 1.0)  # Blue
		Rarity.EPIC:
			return Color(0.7, 0.2, 1.0)  # Purple
		Rarity.LEGENDARY:
			return Color(1.0, 0.6, 0.0)  # Orange/Gold
		_:
			return Color(0.6, 0.6, 0.6)  # Default gray
