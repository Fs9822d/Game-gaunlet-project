extends Control
class_name Inventory

@export var inventorySlot: PackedScene
@export var amountToSpawn: int

@export var activeSlot: ColorRect

@export var hand: Hand
var slots: Array = []
var layout_tween: Tween
var selectedSlot: int = 0:
	set(value):
		selectedSlot = value
		if hand:
			hand.update_held_items_visibility()
		update_slots_layout(true)

func _ready() -> void:
	createSlots()
	update_slots_layout(false)
	self.visible = false

func _process(delta: float) -> void:
	if Input.is_action_just_pressed("Inventory"):
		self.visible = not self.visible

		if self.visible:
			Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		else:
			Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			scroll_slots(-1)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			scroll_slots(1)

func scroll_slots(dir: int) -> void:
	if slots.is_empty():
		return
	selectedSlot = posmod(selectedSlot + dir, slots.size())

func update_slots_layout(animate: bool = true) -> void:
	if layout_tween and layout_tween.is_valid():
		layout_tween.kill()
		
	var current_y: float = 0.0
	var spacing: float = 2.0
	
	if animate:
		layout_tween = create_tween().set_parallel(true).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_OUT)
		
	for i in range(slots.size()):
		var slot = slots[i]
		var target_size = Vector2(118, 118)
		if i == selectedSlot:
			target_size = Vector2(150, 150)
		
		var target_y = current_y
		current_y += target_size.y + spacing
		
		if animate:
			layout_tween.tween_property(slot, "custom_minimum_size", target_size, 0.15)
			layout_tween.tween_property(slot, "size", target_size, 0.15)
			layout_tween.tween_property(slot, "position:y", target_y, 0.15)
		else:
			slot.custom_minimum_size = target_size
			slot.size = target_size
			slot.position.y = target_y
	
	if activeSlot and selectedSlot >= 0 and selectedSlot < slots.size():
		var target_size = Vector2(150, 150)
		var target_y: float = 0.0
		for i in range(selectedSlot):
			target_y += Vector2(118, 118).y + spacing
			
		if animate:
			layout_tween.tween_property(activeSlot, "size", target_size, 0.15)
			layout_tween.tween_property(activeSlot, "position:y", target_y, 0.15)
		else:
			activeSlot.size = target_size
			activeSlot.position.y = target_y

func get_combined_y_size() -> float:
	var total: float = 0.0
	for slot in slots:
		total += slot.size.y
	return total + slots.size()

func createSlots() -> void:
	for i in range(amountToSpawn):
		var new_slot = inventorySlot.instantiate()
		add_child(new_slot)
		new_slot.position.y = get_combined_y_size()
		slots.append(new_slot)

func add_item(item: Item) -> bool:
	for slot in slots:
		if slot.item == null:
			slot.set_item(item)
			return true
	return false

func get_active_item() -> Item:
	if selectedSlot >= 0 and selectedSlot < slots.size():
		return slots[selectedSlot].item
	return null

func remove_item(item: Item) -> void:
	for slot in slots:
		if slot.item == item:
			slot.set_item(null)
			break