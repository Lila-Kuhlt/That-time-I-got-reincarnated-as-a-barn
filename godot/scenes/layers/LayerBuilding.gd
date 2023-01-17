extends "Layer.gd"

onready var building_tower_id: int = tile_set.find_tile_by_name("Tower")
onready var building_plant_id: int = tile_set.find_tile_by_name("Plant")

## OVERRIDES
func clear_on_ready() -> bool:
	return true
