extends TextureButton

class_name ToolbarItem

signal item_selected(slot_id)

var slot_id: int

const DEFAULT_TEXTURE = -1

var TEXTURE_LOOKUP = {
	# Items
	Globals.ItemType.ToolScythe : 0,
	Globals.ItemType.ToolWateringCan : 1,
	
	#Plants
	Globals.ItemType.PlantChili : 2,
	Globals.ItemType.PlantTomato : 3,
	Globals.ItemType.PlantAubergine : 4,
	Globals.ItemType.PlantPotato : 5,
	
	# Towers
	Globals.ItemType.TowerWindmill : -1,
	Globals.ItemType.TowerWatertower : -1,
	Globals.ItemType.TowerWIP : -1
}

func _ready():
	set_item()
	pass

func set_selected(is_sel: bool) -> void:
	self.pressed = is_sel

func set_item(item_id=DEFAULT_TEXTURE):
	if not item_id in Globals.ITEM_NAMES:
		item_id = DEFAULT_TEXTURE

	if item_id != DEFAULT_TEXTURE:
		$ItemTexture.visible = true
		var x: int = $ItemTexture.texture.region.size.y * int(TEXTURE_LOOKUP[item_id])
		$ItemTexture.texture.region.position.x = x
	else:
		$ItemTexture.visible = false

func register_callback(toolbar):
	toolbar.connect("item_selected", self, "_on_toolbar_selection_changed")

func _on_toolbar_selection_changed(slot):
	set_selected(self.slot_id == slot)

func _on_ToolbarItem_button_down():
	emit_signal("item_selected", slot_id)
