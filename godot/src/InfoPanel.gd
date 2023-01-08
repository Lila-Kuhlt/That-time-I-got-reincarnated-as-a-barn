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
	return tower.tower_name

func construct_tower_desc(tower):
	return (
		"Health: " + str(tower.stats.HP) + "\n" +
		"Damage: " + str(tower.stats.DMG) + "\n" +
		"Attack Speed: " + str(tower.stats.AS) + "s\n" +
		"Range: " + str(tower.stats.RG))

func _on_World_hover_end_tower():
	if not selection:
		self.visible = false

func _on_World_hover_start_tower(coord, tower):
	if selection:
		return
	self.modulate.a = HOVER_ALPHA
	self.rect_global_position = coord
	self.visible = true
	title_label.text = construct_tower_title(tower)
	desc_label.text = construct_tower_desc(tower)

func _on_World_select_tower(coord, tower):
	selection = true
	self.modulate.a = 1.0
	self.rect_global_position = coord
	self.visible = true
	title_label.text = construct_tower_title(tower)
	desc_label.text = construct_tower_desc(tower)

func _on_World_unselect_tower():
	selection = false
	self.visible = false
