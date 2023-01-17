extends Node2D



export var world_gen_enable: bool = false
export var debug_print_world: bool = false


export var forest_margin: int = 30
export var map_dim = Vector2(42, 42)

onready var l_background: TileMap = $BackgroundLayer
onready var l_ground: TileMap = $GroundLayer
onready var l_path: TileMap = $PathLayer
onready var l_foreground: TileMap = $ForegroundLayer
onready var l_building: TileMap = $BuildingLayer
onready var l_nav: TileMap = $NavigationLayer
onready var l_preview: TileMap = $BuildPreviewLayer
onready var all_layers := [l_background, l_ground, l_path, l_foreground, l_building, l_nav, l_preview]

const wg = preload("res://src/WorldGen.gd")
const barn_preload = preload("res://scenes/towers/TowerBarn.tscn")
const spawner_preload = preload("res://scenes/Spawner.tscn")
const seed_preload = preload("res://scenes/plants/Seed.tscn")

# to keep map materials/shaders save
var material_path_map: Material
var material_water_tile: Material

var _barn = null

func _ready():
	# Make sure map dimensions are integers
	map_dim.x = int(map_dim.x)
	map_dim.y = int(map_dim.y)
	
	# Init all layers
	for layer in all_layers:
		if layer.clear_on_ready():
			layer.clear()
		layer.init_layer(map_dim)
	
	# Generate background
	l_background.generate_background(forest_margin)
	
	# Generate map
	if world_gen_enable:
		generate_map()
	
	# Set invisible navigation helper tiles
	var relevant_layers := []
	for layer in all_layers:
		if layer.obstructs_pathing():
			relevant_layers.append(layer)
	l_nav.convert_colliders_to_navigation_tiles(relevant_layers)
	
	# Await first frame
	get_tree().connect("idle_frame", self, "_on_first_frame", [], CONNECT_ONESHOT)
	
	
func _on_first_frame():
	# Needs to be done after all Nodes have been added
	$ChainManager.create_chain(_barn, get_tree().get_nodes_in_group("Spawner"))
	
func generate_map():
	randomize()
	l_ground.clear()
	l_foreground.clear()
	var gen = wg.Generator.new(map_dim.x, map_dim.y)
	gen.generate()
	if debug_print_world:
		gen.print_()

	# set tiles
	for y in range(map_dim.y):
		for x in range(map_dim.x):
			set_vtile(x, y, gen.get_tile(x, y))
	for x in range(map_dim.x):
		var ex1 = gen.get_tile(x, 0)
		var ex2 = gen.get_tile(x, map_dim.y - 1)
		for y in range(forest_margin):
			set_vtile(x, -1 - y, ex1)
			set_vtile(x, map_dim.y + y, ex2)
	for y in range(map_dim.y):
		var ex1 = gen.get_tile(0, y)
		var ex2 = gen.get_tile(map_dim.x - 1, y)
		for x in range(forest_margin):
			set_vtile(-1 - x, y, ex1)
			set_vtile(map_dim.x + x, y, ex2)
	for rect in [[-forest_margin, -forest_margin], [map_dim.x, -forest_margin],
			[-forest_margin, map_dim.y], [map_dim.x, map_dim.y]]:
		for y in range(forest_margin):
			for x in range(forest_margin):
				l_foreground.set_cell(rect[0] + x, rect[1] + y, l_foreground.tree_id)
	var start = Vector2(-forest_margin, -forest_margin)
	var end = Vector2(map_dim.x + forest_margin, map_dim.y + forest_margin)
	l_ground.update_bitmask_region(start, end)
	l_foreground.update_bitmask_region(start, end)
	
func set_vtile(x: int, y: int, vtile):
	match vtile:
		wg.VTile.Barn: add_barn(x, y)
		wg.VTile.Farmland: add_farmland(x, y)
		wg.VTile.FarmlandChili: add_farmland(x, y, Globals.ItemType.PlantChili)
		wg.VTile.FarmlandTomato: add_farmland(x, y, Globals.ItemType.PlantTomato)
		wg.VTile.FarmlandPotato: add_farmland(x, y, Globals.ItemType.PlantPotato)
		wg.VTile.FarmlandAubergine: add_farmland(x, y, Globals.ItemType.PlantAubergine)
		wg.VTile.Wasteland: l_ground.set_cell(x, y, l_ground.wasteland_id)
		wg.VTile.WastelandStone:
			l_ground.set_cell(x, y, l_ground.wasteland_id)
			l_foreground.set_cell(x, y, l_foreground.stone_id)
		wg.VTile.Grass: pass
		wg.VTile.GrassStone: l_foreground.set_cell(x, y, l_foreground.stone_id)
		wg.VTile.Tree: l_foreground.set_cell(x, y, l_foreground.tree_id)
		wg.VTile.Pond: l_ground.set_cell(x, y, l_ground.water_id)
		wg.VTile.River: l_ground.set_cell(x, y, l_ground.water_id)
		wg.VTile.Spawner: add_spawner(x, y)

func add_barn(x: int, y: int):
	var map_pos = Vector2(x, y)
	building_place_or_remove(map_pos, l_building.building_tower_id)
	_barn = barn_preload.instance()
	_barn.position = snap_to_grid_center(map_to_world(map_pos))
	$Player.position = _barn.position + Vector2(0, 18)
	get_parent().get_parent().barn_pos = map_pos
	add_child(_barn)

func add_farmland(x: int, y: int, global_plant_type = null):
	l_ground.set_cell(x, y, l_ground.farmland_id)
	if global_plant_type != null:
		var map_pos = Vector2(x, y)
		building_place_or_remove(map_pos, l_building.building_plant_id)
		var seeed = preload("res://scenes/screens/ScreenGame.gd").ITEM_PRELOADS[global_plant_type].instance()
		seeed.position = snap_to_grid_center(map_to_world(map_pos))
		seeed.is_active = true
		# TODO this sucks
		get_parent().get_parent().__plant_store[map_pos] = seeed
		add_child(seeed)

func add_spawner(x: int, y: int):
	var map_pos = Vector2(x, y)
	# a spawner isn't actually a plant, this is just to register that there is a building
	building_place_or_remove(map_pos, l_building.building_plant_id)
	var spawner = spawner_preload.instance()
	spawner.position = snap_to_grid_center(map_to_world(map_pos))
	spawner.set_map(self)
	add_child(spawner)

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

func can_place_building_at(map_pos: Vector2) -> bool:
	# position already has a building
	if is_building_at(map_pos):
		return false
	
	# check layer if there are any colliders
	var has_collider := false
	for layer in all_layers:
		if layer.obstructs_building() and layer.has_tile_colliderv(map_pos):
			has_collider = true
			break
	return not has_collider

func is_building_at(map_pos: Vector2) -> bool:
	return l_building.get_cellv(map_pos) != TileMap.INVALID_CELL

func is_ground_at(map_pos: Vector2, ground: String) -> bool:
	return l_ground.get_cellv(map_pos) == l_ground.tile_set.find_tile_by_name(ground)

func set_ground_around_tower(map_pos: Vector2, radius: int, layer := l_ground):
	if is_farmland_at(map_pos):
		layer.set_cellv(map_pos, TileMap.INVALID_CELL)
	for pos in layer.get_positions_in_radius(map_pos, radius):
		if can_place_building_at(pos) and not is_ground_at(pos, "Wasteland"):
			layer.set_cellv(pos, l_ground.farmland_id)
	var rvec := Vector2(radius, radius)
	layer.update_bitmask_region(map_pos - rvec, map_pos + rvec)

func update_preview_ground(world_pos: Vector2, radius: int):
	l_preview.clear()
	var map_pos := world_to_map(world_pos)
	set_ground_around_tower(map_pos, radius, l_preview)

func remove_preview_ground():
	l_preview.clear()

func is_farmland_at(map_pos: Vector2) -> bool:
	return l_ground.get_cellv(map_pos) == l_ground.farmland_id

func remove_ground(map_pos: Vector2):
	l_ground.set_cellv(map_pos, TileMap.INVALID_CELL)


# Convert empty grass Tile neighboring Tower to Farmland
# If no such spot exists:
# Convert wasteland in Tower range to grass
func _on_tower_killed_enemy(tower, _enemy):
	var pos_tower: Vector2 = l_ground.world_to_map(tower.global_position)

	# find all empty (grass) tiles in neighbors
	var candidates = []
	for pos in l_ground.get_positions_in_radius(pos_tower, 1):
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
		l_ground.set_cellv(candidate, l_ground.farmland_id)
		l_ground.update_bitmask_area(candidate)
		return

	var rg: float = ceil(tower.stats.RG / 32.0)
	var rg_sq: float = rg * rg

	# find all wasteland tiles in tower range
	candidates = []
	for pos in l_ground.get_positions_in_radius(pos_tower, int(rg)):
		if pos.distance_squared_to(pos_tower) <= rg_sq:
			if l_ground.get_cellv(pos) == l_ground.wasteland_id:
				candidates.append(pos)

	# return if none found, select candidate otherwise
	if candidates.size() == 0:
		return
	var candidate = candidates[randi() % candidates.size()]

	l_ground.set_cellv(candidate, TileMap.INVALID_CELL)
	l_ground.update_bitmask_area(candidate)
