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

const TEXTURE_MAP = [
	[{ VTile.Pond: VTile.Pond, VTile.Grass: VTile.Grass, VTile.Wasteland: VTile.Wasteland }, 70],
	[{ VTile.Pond: VTile.Pond, VTile.Grass: VTile.Tree, VTile.Wasteland: VTile.WastelandStone }, 80],
	[{ VTile.Pond: VTile.Pond, VTile.Grass: VTile.GrassStone, VTile.Wasteland: VTile.WastelandStone }, 101],
]

const TEMPRATURE_MAP = [
	#Barn             : [],
	[VTile.Pond             ,  20],
	[VTile.Grass            ,  60],
	[VTile.Wasteland        ,  101],
]

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

	func _init(_width: int, _height: int, saed = null):
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


	func set_tile(x: int, y: int, tile):
		tiles[y * width + x] = tile

	func get_tile(x: int, y: int):
		return tiles[y * width + x]

	
	func normal_dist(x: float, a: float, b: float = 1.0) -> float:
		var xa = x/a
		return exp(-xa * xa) * b + (1.0 - b)

	func temperature_at(pos: Vector2):
		# Scale noise from (-1.0, 1.0) to (0.0, 100.0)
		var temperature = ((temprature_noise.get_noise_2dv(pos) + 1.0) / 2.0)
		var dist = pos - Vector2(width, height)/2.0

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

	func generate():
		for y in range(height):
			for x in range(width):
				var pos = Vector2(x,y)
				var temp = temperature_at(pos)
				var texture = texture_at(pos)

				tiles.append(texture[temp])

		fill_edges()

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
