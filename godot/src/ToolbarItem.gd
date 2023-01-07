extends TextureRect

func _ready():
	pass

func set_selected(is_sel: bool) -> void:
	var pos: float = texture.atlas.get_size().x / 2
	if !is_sel:
		pos = 0
	texture.region.position = Vector2(pos, 0.0)
