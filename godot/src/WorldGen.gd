extends Node

# virtual tile
enum VTile {
	Barn,
	Farmland,
	FarmlandChili,
	FarmlandTomato,
	FarmlandPotato,
	FarmlandAubergine,
	Wasteland,
	WastelandStone,
	Grass,
	GrassStone,
	Tree,
	Pond,
	River,
	Spawner
}

const DEBUG_VTILE_MAP := {
	VTile.Barn             : "BB",
	VTile.Farmland         : "ff",
	VTile.FarmlandChili    : "FF",
	VTile.FarmlandTomato   : "FF",
	VTile.FarmlandPotato   : "FF",
	VTile.FarmlandAubergine: "FF",
	VTile.Wasteland        : "..",
	VTile.WastelandStone   : "ww",
	VTile.Grass            : "::",
	VTile.GrassStone       : "gg",
	VTile.Tree             : "TT",
	VTile.Pond             : "PP",
	VTile.River            : "RR",
	VTile.Spawner          : "##",
	null                   : "??"
}

# y-axis represents distance to map center
# x-axis represents humidity/fertility
const GENERATION_MAP := [
	[ VTile.Grass,			VTile.Grass,				VTile.Grass,				VTile.Grass, 		VTile.Grass, 		VTile.Pond ],
	[ VTile.WastelandStone,	VTile.Wasteland,			VTile.Grass,				VTile.Grass, 		VTile.Tree, 			VTile.Pond ],
	[ VTile.WastelandStone,	VTile.Wasteland,			VTile.Wasteland,			VTile.Wasteland, 	VTile.Tree, 			VTile.Pond ],
	[ VTile.WastelandStone,	VTile.WastelandStone,	VTile.WastelandStone,	VTile.Wasteland, 	VTile.Wasteland, 	VTile.Grass ],
	[ VTile.WastelandStone,	VTile.WastelandStone,	VTile.Wasteland,			VTile.Wasteland,		VTile.Wasteland, 	VTile.Tree ],
	[ VTile.WastelandStone,	VTile.Wasteland,			VTile.Tree,				VTile.Tree,			VTile.Tree, 			VTile.Tree ]
]
const GENERATION_MAP_DIMS := Vector2(6, 6)

const POND_THREASHOLD := 0.5

const RIVER_BLOCKER := [
	VTile.Barn,
	VTile.Farmland,
	VTile.FarmlandChili,
	VTile.FarmlandTomato,
	VTile.FarmlandPotato,
	VTile.FarmlandAubergine,
	VTile.GrassStone,
	VTile.WastelandStone,
	VTile.Spawner
]

const PLANTED_FARMLANDS := [
	VTile.FarmlandChili,
	VTile.FarmlandTomato,
	VTile.FarmlandPotato,
	VTile.FarmlandAubergine
]

const WALKABLE := [VTile.Grass, VTile.Wasteland]

const INDESTRUCTIBLE := [VTile.Spawner, VTile.Barn]

const NEIGHS_DIRECT = [Vector2(0, -1), Vector2(1, 0), Vector2(0, 1), Vector2(-1, 0)]
const NEIGHS_DIAGONAL = [Vector2(-1, -1), Vector2(1, -1), Vector2(-1, 1), Vector2(1, 1)]
const NEIGHS = NEIGHS_DIRECT + NEIGHS_DIAGONAL

const SMALL_WEIGHT = 0.000001
const LARGE_WEIGHT = 100000.0

# used for river generation
class DrunkAStar:
	extends AStar2D

	var alcohol_level: float
	var border_attraction: float
	var width: int
	var height: int

	func _init(w: int, h: int, _alcohol_level := 2.0, _border_attraction := 1.3):
		self.alcohol_level = _alcohol_level
		self.border_attraction = _border_attraction
		self.width = w
		self.height = h

	func _compute_cost(u, v):
		var vpos = get_point_position(v)
		var cost = (get_point_position(u) - vpos).length() + randf() * alcohol_level
		var dif = max(max(vpos.x, self.width - vpos.x), max(vpos.y, self.height - vpos.y))
		cost += dif * border_attraction
		return cost

	func _estimate_cost(from_id, to_id):
		return _compute_cost(from_id, to_id)

# ⚡ 🚀 Blazingly fast access times ⚡ 🚀
#
# Usage:
#  var gen = Generator.new(width, height, seed)
#  gen.generate()
#  	 access gen.tiles (one dimensional array of vtiles)
class Generator:
	var width: int
	var height: int

	# array of VTiles
	var tiles: Array

	var fertility_noise: OpenSimplexNoise
	var distance_noise: OpenSimplexNoise

	var drunk_star: DrunkAStar
	var path_star: AStar2D
	var size: float
	var centerv: Vector2
	var center: Array

	var river_dist_min := 3
	var river_spawn_protection := 5.0
	var spawner_count: int
	var spawner_min_distance := 16.0

	func _init(_width: int, _height: int, saed = null,
			ds_alcohol_level := 1.3, border_attraction := 1.7,
			spawners_per_tile := 0.004):
		self.tiles = []
		self.width = _width
		self.height = _height
		self.spawner_count = int(width * height * spawners_per_tile)

		self.size = float(max(width, height))
		self.center = [width >> 1, height >> 1]
		self.centerv = Vector2(center[0], center[1])

		fertility_noise = OpenSimplexNoise.new()
		fertility_noise.seed = saed if saed != null else randi()
		fertility_noise.period = 3.5
		fertility_noise.persistence = 0.75
		fertility_noise.octaves = 2

		distance_noise = OpenSimplexNoise.new()
		distance_noise.seed = fertility_noise.seed ^ 0x23A49
		distance_noise.lacunarity = 3.0
		distance_noise.period = 8
		distance_noise.persistence = 0.5
		distance_noise.octaves = 3

		drunk_star = DrunkAStar.new(width, height, ds_alcohol_level, border_attraction)
		path_star = AStar2D.new()

	func set_tile(x: int, y: int, tile):
		tiles[get_index(x, y)] = tile

	func set_tilev(pos: Vector2, tile):
		set_tile(pos.x, pos.y, tile)

	func get_tile(x: int, y: int):
		return tiles[get_index(x, y)]

	func get_index(x: int, y: int) -> int:
		return y * width + x

	func resolve_index(index: int) -> Array:
		return [index % width, index / width]

	func in_bounds(x: int, y: int) -> bool:
		return not (x < 0 or y < 0 or x >= width or y >= height)

	## Fills the edges of the map with trees.
	func fill_edges():
		for y in range(height):
			set_tile(0, y, VTile.Tree)
			set_tile(width - 1, y, VTile.Tree)

		for x in range(width):
			set_tile(x, 0, VTile.Tree)
			set_tile(x, height - 1, VTile.Tree)

	## Places the barn at the center of the map.
	func place_barn():
		var pos := centerv
		set_tilev(pos, VTile.Barn)

		# Place empty farmlands on direct neighbors
		for rel in NEIGHS_DIRECT:
			set_tilev(pos + rel, VTile.Farmland)

		# Place farmlands with seeds on diagonal neighbors
		for i in range(4):
			set_tilev(pos + NEIGHS_DIAGONAL[i], PLANTED_FARMLANDS[i])

	func is_valid_river_pos(x: int, y: int) -> bool:
		var dist = Vector2(x, y).distance_to(centerv)
		return ((not get_tile(x, y) in RIVER_BLOCKER)
			and dist >= river_spawn_protection)

	func setup_drunk_star():
		for y in range(height):
			for x in range(width):
				if is_valid_river_pos(x, y):
					var id = get_index(x, y)
					drunk_star.add_point(id, Vector2(x, y))

					# connect with neighbors
					for offset in [[-1, 0], [0, -1]]:
						var nx = x + offset[0]
						var ny = y + offset[1]
						var neighbor := get_index(nx, ny)
						if in_bounds(nx, ny) and drunk_star.has_point(neighbor):
							drunk_star.connect_points(neighbor, id)

	func river_target_from_source(x: int, y: int) -> Array:
		var candidates := []
		for point in drunk_star.get_points():
			var point_a2 = resolve_index(point)
			if abs(point_a2[0] - x) >= river_dist_min and abs(point_a2[1] - y) >= river_dist_min:
				candidates.append(point_a2)
		return candidates[randi() % candidates.size()]

	func draw_river():
		var start_a2: Array = [
			[randi() % width, 0],
			[randi() % width, height - 1],
			[0, randi() % height],
			[width - 1, randi() % height]
		][randi() % 4]
		var target_a2 := river_target_from_source(start_a2[0], start_a2[1])
		var start_id = get_index(start_a2[0], start_a2[1])
		var target_id = get_index(target_a2[0], target_a2[1])
		for point in drunk_star.get_point_path(start_id, target_id):
			set_tile(int(point.x), int(point.y), VTile.River)

	func setup_path_star():
		# path_star connects two points going through a minimal amount of non-walkable tiles
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				var tile = get_tile(x, y)
				if tile in INDESTRUCTIBLE:
					continue
				var id := get_index(x, y)
				var weight := SMALL_WEIGHT if tile in WALKABLE else LARGE_WEIGHT
				path_star.add_point(id, Vector2(x, y), weight)

				# connect with neighbors
				for offset in [[-1, 0], [0, -1]]:
					var nx = x + offset[0]
					var ny = y + offset[1]
					var neighbor := get_index(nx, ny)
					if in_bounds(nx, ny) and path_star.has_point(neighbor):
						path_star.connect_points(neighbor, id)

	func flood_fill(x: int, y: int) -> Dictionary:
		var area := {}
		var stack := [[x, y]]
		while not stack.empty():
			var pos = stack.pop_back()
			var px = pos[0]
			var py = pos[1]
			area[get_index(px, py)] = null
			for nei in NEIGHS_DIRECT:
				var nx = px + nei.x
				var ny = py + nei.y
				if in_bounds(nx, ny) and get_tile(nx, ny) in WALKABLE and not get_index(nx, ny) in area:
					stack.push_back([nx, ny])
		return area

	func get_neighbor_set(area: Dictionary) -> Dictionary:
		var neis: Dictionary = {}
		for pos in area.keys():
			var p := resolve_index(pos)
			var px: int = p[0]
			var py: int = p[1]
			for d in NEIGHS_DIRECT:
				var x: int = px + d[0]
				var y: int = py + d[1]
				if not in_bounds(x, y):
					continue
				var n := get_index(x, y)
				if not (n in area):
					neis[n] = null
		return neis

	func connect_areas() -> bool:
		# choose walkable tile and floodfill
		var xy = null
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				if get_tile(x, y) in WALKABLE:
					xy = [x, y]
					break
			if xy != null:
				break
		if xy == null:
			return false
		var start_id = get_index(xy[0], xy[1])
		var area := flood_fill(xy[0], xy[1])

		# merge neighbor set until finding a walkable tile
		area.merge(get_neighbor_set(area))
		var target_id = null
		while target_id == null:
			var neis := get_neighbor_set(area)
			if neis.empty():
				return false
			for nei in neis:
				if tiles[nei] in WALKABLE:
					target_id = nei
					break
			area.merge(neis)

		# replace tiles so that the two components are path connected
		for point in path_star.get_point_path(start_id, target_id):
			var x = int(point.x)
			var y = int(point.y)
			var tile = get_tile(x, y)
			if not tile in WALKABLE:
				set_tile(x, y, VTile.Grass)
				path_star.set_point_weight_scale(get_index(x, y), SMALL_WEIGHT)
		return true

	# debug print for `connect_areas``
	func print_map_area_point_path(map, area, point, path):
		for y in range(height):
			var line = ""
			for x in range(width):
				var id = get_index(x, y)
				var tile = DEBUG_VTILE_MAP[map[id]]
				if x == point[0] and y == point[1]:
					tile = "\u001b[91m" + tile + "\u001b[0m"
				elif id in area:
					tile = "\u001b[92m" + tile + "\u001b[0m"
				if id in path:
					tile = "\u001b[100m" + tile + "\u001b[0m"
				elif path_star.has_point(id) and path_star.get_point_weight_scale(id) == LARGE_WEIGHT:
					tile = "\u001b[41m" + tile + "\u001b[0m"
				line += tile
			print(line)
		print()

	func try_generate_spawner_pos(spawners, on_tile):
		var avail := []
		for y in range(1, height - 1):
			for x in range(1, width - 1):
				if get_tile(x, y) != on_tile: continue
				var is_ok := true
				for spawner in spawners:
					if Vector2(x, y).distance_to(spawner) < spawner_min_distance:
						is_ok = false
						break
				if is_ok:
					avail.append(Vector2(x, y))
		if len(avail) == 0:
			return null
		return avail[randi() % len(avail)]

	func place_spawners():
		var spawners := []
		for _i in range(spawner_count):
			var pos = try_generate_spawner_pos(spawners, VTile.Wasteland)
			if pos == null:
				pos = try_generate_spawner_pos(spawners, VTile.Grass)
				if pos == null:
					break
			set_tile(pos.x, pos.y, VTile.Spawner)
			spawners.append(pos)
	
	func generate_base_tile(x: int, y: int):
		var pos_tile := Vector2(x, y)
		
		var axis_y_norm = centerv.distance_to(pos_tile) / (size / 2) \
			+ 0.2 * distance_noise.get_noise_2dv(pos_tile)
			
		var axis_x_norm = (fertility_noise.get_noise_2dv(pos_tile) + 1.0) / 2.0
		
		var axis_y := int(clamp(round(GENERATION_MAP_DIMS.y * axis_y_norm - 0.5), 0, GENERATION_MAP_DIMS.y - 1))
		var axis_x := int(clamp(round(GENERATION_MAP_DIMS.x * axis_x_norm - 0.5), 0, GENERATION_MAP_DIMS.x - 1))

		return GENERATION_MAP[axis_y][axis_x]

	func generate():
		for y in range(height):
			for x in range(width):
				tiles.append(generate_base_tile(x, y))

		fill_edges()

		setup_drunk_star()
		for _i in range((randi() % 4) + 2):
			draw_river()

		place_spawners()

		setup_path_star()
		while connect_areas():
			pass

		place_barn()

	func print_():
		var line
		for y in range(height):
			line = ""
			for x in range(width):
				line += DEBUG_VTILE_MAP[get_tile(x, y)]
			print(line)
