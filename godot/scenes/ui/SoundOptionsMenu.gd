extends VBoxContainer

func _on_ButtonMuteMusic_toggled(button_pressed):
	AudioServer.set_bus_mute(1, not button_pressed)

func _on_ButtonMuteSound_toggled(button_pressed):
	AudioServer.set_bus_mute(2, not button_pressed)
