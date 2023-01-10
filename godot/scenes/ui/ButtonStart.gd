extends Button

func _ready():
	pass

func _on_ButtonStart_pressed():
	# abort if already pressed
	if not pressed:
		pressed = true
		return
	yield(get_tree().create_timer(0.1), "timeout")
	get_tree().change_scene_to(preload("res://scenes/World.tscn"))
