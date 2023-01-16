extends PanelContainer

onready var button_restart =  $MarginContainer/VBoxContainer/HBoxContainer2/ButtonRestart

export(String) var title_text_won = "You won."
export(String) var title_text_lost = "You lost."

func _ready():
	Globals.connect("game_lost", self, "show", [false])
	Globals.connect("game_won", self, "show", [true])
	visible = false

func show(won := false):
	get_tree().paused = true
	$MarginContainer/VBoxContainer/Label.text = title_text_won if won else title_text_lost
	$MarginContainer/VBoxContainer/HBoxContainer/LabelScore.text = "%d" % Globals.get_score()
	visible = true

func _on_ButtonRestart_pressed():
	# abort if already pressed
	if not button_restart.pressed:
		button_restart.pressed = true
		return
	get_tree().paused = false
	ScreenLoader.reload_current_scene(true)
