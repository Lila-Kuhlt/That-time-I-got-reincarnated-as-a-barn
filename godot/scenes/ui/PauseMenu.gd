extends PopupDialog

var last_hide_time = -1

func try_show():
	popup_centered()
	
func _on_ButtonContinue_pressed():
	hide()

func _on_ButtonMuteMusic_toggled(button_pressed):
	AudioServer.set_bus_mute(1, not button_pressed)

func _on_ButtonMuteSound_toggled(button_pressed):
	AudioServer.set_bus_mute(2, not button_pressed)

func _on_PauseMenu_about_to_show():
	get_tree().paused = true
	$AudioStreamPlayer.play(0)

func _on_PauseMenu_popup_hide():
	# to prevent Pause button click from instantly re-opening pause menu
	yield(get_tree(), "idle_frame")
	
	$AudioStreamPlayer.stop()
	
	get_tree().paused = false

func _process(delta):
	if Input.is_action_just_pressed("pause"):
		if visible:
			hide()
		else:
			try_show()
