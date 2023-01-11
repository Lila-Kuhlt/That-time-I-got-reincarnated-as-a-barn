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

const TEXTURE_MAP := [
	[{ VTile.Pond: VTile.Pond, VTile.Grass: VTile.Grass, VTile.Wasteland: VTile.Wasteland },           0.70],
	[{ VTile.Pond: VTile.Pond, VTile.Grass: VTile.Tree, VTile.Wasteland: VTile.WastelandStone },       0.80],
	[{ VTile.Pond: VTile.Pond, VTile.Grass: VTile.GrassStone, VTile.Wasteland: VTile.WastelandStone }, 1.01],
]

const TEMPERATURE_MAP := [
	[VTile.Grass,     0.5],
	[VTile.Wasteland, 1.01],
]

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

const NEIGHS_DIRECT = [Vector2(0,-1), Vector2(1,0), Vector2(0,1), Vector2(-1,0)]
const NEIGHS_DIAGONAL = [Vector2(-1,-1), Vector2(1,-1), Vector2(-1,1), Vector2(1,1)]
const NEIGHS = NEIGHS_DIRECT + NEIGHS_DIAGONAL

# used for river generation
class DrunkAStar:
	extends AStar2D

	var alcohol_level: float
	var border_attraction: float
	var width: int
	var height: int

	func _init(w: int, h: int, _alcohol_level := 2.0, _border_attraction := 1.3).():
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

	var temperature_noise: OpenSimplexNoise
	var texture_noise: OpenSimplexNoise
	var pond_noise: OpenSimplexNoise

	var drunk_star: DrunkAStar
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

		temperature_noise = OpenSimplexNoise.new()
		temperature_noise.seed = saed if saed != null else randi()
		temperature_noise.period = 0.25
		temperature_noise.persistence = 1.0

		texture_noise = OpenSimplexNoise.new()
		texture_noise.seed = temperature_noise.seed ^ 0xc0ffe
		texture_noise.period = 1.5

		pond_noise = OpenSimplexNoise.new()
		pond_noise.seed = temperature_noise.seed ^ 0x23A49
		pond_noise.lacunarity = 3.0
		pond_noise.period = 3

		pond_noise = OpenSimplexNoise.new()
		pond_noise.seed = temperature_noise.seed ^ 0x23A49
		pond_noise.lacunarity = 3.0
		pond_noise.period = 3

		drunk_star = DrunkAStar.new(width, height, ds_alcohol_level, border_attraction)

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

	func cubic_bezier(p1: Vector2, p2: Vector2, t: float) -> float:
		var start = Vector2(0, 0)
		var end = Vector2(1, 1)

		var q0 = start.linear_interpolate(p1, t)
		var q1 = end.linear_interpolate(p2, t)
		var r = q0.linear_interpolate(q1, t)
		return r.y

	func layer(first: float, second: float) -> float:
		return (first + second) / 2

	func temperature_at(pos: Vector2):
		# Scale noise from (-1.0, 1.0) to (0.0, 100.0)
		var dist = pos.distance_to(centerv)
		var t = dist/size

		var temperature := cubic_bezier(Vector2(.27, .97), Vector2(0, .99), t)

		temperature = layer(temperature, ((temperature_noise.get_noise_2dv(pos) + 1.0) / 2.0))

		for kv in TEMPERATURE_MAP:
			var key = kv[0]
			var value = kv[1]
			if value > temperature:
				return key

		assert(false, "NO temperature mapping found, this is a bug!")

	func is_pond(pos: Vector2):
		var dist = pos.distance_to(centerv)
		var t = dist/size

		var level = cubic_bezier(Vector2(.86, .28), Vector2(.53, .95), t)
		level = layer(level, ((pond_noise.get_noise_2dv(pos) + 1.0) / 2.0))
		return level >= 0.6

	func texture_at(pos: Vector2):
		var texture = ((texture_noise.get_noise_2dv(pos) + 1.0) / 2.0)
		for kv in TEXTURE_MAP:
			var key = kv[0]
			var value = kv[1]
			if value > texture:
				return key
		assert(false, "wtf?")

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
		var pos := Vector2(center[0], center[1])
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

	func _river_target_helper(x: int, m: int) -> int:
		# generate position with minimum distance `river_dist_min`
		var area_start = max(x - river_dist_min, 0)
		var area_end = min(x + river_dist_min, m)
		var area = max(area_end - area_start - 1, 0)
		var c: int = randi() % (m - area)
		if c > area_start:
			return area_end + c - area_start
		return c

	func river_target_from_source(x: int, y: int) -> Array:
		return [_river_target_helper(x, width), _river_target_helper(y, height)]

	func draw_river():
		var start_a2: Array = [
			[randi() % width, 0],
			[randi() % width, height - 1],
			[0, randi() % height],
			[width - 1, randi() % height]
		][randi() & 3]
		var target_a2 := river_target_from_source(start_a2[0], start_a2[1])
		var start_id = get_index(start_a2[0], start_a2[1])
		var target_id = get_index(target_a2[0], target_a2[1])
		for point in drunk_star.get_point_path(start_id, target_id):
			set_tile(int(point.x), int(point.y), VTile.River)

	func flood_fill_rec(area: Dictionary, x: int, y: int):
		area[get_index(x, y)] = null
		for nei in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
			var nx = x + nei[0]
			var ny = y + nei[1]
			if in_bounds(nx, ny) and get_tile(nx, ny) in WALKABLE and not get_index(nx, ny) in area:
				flood_fill_rec(area, nx, ny)

	func get_neighbor_set(area: Dictionary) -> Dictionary:
		var neis: Dictionary = {}
		for pos in area.keys():
			var p := resolve_index(pos)
			var px: int = p[0]
			var py: int = p[1]
			for d in [[0, -1], [-1, 0], [1, 0], [0, 1]]:
				var x: int = px + d[0]
				var y: int = py + d[1]
				if x < 0 or x >= width or y < 0 or y >= width:
					continue
				var n: int = x + y * width
				if not (n in area):
					neis[n] = null
		return neis

	func flood_fill() -> bool:
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
		var area1 := {}
		flood_fill_rec(area1, xy[0], xy[1])
		var neis1 = get_neighbor_set(area1)

		var expanded: Dictionary = area1.duplicate()
		expanded.merge(neis1)
		xy = null
		while xy == null:
			var neis := get_neighbor_set(expanded)
			if neis.empty():
				return false
			for nei in neis:
				if tiles[nei] in WALKABLE:
					xy = resolve_index(nei)
					break
			expanded.merge(neis)
		var area2 := {}
		flood_fill_rec(area2, xy[0], xy[1])

		# try to replace tiles until everything is path connected
		var neis2 = get_neighbor_set(area2)
		var neisc := []
		for i in neis1.keys():
			if i in neis2.keys():
				neisc.append(i)
		if not neisc:
			neis2.merge(neis1)
			neisc = neis2.keys()
		var neisc2 := []
		for i in neisc:
			var ix: int = i % width
			if (i < width * (height - 1) and i > width and ix != 0
					and ix + 1 < width and not (self.tiles[i] in INDESTRUCTIBLE)):
				neisc2.append(i)
		if not neisc2:
			return false
		var selection = neisc2[randi() % len(neisc2)]
		self.tiles[selection] = VTile.Grass
		return true

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

	func generate():
		for y in range(height):
			for x in range(width):
				var pos = Vector2(x, y)
				if is_pond(pos):
					tiles.append(VTile.Pond)
				else:
					var temp = temperature_at(pos)
					var texture = texture_at(pos)
					tiles.append(texture[temp])
		fill_edges()
		setup_drunk_star()
		for _i in range((randi() % 4) + 2):
			draw_river()
		place_spawners()
		while flood_fill():
			pass
		place_barn()

	func print_():
		var line
		for y in range(height):
			line = ""
			for x in range(width):
				line += DEBUG_VTILE_MAP[get_tile(x,y)]
			print(line)
