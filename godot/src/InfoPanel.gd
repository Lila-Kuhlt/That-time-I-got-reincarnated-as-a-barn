extends PanelContainer

const HOVER_ALPHA: float = 0.7

var selection = false
onready var title_label = $VBoxContainer/Title
onready var desc_label = $VBoxContainer/Description

func _ready():
	pass

func _process(delta):
	pass

func construct_tower_title(tower):
	return "Windmill"

func construct_tower_desc(tower):
	#return (
	#	"Health: " + str(tower.health) + "\n" +
	#	"Damage: " + str(tower.projectile_damage))
	return "uwu :3"

func _on_Map_hover_end_tower():
	if not selection:
		self.visible = false

func _on_Map_hover_start_tower(coord, tower):
	if selection:
		return
	self.modulate.a = HOVER_ALPHA
	self.rect_position = coord
	self.visible = true
	title_label.text = construct_tower_title(tower)
	desc_label.text = construct_tower_desc(tower)

func _on_Map_select_tower(coord, tower):
	selection = true
	self.modulate.a = 1.0
	self.rect_position = coord
	self.visible = true
	title_label.text = construct_tower_title(tower)
	desc_label.text = construct_tower_desc(tower)

func _on_Map_unselect_tower():
	selection = false
	self.visible = false
