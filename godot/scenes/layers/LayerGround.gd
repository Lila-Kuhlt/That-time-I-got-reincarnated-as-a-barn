extends "Layer.gd"

const MATERIAL: Material = preload("res://scenes/layers/LayerGroundWaterMaterial.tres")

onready var water_id = tile_set.find_tile_by_name("Water")

func _ready():
	Settings.get_settings().connect("settings_changed", self, "_on_settings_changed")
	_on_settings_changed("shaders_on")

func _on_settings_changed(settings_name):
	if settings_name == "shaders_on":
		tile_set.tile_set_material(water_id, MATERIAL if  Settings.get_settings().shaders_on else null)
