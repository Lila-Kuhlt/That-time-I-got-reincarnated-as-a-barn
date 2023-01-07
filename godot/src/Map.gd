extends Node2D

export var grass_tile_ratio: float = 0.4;
export var tile_count_w: int = 50;
export var tile_count_h: int = 30;

onready var l_background: TileMap = $BackgroundLayer
onready var l_ground: TileMap = $GroundLayer
onready var l_foreground: TileMap = $ForegroundLayer
onready var l_building: TileMap = $BuildingLayer
onready var l_nav: TileMap = $NavigationLayer

func _ready():
	generate_bg_layer()
	set_invisible_navigation_tiles()

func _process(delta):
	pass

func generate_bg_layer():
	l_background.clear()
	for y in range(tile_count_h):
		for x in range(tile_count_w):
			var id = int(randf() > grass_tile_ratio)
			l_background.set_cell(x, y, 0, false, false, false, Vector2(id, 0))

func set_invisible_navigation_tiles():
	
	var tile_nav_id = l_nav.tile_set.find_tile_by_name("NavigationHack")
	
	# Find the bounds of the tilemap (there is no 'size' property available)
	var bounds_min := Vector2.ZERO
	var bounds_max := Vector2.ZERO
	for pos in l_ground.get_used_cells() + l_foreground.get_used_cells():
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
			for tile_map in [l_foreground, l_ground]:
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
	var map_pos = (l_ground.world_to_map(global) * 32)
	map_pos += (l_ground.cell_size / 2)
	return map_pos

func tower_place(world_pos: Vector2, tower_name: String):
	var map_pos = l_building.world_to_map(world_pos)
	var tower_id = l_building.tile_set.find_tile_by_name(tower_name)
	print(map_pos, tower_id, tower_name)
	l_building.set_cellv(map_pos, tower_id)

func can_place_tower_at(world_pos: Vector2, tower):
	return true

func get_tower_at(world_pos: Vector2):
	var map_pos = l_building.world_to_map(world_pos)
	var tile_id = l_building.get_cellv(map_pos)
	
	if tile_id == TileMap.INVALID_CELL:
		return null
	
	var tower_name = l_building.tile_set.tile_get_name(tile_id)
	
	return tower_name
	
