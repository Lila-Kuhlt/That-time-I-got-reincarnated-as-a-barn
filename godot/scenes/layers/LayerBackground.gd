extends "Layer.gd"

const MATERIAL: Material = preload("res://scenes/layers/LayerBackgroundMapMaterial.tres")

# Fix to prevent weird clipping of Background and Ground Layer
const BG_LAYER_Y_OFFSET = 30 # in tiles

const GRASS_TILES := ["grass_0", "grass_0", "grass_0", "grass_1", "grass_2", "grass_3"]

func init_layer(map_dim: Vector2):
	.init_layer(map_dim)

func _ready():
	Settings.get_settings().connect("settings_changed", self, "_on_settings_changed")
	_on_settings_changed("shaders_on")

## PRIVATE
func _on_settings_changed(settings_name):
	if settings_name == "shaders_on":
		material = MATERIAL if Settings.get_settings().shaders_on else null
		
## PUBLIC
func generate_background(forest_margin):
	clear()
	
	var tile_ids := []
	for tile_name in GRASS_TILES:
		tile_ids.append(tile_set.find_tile_by_name(tile_name))
	
	position.y = -32 * BG_LAYER_Y_OFFSET
	for y in range(-forest_margin, map_dim.y + forest_margin):
		for x in range(-forest_margin, map_dim.x + forest_margin):
			var tile_id = tile_ids[randi() % tile_ids.size()]
			set_cell(x, y + BG_LAYER_Y_OFFSET, tile_id)

## OVERRIDES


