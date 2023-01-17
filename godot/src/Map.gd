extends Node2D

# Fix to prevent weird clipping of Background and Ground Layer
const BG_LAYER_Y_OFFSET = 30 # in tiles

export var world_gen_enable: bool = false
export var debug_print_world: bool = false

export var grass_tile_ratio: float = 0.4
export var forest_margin: int = 30
export var tile_count_w: int = 42
export var tile_count_h: int = 42

onready var l_background: TileMap = $BackgroundLayer
onready var l_ground: TileMap = $GroundLayer
onready var l_path: TileMap = $PathLayer
onready var l_foreground: TileMap = $ForegroundLayer
onready var l_building: TileMap = $BuildingLayer
onready var l_nav: TileMap = $NavigationLayer
onready var l_preview: TileMap = $BuildPreviewLayer

const wg = preload("res://src/WorldGen.gd")
const barn_preload = preload("res://scenes/towers/TowerBarn.tscn")
const spawner_preload = preload("res://scenes/Spawner.tscn")
const seed_preload = preload("res://scenes/plants/Seed.tscn")

onready var farmland_id: int = l_ground.tile_set.find_tile_by_name("FarmSoil")
onready var wasteland_id: int = l_ground.tile_set.find_tile_by_name("Wasteland")
onready var water_id: int = l_ground.tile_set.find_tile_by_name("Water")
onready var stone_id: int = l_foreground.tile_set.find_tile_by_name("Stone")
onready var tree_id: int = l_foreground.tile_set.find_tile_by_name("Tree")
onready var tile_nav_id: int = l_nav.tile_set.find_tile_by_name("NavigationHack")

onready var building_tower_id: int = l_building.tile_set.find_tile_by_name("Tower")
onready var building_plant_id: int = l_building.tile_set.find_tile_by_name("Plant")

const DIRS := [Vector2.UP, Vector2.RIGHT, Vector2.DOWN, Vector2.LEFT]
# describes when path tiles must point the inverted way
const PATH_INV_MAP = {
	# starts / ends
	0b1000 : 3,
	0b0100 : 0,
	0b0010 : 3,
	0b0001 : 0,
	
	# corners
	0b1100 : 3,
	0b0110 : 2,
	0b0011 : 1,
	0b1001 : 0,
	
	# straight
	0b0101 : 0,
	0b1010 : 3
}
var path_bits_to_tile_ids := {}
var path_bits_to_tile_ids_inv := {}
var path_tile_ids_to_bits := {}

var _barn = null

func _ready():
	generate_bg_layer()
	l_building.clear()
	for i in range(16):
		var tile_id = l_path.tile_set.find_tile_by_name(str(i))
		var tile_id_inv = l_path.tile_set.find_tile_by_name(str(i) + "_inv")
		path_bits_to_tile_ids[i] = tile_id
		path_bits_to_tile_ids_inv[i] = tile_id_inv
		path_tile_ids_to_bits[tile_id] = i
		path_tile_ids_to_bits[tile_id_inv] = i
		
	if world_gen_enable:
		randomize()
		l_ground.clear()
		l_foreground.clear()
		var gen = wg.Generator.new(tile_count_w, tile_count_h)
		gen.generate()
		if debug_print_world:
			gen.print_()

		# set tiles
		for y in range(tile_count_h):
			for x in range(tile_count_w):
				set_vtile(x, y, gen.get_tile(x, y))
		for x in range(tile_count_w):
			var ex1 = gen.get_tile(x, 0)
			var ex2 = gen.get_tile(x, tile_count_h - 1)
			for y in range(forest_margin):
				set_vtile(x, -1 - y, ex1)
				set_vtile(x, tile_count_h + y, ex2)
		for y in range(tile_count_h):
			var ex1 = gen.get_tile(0, y)
			var ex2 = gen.get_tile(tile_count_w - 1, y)
			for x in range(forest_margin):
				set_vtile(-1 - x, y, ex1)
				set_vtile(tile_count_w + x, y, ex2)
		for rect in [[-forest_margin, -forest_margin], [tile_count_w, -forest_margin],
				[-forest_margin, tile_count_h], [tile_count_w, tile_count_h]]:
			for y in range(forest_margin):
				for x in range(forest_margin):
					l_foreground.set_cell(rect[0] + x, rect[1] + y, tree_id)
		var start = Vector2(-forest_margin, -forest_margin)
		var end = Vector2(tile_count_w + forest_margin, tile_count_h + forest_margin)
		l_ground.update_bitmask_region(start, end)
		l_foreground.update_bitmask_region(start, end)
	
	set_invisible_navigation_tiles()
	l_preview.clear()
	
	get_tree().connect("idle_frame", self, "_on_first_frame", [], CONNECT_ONESHOT)

func _on_first_frame():
	# Needs to be done after all Nodes have been added
	create_chain(get_tree().get_nodes_in_group("Spawner"))
	
func set_vtile(x: int, y: int, vtile):
	match vtile:
		wg.VTile.Barn: add_barn(x, y)
		wg.VTile.Farmland: add_farmland(x, y)
		wg.VTile.FarmlandChili: add_farmland(x, y, Globals.ItemType.PlantChili)
		wg.VTile.FarmlandTomato: add_farmland(x, y, Globals.ItemType.PlantTomato)
		wg.VTile.FarmlandPotato: add_farmland(x, y, Globals.ItemType.PlantPotato)
		wg.VTile.FarmlandAubergine: add_farmland(x, y, Globals.ItemType.PlantAubergine)
		wg.VTile.Wasteland: l_ground.set_cell(x, y, wasteland_id)
		wg.VTile.WastelandStone:
			l_ground.set_cell(x, y, wasteland_id)
			l_foreground.set_cell(x, y, stone_id)
		wg.VTile.Grass: pass
		wg.VTile.GrassStone: l_foreground.set_cell(x, y, stone_id)
		wg.VTile.Tree: l_foreground.set_cell(x, y, tree_id)
		wg.VTile.Pond: l_ground.set_cell(x, y, water_id)
		wg.VTile.River: l_ground.set_cell(x, y, water_id)
		wg.VTile.Spawner: add_spawner(x, y)

func add_barn(x: int, y: int):
	var map_pos = Vector2(x, y)
	building_place_or_remove(map_pos, building_tower_id)
	_barn = barn_preload.instance()
	_barn.position = snap_to_grid_center(map_to_world(map_pos))
	$Player.position = _barn.position + Vector2(0, 18)
	get_parent().get_parent().barn_pos = map_pos
	add_child(_barn)

func add_farmland(x: int, y: int, global_plant_type = null):
	l_ground.set_cell(x, y, farmland_id)
	if global_plant_type != null:
		var map_pos = Vector2(x, y)
		building_place_or_remove(map_pos, building_plant_id)
		var seeed = preload("res://scenes/screens/ScreenGame.gd").ITEM_PRELOADS[global_plant_type].instance()
		seeed.position = snap_to_grid_center(map_to_world(map_pos))
		seeed.is_active = true
		# TODO this sucks
		get_parent().get_parent().__plant_store[map_pos] = seeed
		add_child(seeed)

func add_spawner(x: int, y: int):
	var map_pos = Vector2(x, y)
	# a spawner isn't actually a plant, this is just to register that there is a building
	building_place_or_remove(map_pos, building_plant_id)
	var spawner = spawner_preload.instance()
	spawner.position = snap_to_grid_center(map_to_world(map_pos))
	spawner.set_map(self)
	add_child(spawner)

func create_chain(spawners: Array):
	
	# setup loop vars
	var cur_target: Node2D = _barn
	var targets_in_order := [_barn]
	
	# create copy of spawner List and iterate until empty
	var spawners_left = spawners.duplicate()
	while spawners_left.size() > 0:
		# pop spawner that is closes to current target
		var spawner = get_spawner_with_min_dst_to(spawners_left, cur_target)
		
		if spawner == null:
			break
		
		spawners_left.erase(spawner)
		
		# tell this spawner of its target
		spawner._set_target(cur_target)
		
		# update loop vars
		targets_in_order.append(spawner)
		cur_target = spawner
	
	prints("Connected", targets_in_order.size()-1, "/", spawners.size(), "spawners")
	
	for i in range(targets_in_order.size()):
		var target = targets_in_order[i]
		# find prev and next in chain if there are, null otherwise
		var prev = targets_in_order[i - 1] if i > 0 else null
		var next = targets_in_order[i + 1] if i < targets_in_order.size() - 1 else null
		target.get_chain_link().set_neighs(prev, next)
	
	Globals.connect("game_started", targets_in_order[1], "activate_spawner", [targets_in_order[0]])

var _spawner_paths := []
func register_spawner_path(spawner_path):
	if spawner_path in _spawner_paths:
		return
	_spawner_paths.append(spawner_path)
	_update_spawner_paths()
func unregister_spawner_path(spawner_path):
	if not spawner_path in _spawner_paths:
		return
	_spawner_paths.erase(spawner_path)
	_update_spawner_paths()
	
func _update_spawner_paths():
	# Add Paths fresh
	l_path.clear()
	for spawner_path in _spawner_paths:
		_add_spawner_path(spawner_path)
	
	# Switch direction of path tiles
	for spawner_path in _spawner_paths:
		var path: Array = spawner_path.get_path_map_positions()
		var pos_last = null
		for i in range(path.size()):
			var pos_now = path[i]
			var pos_next = path[i + 1] if i + 1 < path.size() else null
			
			var dir_last = get_dir_id(pos_last, pos_now)
			var dir_next = get_dir_id(pos_now, pos_next)
			
			var bits = path_tile_ids_to_bits[l_path.get_cellv(pos_now)]

			if PATH_INV_MAP.has(bits):
				
				var dir_to_check = dir_next
				if pos_next == null:
					dir_to_check = dir_last
				
				if dir_to_check == PATH_INV_MAP[bits]:
					l_path.set_cellv(pos_now, path_bits_to_tile_ids_inv[bits])
			
			pos_last = pos_now
			
			

func _add_spawner_path(spawner_path):
	var last_map_pos = null
	for map_pos in spawner_path.get_path_map_positions():
		
		var dir_bit = get_dir_id(last_map_pos, map_pos)
		
		# get current tile bits (or 0 if new)
		var bits = 0
		var tile_id = l_path.get_cellv(map_pos)
		if tile_id != TileMap.INVALID_CELL:
			bits = path_tile_ids_to_bits[tile_id]
		
		# if this this is not the start
		if dir_bit != -1:
			var inv_dir_bit = ((dir_bit + 2) % 4)
			bits = bits | int(pow(2, inv_dir_bit))
			var last_bits = path_tile_ids_to_bits[l_path.get_cellv(last_map_pos)]
			last_bits = last_bits | int(pow(2, dir_bit))
			
			l_path.set_cellv(last_map_pos, path_bits_to_tile_ids[last_bits])
		
		l_path.set_cellv(map_pos, path_bits_to_tile_ids[bits])
		
		last_map_pos = map_pos

func get_dir_id(from, to):
	var dir_id = -1
	if from == null:
		dir_id = -1
	elif to == null:
		dir_id = -1
	else:
		for i in range(DIRS.size()):
			if from + DIRS[i] == to:
				dir_id = i
		assert(dir_id != -1, "Error, from and to must be direct neighbours")
	return dir_id

func get_spawner_with_min_dst_to(spawners, target):
	var cur_min_dst = INF
	var cur_target = null
	for spawner in spawners:
		spawner._agent.set_target_location(target.global_position)
		var dst = spawner._agent.distance_to_target()
		if dst == 0:
			continue

		if dst < cur_min_dst:
			cur_min_dst = dst
			cur_target = spawner
	return cur_target
	
func generate_bg_layer():
	l_background.clear()
	l_background.position.y = -32 * BG_LAYER_Y_OFFSET
	for y in range(-forest_margin, tile_count_h + forest_margin):
		for x in range(-forest_margin, tile_count_w + forest_margin):
			var id = int(randf() > grass_tile_ratio)
			l_background.set_cell(x, y + BG_LAYER_Y_OFFSET, 0, false, false, false, Vector2(id, 0))

func set_invisible_navigation_tiles():
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
			var has_obstacle := has_tile_collider(x, y)
			l_nav.set_cell(x, y, -1 if has_obstacle else tile_nav_id)

	# Force the navigation mesh to update immediately
	l_nav.update_dirty_quadrants()

func has_tile_collider(x: int, y: int) -> bool:
	# detects if the position has an obstacle (forest, rock, water, ...)
	for tile_map in [l_foreground, l_ground]:
		var tile_id = tile_map.get_cell(x, y)
		if (tile_id != -1 and
			tile_id in tile_map.tile_set.get_tiles_ids() and
			tile_map.tile_set.tile_get_shape_count(tile_id) > 0
		):
			return true
	return false

func world_to_map(world_pos: Vector2) -> Vector2:
	return l_building.world_to_map(world_pos)

func map_to_world(map_pos: Vector2) -> Vector2:
	return l_building.map_to_world(map_pos)

func snap_to_grid_center(global: Vector2):
	var map_pos = (l_ground.world_to_map(global) * 32)
	map_pos += (l_ground.cell_size / 2)
	return map_pos

func building_place_or_remove(map_pos: Vector2, building_tile_id := TileMap.INVALID_CELL):
	l_building.set_cellv(map_pos, building_tile_id)
	var has_obstacle := building_tile_id == building_tower_id or has_tile_collider(int(map_pos.x), int(map_pos.y))
#	# Don't make Towers blocking Enemy pathing for now, otherwise paths are buggy when player blocks it completelya
#	l_nav.set_cellv(map_pos, -1 if has_obstacle else tile_nav_id)
#	l_nav.update_dirty_quadrants()

func can_place_building_at(map_pos: Vector2) -> bool:
	if is_building_at(map_pos):
		# position already has a building
		return false
	return not has_tile_collider(int(map_pos.x), int(map_pos.y))

func is_building_at(map_pos: Vector2) -> bool:
	return l_building.get_cellv(map_pos) != TileMap.INVALID_CELL

func is_ground_at(map_pos: Vector2, ground: String) -> bool:
	return l_ground.get_cellv(map_pos) == l_ground.tile_set.find_tile_by_name(ground)

func get_positions_around_tower(map_pos: Vector2, radius: int):
	var positions = []
	var r2 := radius * 2 + 1
	for _dy in range(r2):
		for _dx in range(r2):
			var d := Vector2(_dx - radius, _dy - radius)
			if d != Vector2(0, 0):
				positions.append(map_pos + d)
	return positions

func set_ground_around_tower(map_pos: Vector2, radius: int, layer := l_ground):
	if is_farmland_at(map_pos):
		layer.set_cellv(map_pos, TileMap.INVALID_CELL)
	for pos in get_positions_around_tower(map_pos, radius):
		if can_place_building_at(pos) and not is_ground_at(pos, "Wasteland"):
			layer.set_cellv(pos, farmland_id)
	var rvec := Vector2(radius, radius)
	layer.update_bitmask_region(map_pos - rvec, map_pos + rvec)

func update_preview_ground(world_pos: Vector2, radius: int):
	l_preview.clear()
	var map_pos := world_to_map(world_pos)
	set_ground_around_tower(map_pos, radius, l_preview)

func remove_preview_ground():
	l_preview.clear()

func is_farmland_at(map_pos: Vector2) -> bool:
	return l_ground.get_cellv(map_pos) == farmland_id

func remove_ground(map_pos: Vector2):
	l_ground.set_cellv(map_pos, TileMap.INVALID_CELL)


# Convert empty grass Tile neighboring Tower to Farmland
# If no such spot exists:
# Convert wasteland in Tower range to grass
func _on_tower_killed_enemy(tower, _enemy):
	var pos_tower: Vector2 = l_ground.world_to_map(tower.global_position)

	# find all empty (grass) tiles in neighbors
	var candidates = []
	for pos in get_positions_around_tower(pos_tower, 1):
		if l_ground.get_cellv(pos) != TileMap.INVALID_CELL:
			continue # continue if sth on ground layer
		if l_building.get_cellv(pos) != TileMap.INVALID_CELL:
			continue # continue if sth on building layer
		if l_foreground.get_cellv(pos) != TileMap.INVALID_CELL:
			continue # continue if sth on foreground layer

		candidates.append(pos)

	# if found: convert to farmland and return
	if candidates.size() > 0:
		var candidate = candidates[randi() % candidates.size()]
		l_ground.set_cellv(candidate, farmland_id)
		l_ground.update_bitmask_area(candidate)
		return

	var rg: float = ceil(tower.stats.RG / 32.0)
	var rg_sq: float = rg * rg

	# find all wasteland tiles in tower range
	candidates = []
	for pos in get_positions_around_tower(pos_tower, int(rg)):
		if pos.distance_squared_to(pos_tower) <= rg_sq:
			if l_ground.get_cellv(pos) == wasteland_id:
				candidates.append(pos)

	# return if none found, select candidate otherwise
	if candidates.size() == 0:
		return
	var candidate = candidates[randi() % candidates.size()]

	l_ground.set_cellv(candidate, TileMap.INVALID_CELL)
	l_ground.update_bitmask_area(candidate)
