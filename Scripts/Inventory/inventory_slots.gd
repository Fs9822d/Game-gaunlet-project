extends ColorRect
class_name InventorySlot

@export var item: Item
@export var texture: TextureRect

func set_item(new_item: Item) -> void:
	item = new_item
	if texture:
		if new_item and new_item.inventoryItem:
			texture.texture = new_item.inventoryItem.inventoryImage
		else:
			texture.texture = null
