extends Resource

signal settings_changed(setting_name)

export(bool) var music_on := true setget _music_on
export(bool) var sfx_on := true setget _sfx_on

func _music_on(v):
	music_on = v
	AudioServer.set_bus_mute(1, not music_on)
	emit_signal("settings_changed", "music_on")

func _sfx_on(v):
	sfx_on = v
	AudioServer.set_bus_mute(2, not sfx_on)
	emit_signal("settings_changed", "_sfx_on")
