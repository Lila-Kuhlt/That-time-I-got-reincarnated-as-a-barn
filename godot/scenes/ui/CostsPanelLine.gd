extends HBoxContainer

var item_type = Globals.ItemType.None setget _set_item_type
var funds = 0 setget _set_funds
var cost = 0 setget _set_cost

const MODULATE_CAN_PAY = Color(1, 1, 1, 1)
const MODULATE_CANNOT_PAY = Color(1, 0.5, 0.5, 1)

func _ready():
	var sprite = $Control/Sprite
	sprite.texture = sprite.texture.duplicate()

func update_from_player_inventory(inventory):
	_set_funds(inventory.get_value(item_type))
	
func _set_item_type(v):
	item_type = v
	var sprite = $Control/Sprite
	sprite.texture.region.position.x = v * sprite.texture.region.size.y

func _set_cost(v):
	cost = v
	_update_text()

func _set_funds(v):
	if funds != v:
		funds = v
		_update_text()

func _update_text():
	$Label.text = "%d/%d" % [funds, cost]
	$Label.modulate = MODULATE_CAN_PAY if cost <= funds else MODULATE_CANNOT_PAY
