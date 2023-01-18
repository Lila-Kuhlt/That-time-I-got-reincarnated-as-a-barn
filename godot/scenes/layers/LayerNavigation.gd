extends "Layer.gd"

onready var tile_nav_id: int = tile_set.find_tile_by_name("NavigationHack")

## OVERRIDES
func clear_on_ready() -> bool:
	return true

func set_vtile(x: int, y: int, vtile):
	if vtile in [wg.VTile.GrassStone, wg.VTile.WastelandStone, wg.VTile.Pond, wg.VTile.River, wg.VTile.Tree]:
		set_cell(x, y, INVALID_CELL)
	else:
		set_cell(x, y, tile_nav_id)
