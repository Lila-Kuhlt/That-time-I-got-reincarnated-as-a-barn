extends "Layer.gd"

const MATERIAL: Material = preload("res://scenes/layers/LayerPathMapMaterial.tres")

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

var _spawner_paths := []

func _ready():
	Settings.get_settings().connect("settings_changed", self, "_on_settings_changed")
	_on_settings_changed("shaders_on")
	
	# Initialize path tile helper data structures
	for i in range(16):
		var tile_id = tile_set.find_tile_by_name(str(i))
		var tile_id_inv = tile_set.find_tile_by_name(str(i) + "_inv")
		path_bits_to_tile_ids[i] = tile_id
		path_bits_to_tile_ids_inv[i] = tile_id_inv
		path_tile_ids_to_bits[tile_id] = i
		path_tile_ids_to_bits[tile_id_inv] = i

## PRIVATE
func _on_settings_changed(settings_name):
	if settings_name == "shaders_on":
		material = MATERIAL if  Settings.get_settings().shaders_on else null

func _add_spawner_path(spawner_path):
	var last_map_pos = null
	for map_pos in spawner_path.get_path_map_positions():
		
		var dir_bit = _get_dir_id(last_map_pos, map_pos)
		
		# get current tile bits (or 0 if new)
		var bits = 0
		var tile_id = get_cellv(map_pos)
		if tile_id != TileMap.INVALID_CELL:
			bits = path_tile_ids_to_bits[tile_id]
		
		# if this this is not the start
		if dir_bit != -1:
			var inv_dir_bit = ((dir_bit + 2) % 4)
			bits = bits | int(pow(2, inv_dir_bit))
			var last_bits = path_tile_ids_to_bits[get_cellv(last_map_pos)]
			last_bits = last_bits | int(pow(2, dir_bit))
			
			set_cellv(last_map_pos, path_bits_to_tile_ids[last_bits])
		
		set_cellv(map_pos, path_bits_to_tile_ids[bits])
		
		last_map_pos = map_pos

func _get_dir_id(from, to):
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
	
func _update_spawner_paths():
	# Add Paths fresh
	clear()
	for spawner_path in _spawner_paths:
		_add_spawner_path(spawner_path)
	
	# Switch direction of path tiles
	for spawner_path in _spawner_paths:
		var path: Array = spawner_path.get_path_map_positions()
		var pos_last = null
		for i in range(path.size()):
			var pos_now = path[i]
			var pos_next = path[i + 1] if i + 1 < path.size() else null
			
			var dir_last = _get_dir_id(pos_last, pos_now)
			var dir_next = _get_dir_id(pos_now, pos_next)
			
			var bits = path_tile_ids_to_bits[get_cellv(pos_now)]

			if PATH_INV_MAP.has(bits):
				
				var dir_to_check = dir_next
				if pos_next == null:
					dir_to_check = dir_last
				
				if dir_to_check == PATH_INV_MAP[bits]:
					set_cellv(pos_now, path_bits_to_tile_ids_inv[bits])
			
			pos_last = pos_now
			
## PUBLIC
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
	
## OVERRIDES
func clear_on_ready() -> bool:
	return true
