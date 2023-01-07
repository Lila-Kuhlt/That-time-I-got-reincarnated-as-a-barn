extends Node2D

export var grass_tile_ratio: float = 0.4;
export var tile_count_w: int = 50;
export var tile_count_h: int = 30;

onready var bg_layer = $BackgroundLayer;
onready var bld_layer = $BuildLayer;

func _ready():
	generate_bg_layer()
	set_invisible_navigation_tiles()

func _process(delta):
	pass

func generate_bg_layer():
	bg_layer.clear()
	for y in range(tile_count_h):
		for x in range(tile_count_w):
			var id = int(randf() > grass_tile_ratio)
			bg_layer.set_cell(x, y, 0, false, false, false, Vector2(id, 0))

func set_invisible_navigation_tiles():
	
	var l_ground: TileMap = $GroundLayer
	var l_build: TileMap = $BuildLayer
	var l_nav: TileMap = $NavigationLayer
	var tile_nav_id = l_nav.tile_set.find_tile_by_name("NavigationHack")
	
	# Find the bounds of the tilemap (there is no 'size' property available)
	var bounds_min := Vector2.ZERO
	var bounds_max := Vector2.ZERO
	for pos in l_ground.get_used_cells() + l_build.get_used_cells():
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
			
			var has_obstacle = false
			# Check both maps for colliders
			for tile_map in [l_build, l_ground]:
				var tile_id = tile_map.get_cell(x, y)
				if (tile_id != -1 and
					tile_id in tile_map.tile_set.get_tiles_ids() and
					tile_map.tile_set.tile_get_shape_count(tile_id) > 0
				):
					has_obstacle = true
					
			l_nav.set_cell(x, y, -1 if has_obstacle else tile_nav_id)

	# Force the navigation mesh to update immediately
	l_nav.update_dirty_quadrants()

func world_to_map_pos(global : Vector2):
	var map_pos = (bld_layer.world_to_map(global) * 32)
	map_pos += (bld_layer.cell_size / 2)
	return map_pos
