extends HBoxContainer

var item_type = Globals.ItemType.None setget _set_item_type
var value = 0 setget _set_value

func _ready():
	var sprite = $Control/Sprite
	sprite.texture = sprite.texture.duplicate()

func _set_item_type(v):
	item_type = v
	var sprite = $Control/Sprite
	sprite.texture.region.position.x = v * sprite.texture.region.size.y

func _set_value(v):
	value = v
	$Label.text = str(v)
