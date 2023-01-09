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

func _on_PauseMenu_popup_hide():
	get_tree().paused = false
