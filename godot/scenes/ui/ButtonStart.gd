extends Button

func _ready():
	pass

func _on_ButtonStart_pressed():
	disabled = true
	yield(get_tree().create_timer(0.2), "timeout")
	get_tree().change_scene_to(preload("res://scenes/World.tscn"))
