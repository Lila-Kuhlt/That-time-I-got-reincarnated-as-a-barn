extends Button

func _ready():
	pass

func _on_ButtonStart_pressed():
	get_tree().change_scene_to(preload("res://scenes/World.tscn"))
