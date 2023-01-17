extends "Layer.gd"

onready var stone_id: int = tile_set.find_tile_by_name("Stone")
onready var tree_id: int = tile_set.find_tile_by_name("Tree")

## OVERRIDES
func obstructs_pathing() -> bool:
	return true

func obstructs_building() -> bool:
	return true
