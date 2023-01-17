extends "Layer.gd"

# Fix to prevent weird clipping of Background and Ground Layer
const BG_LAYER_Y_OFFSET = 30 # in tiles

const GRASS_TILE_RATIO: float = 0.4

func init_layer(map_dim: Vector2):
	.init_layer(map_dim)

## PRIVATE

## PUBLIC
func generate_background(forest_margin):
	clear()
	position.y = -32 * BG_LAYER_Y_OFFSET
	for y in range(-forest_margin, map_dim.y + forest_margin):
		for x in range(-forest_margin, map_dim.x + forest_margin):
			var id = int(randf() > GRASS_TILE_RATIO)
			set_cell(x, y + BG_LAYER_Y_OFFSET, 0, false, false, false, Vector2(id, 0))

## OVERRIDES
