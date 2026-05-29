extends Node3D


@export var spot_light_1: SpotLight3D
@export var spot_light_2: SpotLight3D

var parent_item: Item

func _ready() -> void:
	validate_parent()

# Validates parent is of type Item and gets the reference
func validate_parent() -> void:
	parent_item = get_parent() as Item
	if not parent_item:
		push_warning("Parent of torch_script is not of class Item!")

func _input(event: InputEvent) -> void:
	# Check for Left Mouse Button press
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		toggle_all_lights()

# Toggles visibility of both lights
func toggle_all_lights() -> void:
	if can_toggle_lights():
		toggle_light(spot_light_1)
		toggle_light(spot_light_2)

# Check if lights can be toggled based on parent picked status
func can_toggle_lights() -> bool:
	return parent_item != null and parent_item.picked

# Helper to toggle a single SpotLight3D
func toggle_light(light: SpotLight3D) -> void:
	if light:
		light.visible = not light.visible
