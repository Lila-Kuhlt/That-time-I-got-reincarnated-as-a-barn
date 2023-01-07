extends TextureButton

signal item_selected(slot_id)

var slot_id: int;

func _ready():
	pass

func set_selected(is_sel: bool) -> void:
	self.pressed = is_sel


func _on_ToolbarItem_button_down():
	emit_signal("item_selected", slot_id)
