extends Node2D

signal tower_added(map_pos, tower)
signal plant_added(map_pos, plant)

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

var _barn = null
var _tower_tile_improvements := []

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
	# place forest
	for rect in [[-forest_margin, -forest_margin], [map_dim.x, -forest_margin],
			[-forest_margin, map_dim.y], [map_dim.x, map_dim.y]]:
		for y in range(forest_margin):
			for x in range(forest_margin):
				l_foreground.set_cell(rect[0] + x, rect[1] + y, l_foreground.tree_id)
	
	# update autotiles
	var start = Vector2(-forest_margin, -forest_margin)
	var end = Vector2(map_dim.x + forest_margin, map_dim.y + forest_margin)
	l_ground.update_bitmask_region(start, end)
	l_foreground.update_bitmask_region(start, end)
	
func set_vtile(x: int, y: int, vtile):
	for layer in all_layers:
		layer.set_vtile(x, y, vtile)
	match vtile:
		wg.VTile.Barn: add_barn(x, y)
		wg.VTile.FarmlandChili: add_plant(x, y, Globals.ItemType.PlantChili)
		wg.VTile.FarmlandTomato: add_plant(x, y, Globals.ItemType.PlantTomato)
		wg.VTile.FarmlandPotato: add_plant(x, y, Globals.ItemType.PlantPotato)
		wg.VTile.FarmlandAubergine: add_plant(x, y, Globals.ItemType.PlantAubergine)
		wg.VTile.Spawner: add_spawner(x, y)

func add_barn(x: int, y: int):
	var map_pos = Vector2(x, y)
	_barn = barn_preload.instance()
	_barn.position = map_to_world_center(map_pos)
	$Player.position = _barn.position + Vector2(0, 18)
	add_child(_barn)

func add_plant(x: int, y: int, global_plant_type):
	var map_pos = Vector2(x, y)
	var seeed = preload("res://scenes/screens/ScreenGame.gd").ITEM_PRELOADS[global_plant_type].instance()
	seeed.position = map_to_world_center(map_pos)
	seeed.is_active = true
	add_child(seeed)
	emit_signal("plant_added", map_pos, seeed)

func add_spawner(x: int, y: int):
	var map_pos = Vector2(x, y)
	var spawner = spawner_preload.instance()
	spawner.position = map_to_world_center(map_pos)
	spawner.set_map(self)
	add_child(spawner)

func world_to_map(world_pos: Vector2) -> Vector2:
	return l_building.world_to_map(world_pos)

func map_to_world(map_pos: Vector2) -> Vector2:
	return l_building.map_to_world(map_pos)

func map_to_world_center(map_pos: Vector2):
	return l_ground.map_to_world(map_pos) + l_ground.cell_size / 2.0

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


func has_farmable_ground(map_pos: Vector2) -> bool:
	return l_ground.get_cellv(map_pos) == l_ground.farmland_id
func has_waterwheel_suitable_ground(map_pos: Vector2) -> bool:
	return l_ground.get_cellv(map_pos) == l_ground.water_id
func has_tower_suitable_ground(map_pos: Vector2) -> bool:
	return l_ground.get_cellv(map_pos) != l_ground.wasteland_id and can_place_building_at(map_pos)

func update_preview_ground(world_pos: Vector2, radius: int):
	l_preview.clear()
	var map_pos := world_to_map(world_pos)
	set_ground_around_tower(map_pos, radius, false, l_preview)

func remove_preview_ground():
	l_preview.clear()

func remove_ground(map_pos: Vector2):
	l_ground.set_cellv(map_pos, TileMap.INVALID_CELL)

func _set_ground_around_tower_ony_by_one(queue: Array):
	if queue.size() == 0:
		return
	var pos = queue.pop_front()
	var particles = l_ground.improve_tile_animated(pos, l_ground.farmland_id)
	particles.connect("fertility_ray_next", self, "_set_ground_around_tower_ony_by_one", [queue], CONNECT_ONESHOT)

func set_ground_around_tower(map_pos: Vector2, radius: int, animate := false, layer := l_ground):
	if has_farmable_ground(map_pos):
		layer.set_cellv(map_pos, TileMap.INVALID_CELL)
	var changes := []
	for pos in layer.get_positions_in_radius(map_pos, radius):
		if can_place_building_at(pos) and l_ground.get_cellv(pos) != l_ground.wasteland_id:
			if animate:
				changes.append(pos)
			else:
				layer.set_cellv(pos, l_ground.farmland_id)
	if animate:
		changes.shuffle()
		_set_ground_around_tower_ony_by_one(changes)
	else:
		var rvec := Vector2(radius, radius)
		layer.update_bitmask_region(map_pos - rvec, map_pos + rvec)


func on_tower_destroyed(map_pos: Vector2):
	l_building.set_cellv(map_pos, l_building.INVALID_CELL)
	
func maybe_remove_farmland(map_pos: Vector2) -> bool:
	if not has_farmable_ground(map_pos):
		return false
	var has_building := false
	for pos in l_building.get_positions_in_radius(map_pos):
		if l_building.get_cellv(pos) == l_building.building_tower_id:
			has_building = true
			break
	if not has_building:
		l_ground.set_cellv(map_pos, l_ground.INVALID_CELL)
		l_ground.update_bitmask_area(map_pos)
		return true
	return false

func _on_tower_soul_received(tower):
	l_ground.improve_tile_around_tower(tower, [l_ground, l_building, l_foreground])
