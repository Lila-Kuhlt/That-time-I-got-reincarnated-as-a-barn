extends "Layer.gd"

const MATERIAL: Material = preload("res://scenes/layers/LayerGroundWaterMaterial.tres")
const ParticlesFertilityRay = preload("res://scenes/particles/ParticlesFertilityRay.tscn")
const ParticlesFertilityRayScript = preload("res://scenes/particles/ParticlesFertilityRay.gd")

onready var farmland_id: int = tile_set.find_tile_by_name("FarmSoil")
onready var wasteland_id: int = tile_set.find_tile_by_name("Wasteland")
onready var water_id: int = tile_set.find_tile_by_name("Water")

func _ready():
	Settings.get_settings().connect("settings_changed", self, "_on_settings_changed")
	_on_settings_changed("shaders_on")

## PRIVATE
func _on_settings_changed(settings_name):
	if settings_name == "shaders_on":
		tile_set.tile_set_material(water_id, MATERIAL if  Settings.get_settings().shaders_on else null)

## PUBLIC

func improve_tile_around_tower(tower: Node2D, layers_that_must_be_empty := []) -> ParticlesFertilityRayScript:
	var pos_tower: Vector2 = world_to_map(tower.global_position)
	
	## STEP 1 ##
	# find all empty (grass) tiles in neighbors
	var candidates = []
	for pos in get_positions_in_radius(pos_tower, 1):
		var sth_on_layer := false
		for layer in layers_that_must_be_empty:
			if layer.get_cellv(pos) != TileMap.INVALID_CELL:
				sth_on_layer = true
				break
		if not sth_on_layer:
			candidates.append(pos)
	# if found: convert to farmland and return
	if candidates.size() > 0:
		var candidate = candidates[randi() % candidates.size()]
		return improve_tile_animated(candidate, farmland_id)
		
	## STEP 2 ##
	# find all adjacent wasteland tiles in neighbors
	candidates = []
	for pos in get_positions_in_radius(pos_tower, 1):
		if get_cellv(pos) == wasteland_id:
			candidates.append(pos)
	# if found: convert to grass and return
	if candidates.size() > 0:
		var candidate = candidates[randi() % candidates.size()]
		return improve_tile_animated(candidate, TileMap.INVALID_CELL)
	
	## STEP 3 ##
	var rg: float = ceil(tower.stats.RG / 32.0)
	var rg_sq: float = rg * rg

	# find all wasteland tiles in tower range
	candidates = []
	for pos in get_positions_in_radius(pos_tower, int(rg)):
		if pos.distance_squared_to(pos_tower) <= rg_sq:
			if get_cellv(pos) == wasteland_id:
				candidates.append(pos)
	# return if none found, select candidate otherwise
	if candidates.size() > 0:
		var candidate = candidates[randi() % candidates.size()]
		return improve_tile_animated(candidate, TileMap.INVALID_CELL)
	
	return null

func improve_tile_animated(map_pos: Vector2, cell: int) -> ParticlesFertilityRayScript:
	var particles: ParticlesFertilityRayScript = ParticlesFertilityRay.instance()
	get_parent().add_child(particles)
	particles.connect("fertility_ray_change_tile", self, "_improve_tile", [map_pos, cell], CONNECT_ONESHOT)
	particles.global_position = map_to_world(map_pos) + Vector2(16, 16)
	return particles
func _improve_tile(map_pos: Vector2, cell: int):
	set_cellv(map_pos, cell)
	update_bitmask_area(map_pos)
	
## OVERRIDES
func obstructs_building() -> bool:
	return true

func set_vtile(x: int, y: int, vtile):
	match vtile:
		wg.VTile.Farmland: set_cell(x, y, farmland_id)
		wg.VTile.FarmlandChili: set_cell(x, y, farmland_id)
		wg.VTile.FarmlandTomato: set_cell(x, y, farmland_id)
		wg.VTile.FarmlandPotato: set_cell(x, y, farmland_id)
		wg.VTile.FarmlandAubergine: set_cell(x, y, farmland_id)
		wg.VTile.Wasteland: set_cell(x, y, wasteland_id)
		wg.VTile.WastelandStone: set_cell(x, y, wasteland_id)
		wg.VTile.Pond: set_cell(x, y, water_id)
		wg.VTile.River: set_cell(x, y, water_id)
