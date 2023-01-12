extends PanelContainer

onready var button_restart =  $MarginContainer/VBoxContainer/HBoxContainer2/ButtonRestart

func _ready():
	Globals.connect("game_lost", self, "try_show")
	visible = false

func try_show():
	get_tree().paused = true
	$MarginContainer/VBoxContainer/HBoxContainer/LabelScore.text = "%d" % Globals.get_score()
	visible = true

func _on_ButtonRestart_pressed():
	# abort if already pressed
	if not button_restart.pressed:
		button_restart.pressed = true
		return
	get_tree().paused = false
	ScreenLoader.reload_current_scene(true)
