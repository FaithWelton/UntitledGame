extends Resource
class_name Item

@export_group("Settings")
@export var name: String
@export_multiline var description: String
@export var icon: CompressedTexture2D
@export var use_effect: String
@export_enum("Weapon", "Armor", "Useable", "Interactable") var type: String

@export_group("Stats")
@export var health: int
@export var strength: int
@export var armor: int

@export_group("Inventory Data")
@export var inv_slot: String
@export var inv_position: int
