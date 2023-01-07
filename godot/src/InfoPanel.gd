extends PanelContainer

const HOVER_ALPHA: float = 0.7

var selection = false

func _ready():
	pass

func _process(delta):
	pass

func on_hover_start(coord, title, desc):
	if selection:
		return
	self.modulate.a = HOVER_ALPHA
	self.rect_position = coord
	self.visible = true
	$VBoxContainer/Title.text = title
	$VBoxContainer/Title.desc = desc

func on_hover_end():
	if not selection:
		self.visible = false

func on_select(coord, title, desc):
	selection = true
	self.modulate.a = 1.0
	self.rect_position = coord
	self.visible = true
	$VBoxContainer/Title.text = title
	$VBoxContainer/Title.desc = desc

func on_unselect():
	selection = false
	self.visible = false
