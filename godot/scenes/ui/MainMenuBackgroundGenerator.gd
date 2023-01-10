extends ViewportContainer

export var tilemap_draw_width: int = 20
export var tilemap_draw_height: int = 12
export var expand_count: int = 4
export var barn_frame_count: int = 8

onready var background: TileMap = $BackgroundTileMap
onready var ground: TileMap = $GroundTileMap
onready var foreground: TileMap = $ForegroundTileMap
onready var buildings: TileMap = $BuildingTileMap

var is_ready: bool = false
var barn_position: Vector2
var barn_frame: int = 0

func _scan_for_barn():
	for y in range(tilemap_draw_height):
		for x in range(tilemap_draw_width):
			var tile = buildings.get_cell(x, y)
			if tile == TileMap.INVALID_CELL: continue
			var tile_name = buildings.tile_set.tile_get_name(tile)
			if tile_name.find("barn-") != -1:
				barn_position = Vector2(x, y)
				return

func _set_barn_frame(new_frame: int):
	if not is_ready or new_frame == barn_frame: return
	barn_frame = new_frame
	print('new frame ', barn_frame)
	var tile = buildings.tile_set.find_tile_by_name("barn-" + str(barn_frame))
	buildings.set_cellv(barn_position, tile)

func _expand(map: TileMap, w: int, h: int):
	for y in range(h):
		for x in range(w):
			var tile = map.get_cell(x, y)
			var autotile = map.get_cell_autotile_coord(x, y)
			var mx: int = (w << 1) - x - 1
			var my: int = (h << 1) - y - 1
			for c in [[mx, y], [x, my], [mx, my]]:
				map.set_cell(c[0], c[1], tile, false, false, false, autotile)

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
	_scan_for_barn()
	$BarnAnimationPlayer.play("Barnimation")
	is_ready = true
