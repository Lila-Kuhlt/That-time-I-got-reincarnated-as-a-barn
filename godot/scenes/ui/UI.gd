extends CanvasLayer

signal screen_clicked(worldpos)
signal item_selected(globals_itemtype)

onready var toolbar = $MarginContainer/VBoxContainer/ToolBar

func _on_TextureButton_button_up():
	var click_pos = get_viewport().get_mouse_position()
	emit_signal("screen_clicked", click_pos)


func _on_toolbar_item_selected(globals_itemtype):
	emit_signal("item_selected", globals_itemtype)
