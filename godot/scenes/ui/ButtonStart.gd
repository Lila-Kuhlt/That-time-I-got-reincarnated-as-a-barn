extends Button

func _ready():
	pass

func _on_ButtonStart_pressed():
	# abort if already pressed
	if not pressed:
		pressed = true
		return
	
	ScreenLoader.goto_scene("res://scenes/screens/ScreenGame.tscn")
