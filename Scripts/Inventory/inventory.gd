extends Control
class_name Inventory

@export var inventorySlot: PackedScene
@export var amountToSpawn: int
var slots: Array = []

func _ready() -> void:
	createSlots()

func get_combined_y_size() -> float:
	var total: float = 0.0
	for slot in slots:
		total += slot.size.y
	return total + slots.size() * 2.0

func createSlots() -> void:
	for i in range(amountToSpawn):
		var new_slot = inventorySlot.instantiate()
		add_child(new_slot)
		new_slot.position.y = get_combined_y_size()
		slots.append(new_slot)