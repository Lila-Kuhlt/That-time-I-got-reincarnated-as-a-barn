extends PopupDialog

onready var button_restart = $MarginContainer/VBoxContainer/HBoxContainer3/ButtonRestart

var last_hide_time = -1

func try_show():
	popup_centered()

func _on_ButtonContinue_pressed():
	hide()

func _on_PauseMenu_about_to_show():
	get_tree().paused = true
	$AudioStreamPlayer.play(0)

func _on_PauseMenu_popup_hide():
	# to prevent Pause button click from instantly re-opening pause menu
	yield(get_tree(), "idle_frame")

	$AudioStreamPlayer.stop()

	get_tree().paused = false

func _process(_delta):
	if Input.is_action_just_pressed("pause"):
		if visible:
			hide()
		else:
			try_show()


func _on_ButtonRestart_pressed():
	# abort if already pressed
	if not button_restart.pressed:
		button_restart.pressed = true
		return
	get_tree().paused = false
	yield(get_tree().create_timer(0.1), "timeout")
	get_tree().reload_current_scene()
