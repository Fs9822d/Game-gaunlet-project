extends Control
class_name Inventory

@export var inventorySlot: PackedScene
@export var amountToSpawn: int

@export var hand: Hand
var slots: Array = []

func _ready() -> void:
	createSlots()
	self.visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Inventory"):
		self.visible = not self.visible

		if self.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

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