extends TextureButton

class_name ToolbarItem

signal item_selected(slot_id)

var slot_id: int

func _ready():
	set_item()
	pass

func set_selected(is_sel: bool) -> void:
	self.pressed = is_sel

func set_item(item_id=Globals.ITEM_NAMES.size()):
	$ItemTexture.visible = false
	if item_id != -1:
		$ItemTexture.visible = true
		var x: int = $ItemTexture.texture.region.size.y * int(item_id)
		$ItemTexture.texture.region.position.x = x

func register_callback(toolbar):
	toolbar.connect("item_selected", self, "_on_toolbar_selection_changed")

func _on_toolbar_selection_changed(slot):
	set_selected(self.slot_id == slot)

func _on_ToolbarItem_button_down():
	emit_signal("item_selected", slot_id)
