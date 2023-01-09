extends Button

class_name ToolbarItem

signal item_selected(slot_id)

export var show_value = false setget _set_show_value
var shown_value = "Test" setget _set_shown_value

var slot_id: int

const DEFAULT_TEXTURE = 0

var TEXTURE_LOOKUP = {
	Globals.ItemType.None : 0,
	
	# Items
	Globals.ItemType.ToolScythe : 1,
	Globals.ItemType.ToolWateringCan : 2,

	#Plants
	Globals.ItemType.PlantChili : 3,
	Globals.ItemType.PlantTomato : 4,
	Globals.ItemType.PlantAubergine : 5,
	Globals.ItemType.PlantPotato : 6,

	# Towers
	Globals.ItemType.TowerWindmill : 7,
	Globals.ItemType.TowerWatertower : 8,
	Globals.ItemType.TowerWIP : 9
}

func _ready():
	set_item()
	icon = icon.duplicate()
	_set_shown_value(shown_value)
	_set_show_value(show_value)
	pass

func set_selected(is_sel: bool) -> void:
	self.pressed = is_sel

func set_item(item_id=DEFAULT_TEXTURE):
	if not item_id in Globals.ITEM_NAMES:
		item_id = DEFAULT_TEXTURE

	var x: int = icon.region.size.y * int(TEXTURE_LOOKUP[item_id])
	icon.region.position.x = x
	
func _set_shown_value(v):
	shown_value = v
	$Label.text = str(v)
func _set_show_value(v):
	show_value = v
	$Label.visible = v

func register_callback(toolbar):
	toolbar.connect("item_selected", self, "_on_toolbar_selection_changed")

func _on_toolbar_selection_changed(slot):
	set_selected(self.slot_id == slot)

func _on_ToolbarItem_button_down():
	emit_signal("item_selected", slot_id)
