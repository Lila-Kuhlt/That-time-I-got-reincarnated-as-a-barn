extends TileMap

var map_dim: Vector2

func init_layer(map_dim: Vector2):
	self.map_dim = map_dim

## PUBLIC
func get_positions_in_radius(center: Vector2, radius: int = 1, add_center: bool = false) -> Array:
	var candidates := []
	center.x = int(center.x)
	center.y = int(center.y)
	for y in range(center.y - radius, center.y + radius + 1):
		for x in range(center.x - radius, center.x + radius + 1):
			var candidate = Vector2(x, y)
			if add_center or center != candidate:
				candidates.append(candidate)
	return candidates

func has_tile_collider(x: int, y: int) -> bool:
	# detects if the cell at given position has a collider
	var tile_id = get_cell(x, y)
	return (tile_id != INVALID_CELL and tile_id in tile_set.get_tiles_ids() and
		tile_set.tile_get_shape_count(tile_id) > 0)
		
func has_tile_colliderv(pos: Vector2) -> bool:
	return has_tile_collider(int(pos.x), int(pos.y))

## FUNCTIONS TO OVERRIDE
func clear_on_ready() -> bool:
	return false

func obstructs_pathing() -> bool:
	return false

func obstructs_building() -> bool:
	return false
