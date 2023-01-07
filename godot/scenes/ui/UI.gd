extends CanvasLayer

signal screen_clicked (worldpos) 

onready var toolbar = $MarginContainer/VBoxContainer/ToolBar

func _ready():
	pass # Replace with function body.

func _on_TextureButton_button_up():
	var click_pos = get_viewport().get_mouse_position()
	emit_signal("screen_clicked", click_pos)
