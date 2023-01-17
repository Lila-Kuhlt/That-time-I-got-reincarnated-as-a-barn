extends "Layer.gd"

const MATERIAL: Material = preload("res://scenes/layers/LayerPathMapMaterial.tres")

func _ready():
	Settings.get_settings().connect("settings_changed", self, "_on_settings_changed")
	_on_settings_changed("shaders_on")

func _on_settings_changed(settings_name):
	if settings_name == "shaders_on":
		material = MATERIAL if  Settings.get_settings().shaders_on else null
