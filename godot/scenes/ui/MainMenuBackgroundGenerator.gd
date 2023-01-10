extends ViewportContainer

export var tilemap_draw_width: int = 20
export var tilemap_draw_height: int = 12
export var expand_count: int = 4

onready var background: TileMap = $BackgroundTileMap
onready var ground: TileMap = $GroundTileMap
onready var foreground: TileMap = $ForegroundTileMap

func _expand(map: TileMap, w: int, h: int):
	for y in range(h):
		for x in range(w):
			var tile = map.get_cell(x, y)
			var mx: int = (w << 1) - x - 1
			var my: int = (h << 1) - y - 1
			map.set_cell(mx, y, tile)
			map.set_cell(x, my, tile)
			map.set_cell(mx, my, tile)

func _ready():
	var w: int = tilemap_draw_width
	var h: int = tilemap_draw_height
	for _i in range(expand_count):
		_expand(background, w, h)
		_expand(ground, w, h)
		_expand(foreground, w, h)
		w <<= 1
		h <<= 1
	for map in [background, ground, foreground]:
		map.update_bitmask_region(Vector2(0, 0), Vector2(w, h))
