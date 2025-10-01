extends PanelContainer
class_name ItemTooltip

@onready var item_name_label: Label = $VBoxContainer/ItemName
@onready var item_type_label: Label = $VBoxContainer/ItemType
@onready var description_label: Label = $VBoxContainer/Description
@onready var stats_label: Label = $VBoxContainer/Stats

func _ready() -> void:
	hide()
	mouse_filter = Control.MOUSE_FILTER_IGNORE

func show_tooltip(item: Item, mouse_position: Vector2) -> void:
	if not item:
		hide()
		return

	_update_tooltip_content(item)
	_position_tooltip(mouse_position)
	show()

func hide_tooltip() -> void:
	hide()

func _update_tooltip_content(item: Item) -> void:
	# Item name
	if item_name_label:
		item_name_label.text = item.name

	# Item type
	if item_type_label:
		item_type_label.text = item.get_type_string()

	# Description
	if description_label:
		if item.description.is_empty():
			description_label.hide()
		else:
			description_label.text = item.description
			description_label.show()

	# Stats
	if stats_label:
		var stats_text = _build_stats_text(item)
		if stats_text.is_empty():
			stats_label.hide()
		else:
			stats_label.text = stats_text
			stats_label.show()

func _build_stats_text(item: Item) -> String:
	var stats = []

	if item.health > 0:
		stats.append("+%d Health" % item.health)

	if item.strength > 0:
		stats.append("+%d Strength" % item.strength)

	if item.armor > 0:
		stats.append("+%d Armor" % item.armor)

	if item.is_stackable():
		stats.append("Max Stack: %d" % item.max_stack_size)

	return "\n".join(stats)

func _position_tooltip(mouse_pos: Vector2) -> void:
	# Offset tooltip slightly from cursor
	var offset = Vector2(15, 15)
	var target_pos = mouse_pos + offset

	# Make sure tooltip doesn't go off screen
	var screen_size = get_viewport_rect().size
	var tooltip_size = size

	if target_pos.x + tooltip_size.x > screen_size.x:
		target_pos.x = mouse_pos.x - tooltip_size.x - offset.x

	if target_pos.y + tooltip_size.y > screen_size.y:
		target_pos.y = mouse_pos.y - tooltip_size.y - offset.y

	global_position = target_pos
