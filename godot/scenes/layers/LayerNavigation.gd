extends "Layer.gd"

onready var tile_nav_id: int = tile_set.find_tile_by_name("NavigationHack")


## PUBLIC
func convert_colliders_to_navigation_tiles(layers):
	# Get all used cells of given layers
	var used_cells := []
	for layer in layers:
		used_cells.append_array(layer.get_used_cells())
	
	# Find the bounds of the tilemap (there is no 'size' property available)
	var bounds_min := Vector2.ZERO
	var bounds_max := Vector2.ZERO
	for pos in used_cells:
		if pos.x < bounds_min.x:
			bounds_min.x = int(pos.x)
		elif pos.x > bounds_max.x:
			bounds_max.x = int(pos.x)
		if pos.y < bounds_min.y:
			bounds_min.y = int(pos.y)
		elif pos.y > bounds_max.y:
			bounds_max.y = int(pos.y)

	# Iterate all cells within bounds
	for x in range(bounds_min.x, bounds_max.x):
		for y in range(bounds_min.y, bounds_max.y):
			var has_obstacle := false
			for layer in layers:
				if layer.has_tile_collider(x, y):
					has_obstacle = true
			set_cell(x, y, -1 if has_obstacle else tile_nav_id)
	
	update_dirty_quadrants()
			
## OVERRIDES
func clear_on_ready() -> bool:
	return true
