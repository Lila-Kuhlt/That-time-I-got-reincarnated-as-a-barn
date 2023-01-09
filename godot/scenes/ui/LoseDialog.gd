extends PopupDialog

func _ready():
	Globals.connect("game_lost", self, "try_show")

func try_show():
	get_tree().paused = true
	$MarginContainer/VBoxContainer/HBoxContainer/LabelScore.text = "%d" % Globals.get_score()
	popup_centered()

func _on_ButtonRestart_pressed():
	get_tree().paused = false
	Globals.reset_score()
	get_tree().reload_current_scene()
