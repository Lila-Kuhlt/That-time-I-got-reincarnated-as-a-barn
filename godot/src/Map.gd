extends Node2D

# Fix to prevent weird clipping of Background and Ground Layer
const BG_LAYER_Y_OFFSET = 30 # in tiles

export var world_gen_enable: bool = false
export var debug_print_world: bool = false

export var grass_tile_ratio: float = 0.4
export var forest_margin: int = 20
export var tile_count_w: int = 31
export var tile_count_h: int = 31

onready var l_background: TileMap = $BackgroundLayer
onready var l_ground: TileMap = $GroundLayer
onready var l_foreground: TileMap = $ForegroundLayer
onready var l_building: TileMap = $BuildingLayer
onready var l_nav: TileMap = $NavigationLayer
onready var l_preview: TileMap = $BuildPreviewLayer

onready var wg = preload("res://src/WorldGen.gd")
onready var barn_preload = preload("res://scenes/towers/TowerBarn.tscn")
onready var spawner_preload = preload("res://scenes/Spawner.tscn")
onready var seed_preload = preload("res://scenes/plants/Seed.tscn")

onready var farmland_id: int = l_preview.tile_set.find_tile_by_name("FarmSoil")
onready var wasteland_id: int = l_ground.tile_set.find_tile_by_name("Wasteland")
onready var water_id: int = l_ground.tile_set.find_tile_by_name("Water")
onready var stone_id: int = l_foreground.tile_set.find_tile_by_name("Stone")
onready var tree_id: int = l_foreground.tile_set.find_tile_by_name("Tree")
onready var tile_nav_id:int = l_nav.tile_set.find_tile_by_name("NavigationHack")

func _ready():
	generate_bg_layer()
	l_building.clear()
	if world_gen_enable:
		randomize()
		l_ground.clear()
		l_foreground.clear()
		var gen = wg.Generator.new(tile_count_w, tile_count_h)
		gen.generate()
		if debug_print_world:
			gen.print_()
		for y in range(tile_count_h):
			for x in range(tile_count_w):
				set_vtile(x, y, gen.tiles[x + y * tile_count_w])
		for x in range(tile_count_w):
			var ex1 = gen.tiles[x]
			var ex2 = gen.tiles[x + (tile_count_h - 1) * tile_count_w]
			for y in range(forest_margin):
				set_vtile(x, -1 - y, ex1)
				set_vtile(x, tile_count_h + y, ex2)
		for y in range(tile_count_h):
			var ex1 = gen.tiles[y * tile_count_w]
			var ex2 = gen.tiles[y * tile_count_w + tile_count_w - 1]
			for x in range(forest_margin):
				set_vtile(-1 - x, y, ex1)
				set_vtile(tile_count_w + x, y, ex2)
		for rect in [[-forest_margin, -forest_margin], [tile_count_w, -forest_margin],
				[-forest_margin, tile_count_h], [tile_count_w, tile_count_h]]:
			for y in range(forest_margin):
				for x in range(forest_margin):
					l_foreground.set_cell(rect[0] + x, rect[1] + y, tree_id)
		var start = Vector2(-forest_margin, -forest_margin)
		var end = Vector2(tile_count_w, tile_count_h) - start
		l_ground.update_bitmask_region(start, end)
		l_foreground.update_bitmask_region(start, end)
	set_invisible_navigation_tiles()
	l_preview.clear()

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
	building_place_or_remove(map_pos)
	var barn = barn_preload.instance()
	barn.connect("tower_destroyed", Globals, "emit_signal", ["game_lost"])
	barn.position = snap_to_grid_center(map_to_world(map_pos))
	$Player.position = barn.position + Vector2(0, 14)
	add_child(barn)

func add_farmland(x: int, y: int, global_plant_type = null):
	l_ground.set_cell(x, y, farmland_id)
	if global_plant_type != null:
		var map_pos = Vector2(x, y)
		building_place_or_remove(map_pos)
		var seeed = preload("res://src/World.gd").ITEM_PRELOADS[global_plant_type].instance()
		seeed.position = snap_to_grid_center(map_to_world(map_pos))
		seeed.is_active = true
		get_parent().__plant_store[map_pos] = seeed
		add_child(seeed)

func add_spawner(x: int, y: int):
	var map_pos = Vector2(x, y)
	building_place_or_remove(map_pos)
	var spawner = spawner_preload.instance()
	spawner.type = randi() % len(Globals.EnemyType)
	spawner.position = snap_to_grid_center(map_to_world(map_pos))
	spawner.set_map(self)
	add_child(spawner)

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

func snap_to_grid_center(global : Vector2):
	var map_pos = (l_ground.world_to_map(global) * 32)
	map_pos += (l_ground.cell_size / 2)
	return map_pos

func building_place_or_remove(map_pos: Vector2, remove = false, add_navigation = false):
	if remove:
		l_building.set_cellv(map_pos, TileMap.INVALID_CELL)
		var has_obstacle := has_tile_collider(map_pos.x, map_pos.y)
		l_nav.set_cellv(map_pos, -1 if has_obstacle else tile_nav_id)
		l_nav.update_dirty_quadrants()
	else:
		var occupied = l_building.tile_set.find_tile_by_name("Occupied")
		l_building.set_cellv(map_pos, occupied)
		l_nav.set_cellv(map_pos, tile_nav_id if add_navigation else -1)
		l_nav.update_dirty_quadrants()

func can_place_building_at(world_pos: Vector2) -> bool:
	return can_place_building_at_map_pos(world_to_map(world_pos))

func can_place_building_at_map_pos(map_pos: Vector2) -> bool:
	if l_building.get_cellv(map_pos) != TileMap.INVALID_CELL:
		# position already has a building
		return false
	return not has_tile_collider(int(map_pos.x), int(map_pos.y))

func is_building_at(world_pos: Vector2) -> bool:
	var map_pos = l_building.world_to_map(world_pos)
	var tile_id = l_building.get_cellv(map_pos)

	return tile_id != TileMap.INVALID_CELL

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
		if can_place_building_at_map_pos(pos) and not is_ground_at(pos, "Wasteland"):
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

func remove_at(map_pos: Vector2):
	l_ground.set_cellv(map_pos, TileMap.INVALID_CELL)
