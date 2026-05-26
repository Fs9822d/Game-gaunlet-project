extends Node3D
class_name Hand

@export var handExtent: float = 3.0
@export var throwForce: float = 12.0

@export var camera: Camera3D
@export var use_camera_forward_axis: bool = true

@export var inventory: Inventory

var handItem: Item:
	get:
		if inventory:
			return inventory.get_active_item()
		return null

func _ready() -> void:
	if not camera:
		if get_parent() is Camera3D:
			camera = get_parent()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("Interact"):
		if handItem:
			throw_item()
		else:
			interact_raycast()

func interact_raycast() -> void:
	if not camera:
		printerr("Hand: No Camera3D set or found!")
		return
	
	var space_state = get_world_3d().direct_space_state
	if not space_state:
		return
		
	# Determine the ray direction
	var dir = - camera.global_transform.basis.z if use_camera_forward_axis else -camera.global_transform.basis.y
	
	var from = camera.global_position
	var to = from + dir * handExtent
	
	var query = PhysicsRayQueryParameters3D.create(from, to)
	
	# Exclude player node if possible to prevent self-collision
	var player = get_parent().get_parent()
	if player:
		query.exclude = [player.get_rid()]
		
	# Query the physics space
	var result = space_state.intersect_ray(query)
	if result and result.collider:
		var collider = result.collider
		if collider is Item:
			pick_up_item(collider)

func pick_up_item(item: Item) -> void:
	if not inventory:
		printerr("Hand: No inventory set!")
		return
	if not inventory.add_item(item):
		return
		
	item.picked = true
	
	# Re-parent the item to the Hand node
	if item.get_parent():
		item.get_parent().remove_child(item)
	add_child(item)
	
	# Reset local position and rotation to align perfectly with the Hand node
	item.position = Vector3.ZERO
	item.rotation = Vector3.ZERO
	
	update_held_items_visibility()

func throw_item() -> void:
	var item = handItem
	if not item:
		return
		
	if inventory:
		inventory.remove_item(item)
	
	# Save the global position before changing parents
	var throw_pos = global_position
	
	# Re-parent the item back to the main scene tree
	remove_child(item)
	var scene_root = get_tree().current_scene
	if scene_root:
		scene_root.add_child(item)
	else:
		get_tree().root.add_child(item)
		
	item.global_position = throw_pos
	item.picked = false
	
	# Add velocity to the item along the camera direction
	var dir = - camera.global_transform.basis.z if use_camera_forward_axis else -camera.global_transform.basis.y
	item.velocity = dir * throwForce
	
	update_held_items_visibility()

func update_held_items_visibility() -> void:
	var active_item = handItem
	for child in get_children():
		if child is Item:
			child.visible = (child == active_item)
