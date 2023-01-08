extends CanvasLayer

signal screen_clicked(worldpos)
signal item_selected(globals_itemtype)

onready var toolbar = $MarginContainer/VBoxContainer/ToolBar

func _on_TextureButton_button_up():
	# get mouse pos in world pos from Node not inside the UI CanvasLayer
	var click_pos = get_tree().root.get_node("World").get_global_mouse_position()
	emit_signal("screen_clicked", click_pos)


func _on_toolbar_item_selected(globals_itemtype):
	emit_signal("item_selected", globals_itemtype)
