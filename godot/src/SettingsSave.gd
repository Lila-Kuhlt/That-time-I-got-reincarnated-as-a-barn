extends Resource

signal settings_changed(setting_name)

export(bool) var music_on := true setget _music_on
export(bool) var sfx_on := true setget _sfx_on
export(bool) var shaders_on := true setget _shaders_on

func _music_on(v):
	if music_on == v:
		return
	music_on = v
	AudioServer.set_bus_mute(1, not music_on)
	emit_signal("settings_changed", "music_on")

func _sfx_on(v):
	if sfx_on == v:
		return
	sfx_on = v
	AudioServer.set_bus_mute(2, not sfx_on)
	emit_signal("settings_changed", "_sfx_on")

func _shaders_on(v):
	if shaders_on == v:
		return
	shaders_on = v
	emit_signal("settings_changed", "shaders_on")
