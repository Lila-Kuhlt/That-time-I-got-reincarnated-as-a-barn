extends TextureButton

class_name ToolbarItem

signal item_selected(slot_id)

var slot_id: int

enum ItemId {
	CHILI = 0,
	TOMATO = 1,
	POTATO = 2,
	NONE = 3
}

var item = ItemId.NONE

func _ready():
	set_item()
	pass

func set_selected(is_sel: bool) -> void:
	self.pressed = is_sel

func set_item(item_id=null):
	if item_id == null:
		item_id = self.item
	else:
		self.item = item_id
	$ItemTexture.visible = item_id != ItemId.NONE
	if item_id != ItemId.NONE:
		var x: int = $ItemTexture.texture.region.size.y * int(item_id)
		print(x)
		$ItemTexture.texture.region.position.x = x

func register_callback(toolbar):
	toolbar.connect("item_selected", self, "_on_toolbar_selection_changed")

func _on_toolbar_selection_changed(slot):
	set_selected(self.slot_id == slot)

func _on_ToolbarItem_button_down():
	emit_signal("item_selected", slot_id)
