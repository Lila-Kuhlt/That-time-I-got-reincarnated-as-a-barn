extends "Layer.gd"

const MATERIAL: Material = preload("res://scenes/layers/LayerGroundWaterMaterial.tres")

onready var farmland_id: int = tile_set.find_tile_by_name("FarmSoil")
onready var wasteland_id: int = tile_set.find_tile_by_name("Wasteland")
onready var water_id: int = tile_set.find_tile_by_name("Water")

func _ready():
	Settings.get_settings().connect("settings_changed", self, "_on_settings_changed")
	_on_settings_changed("shaders_on")

## PRIVATE
func _on_settings_changed(settings_name):
	if settings_name == "shaders_on":
		tile_set.tile_set_material(water_id, MATERIAL if  Settings.get_settings().shaders_on else null)

## OVERRIDES
func obstructs_pathing() -> bool:
	return true

func obstructs_building() -> bool:
	return true
