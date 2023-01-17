extends VBoxContainer

func _on_ButtonMuteMusic_toggled(button_pressed):
	Settings.get_settings().music_on = button_pressed
	$HBoxContainer/ButtonMuteMusic.pressed = button_pressed

func _on_ButtonMuteSound_toggled(button_pressed):
	Settings.get_settings().sfx_on = button_pressed
	$HBoxContainer2/ButtonMuteSound.pressed = button_pressed

func _enter_tree():
	var settings := Settings.get_settings()
	_on_ButtonMuteMusic_toggled(settings.music_on)
	_on_ButtonMuteSound_toggled(settings.sfx_on)
