extends ColorRect
class_name InventorySlot

@export var item: Item
@export var texture: TextureRect

func _ready() -> void:
	if texture:
		texture.expand_mode = TextureRect.EXPAND_IGNORE_SIZE
		texture.stretch_mode = TextureRect.STRETCH_SCALE
		texture.anchor_left = 0.0
		texture.anchor_top = 0.0
		texture.anchor_right = 1.0
		texture.anchor_bottom = 1.0
		texture.offset_left = 0.0
		texture.offset_top = 0.0
		texture.offset_right = 0.0
		texture.offset_bottom = 0.0

func set_item(new_item: Item) -> void:
	item = new_item
	if texture:
		if new_item and new_item.inventoryItem:
			texture.texture = new_item.inventoryItem.inventoryImage
		else:
			texture.texture = null

