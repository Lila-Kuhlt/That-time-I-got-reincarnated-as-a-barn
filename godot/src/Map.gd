extends Node2D

export var grass_tile_ratio: float = 0.4;
export var tile_count_w: int = 50;
export var tile_count_h: int = 30;

onready var bg_layer = $BackgroundLayer;
onready var bld_layer = $BuildLayer;

func _ready():
	print(bg_layer.get_cell_autotile_coord(0, 0))
	generate_bg_layer()

func _process(delta):
	pass

func generate_bg_layer():
	bg_layer.clear()
	for y in range(tile_count_h):
		for x in range(tile_count_w):
			var id = int(randf() > grass_tile_ratio)
			bg_layer.set_cell(x, y, 0, false, false, false, Vector2(id, 0))
			

func world_to_map_pos(global : Vector2):
	bld_layer.world_to_map(global)
