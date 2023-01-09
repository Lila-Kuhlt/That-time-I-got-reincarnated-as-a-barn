extends Node

enum VTile {
	Barn,
	Wasteland,
	WastelandStone,
	Grass,
	GrassStone,
	Tree,
	Pond,
	River
}

const TEXTURE_MAP := [
	[{ VTile.Pond: VTile.Pond, VTile.Grass: VTile.Grass, VTile.Wasteland: VTile.Wasteland }, 			70],
	[{ VTile.Pond: VTile.Pond, VTile.Grass: VTile.Tree, VTile.Wasteland: VTile.WastelandStone }, 		80],
	[{ VTile.Pond: VTile.Pond, VTile.Grass: VTile.GrassStone, VTile.Wasteland: VTile.WastelandStone }, 101],
]

const TEMPRATURE_MAP := [
	[VTile.Pond,	   20],
	[VTile.Grass,	   60],
	[VTile.Wasteland, 101],
]

const RIVER_BLOCKER := [
	VTile.Barn,
	VTile.GrassStone,
	VTile.WastelandStone
]

const RIVER_CONNECTION_PATTERN := [[0, -1], [1, 0], [0, 1], [-1, 0]]

class DrunkAStar:
	extends AStar

	var alcohol_level

	func _init(_alcohol_level := 2.0).():
		self.alcohol_level = _alcohol_level

	func _compute_cost(u, v):
		return (get_point_position(u) - get_point_position(v)).length() + randf() * alcohol_level

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

	var temprature_noise: OpenSimplexNoise
	var texture_noise: OpenSimplexNoise

	var drunk_star: DrunkAStar

	func _init(_width: int, _height: int, saed = null, ds_alcohol_level := 2.0):
		assert(_height&1 == 1 and _width&1 == 1, "The map has no center")
		self.tiles = []
		self.width = _width
		self.height = _height
		
		temprature_noise = OpenSimplexNoise.new()
		temprature_noise.seed = saed if saed != null else randi()
		temprature_noise.period = 0.25

		texture_noise = OpenSimplexNoise.new()
		texture_noise.seed = temprature_noise.seed ^ 0xc0ffe
		texture_noise.period = 1.5

		drunk_star = DrunkAStar.new(ds_alcohol_level)

	func set_tile(x: int, y: int, tile):
		tiles[get_index(x, y)] = tile

	func get_tile(x: int, y: int):
		return tiles[get_index(x, y)]

	func get_index(x: int, y: int) -> int:
		return y * width + x

	func in_bounds(x: int, y: int) -> bool:
		return not (x < 0 or y < 0 or x >= width or y >= height)
	
	func normal_dist(x: float, a: float, b: float = 1.0) -> float:
		var xa = x/a
		return exp(-xa * xa) * b + (1.0 - b)

	func temperature_at(pos: Vector2):
		# Scale noise from (-1.0, 1.0) to (0.0, 100.0)
		var temperature = ((temprature_noise.get_noise_2dv(pos) + 1.0) / 2.0)
		var dist = pos - Vector2(width, height) / 2.0

		temperature *= normal_dist(dist.length(), 5, 0)

		for kv in TEMPRATURE_MAP:
			var key = kv[0]
			var value = kv[1]
			if value > temperature*100:
				return key

		assert(false, "wtf?")

	func texture_at(pos: Vector2):
		var texture = ((texture_noise.get_noise_2dv(pos) + 1.0) / 2.0)

		for kv in TEXTURE_MAP:
			var key = kv[0]
			var value = kv[1]
			if value > texture*100:
				return key

		assert(false, "wtf?")

	func fill_edges():
		for y in range(height):
			set_tile(0, y, VTile.Tree)
			set_tile(width - 1, y, VTile.Tree)

		for x in range(width):
			set_tile(x, 0, VTile.Tree)
			set_tile(x, height - 1, VTile.Tree)

		set_tile(width>>1, height>>1, VTile.Barn)

	func setup_drunk_star():
		for y in range(height):
			for x in range(width):
				if get_tile(x, y) in RIVER_BLOCKER:
					continue
				drunk_star.add_point(get_index(x, y), Vector3(x, y, 0))
				for v in RIVER_CONNECTION_PATTERN:
					var dx = v[0]
					var dy = v[1]
					var nx = dx + x
					var ny = dy + y
					if (not in_bounds(nx, ny)
							or (dx == 0 and dy == 0)
							or get_tile(nx, ny) in RIVER_BLOCKER):
						continue
					drunk_star.connect_points(get_index(nx, ny), get_index(x,y))

	func draw_river():
		var start_id: int = [
			get_index(randi() % width, 0),
			get_index(randi() % width, height - 1),
			get_index(0, randi() % height),
			get_index(width - 1, randi() % height)
		][randi() & 3]
		var target_id: int = randi() % (width*height)
		for point in drunk_star.get_point_path(start_id, target_id):
			set_tile(int(point.x), int(point.y), VTile.River)

	func generate():
		for y in range(height):
			for x in range(width):
				var pos = Vector2(x,y)
				var temp = temperature_at(pos)
				var texture = texture_at(pos)
				tiles.append(texture[temp])
		fill_edges()
		setup_drunk_star()
		for _i in range((randi() & 3) + 2):
			draw_river()

	func print_():
		var line
		for y in range(height):
			line = ""
			for x in range(width):
				var tile = get_tile(x,y) 
				match tile:
					null:
						line += "??"
					VTile.Barn:
						line += "BB"
					VTile.Wasteland:
						line += ".."
					VTile.WastelandStone:
						line += "ww"
					VTile.Grass:
						line += "::"
					VTile.GrassStone:
						line += "gg"
					VTile.Tree:
						line += "TT"
					VTile.Pond:
						line += "PP"
					VTile.River:
						line += "RR"
			print(line)
