extends "Layer.gd"

onready var building_tower_id: int = tile_set.find_tile_by_name("Tower")
onready var building_plant_id: int = tile_set.find_tile_by_name("Plant")

## OVERRIDES
func clear_on_ready() -> bool:
	return true

func set_vtile(x: int, y: int, vtile):
	match vtile:
		wg.VTile.Barn: set_cell(x, y, building_plant_id)
		wg.VTile.FarmlandChili: set_cell(x, y, building_plant_id)
		wg.VTile.FarmlandTomato: set_cell(x, y, building_plant_id)
		wg.VTile.FarmlandPotato: set_cell(x, y, building_plant_id)
		wg.VTile.FarmlandAubergine: set_cell(x, y, building_plant_id)
