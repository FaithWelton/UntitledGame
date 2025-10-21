extends Resource
class_name LootTable

# Individual loot entry
class LootEntry:
	var item_path: String
	var drop_chance: float  # 0.0 to 1.0 (0% to 100%)
	var min_quantity: int = 1
	var max_quantity: int = 1

	func _init(path: String, chance: float, min_qty: int = 1, max_qty: int = 1) -> void:
		item_path = path
		drop_chance = chance
		min_quantity = min_qty
		max_quantity = max_qty

var loot_entries: Array[LootEntry] = []

func add_loot(item_path: String, drop_chance: float, min_quantity: int = 1, max_quantity: int = 1) -> void:
	var entry = LootEntry.new(item_path, drop_chance, min_quantity, max_quantity)
	loot_entries.append(entry)

func roll_loot() -> Array[Dictionary]:
	var dropped_items: Array[Dictionary] = []

	for entry in loot_entries:
		# Roll for this item
		if randf() <= entry.drop_chance:
			var quantity = randi_range(entry.min_quantity, entry.max_quantity)
			dropped_items.append({
				"item_path": entry.item_path,
				"quantity": quantity
			})

	return dropped_items
