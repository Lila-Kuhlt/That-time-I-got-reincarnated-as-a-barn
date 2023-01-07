extends CanvasLayer


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
signal screen_clicked (worldpos) 
signal hover_start
signal hover_stop

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass


func _on_TextureButton_button_up():
	var click_pos = get_viewport().get_mouse_position()
	emit_signal("screen_clicked", click_pos)


func _on_TextureButton_mouse_entered():
	emit_signal("hover_start")

func _on_TextureButton_mouse_exited():
	emit_signal("hover_stop")
