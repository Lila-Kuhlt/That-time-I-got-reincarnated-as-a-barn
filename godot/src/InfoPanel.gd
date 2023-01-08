extends Node2D

const HOVER_ALPHA: float = 0.7

var selection = false
onready var title_label = $PanelContainer/VBoxContainer/Title
onready var desc_label = $PanelContainer/VBoxContainer/Description
onready var animator: AnimationPlayer = $AnimationPlayer

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
	animator.play("hide")
	print("hide")

func _on_World_hover_start_tower(coord, tower):
	global_position = coord	
	title_label.text = construct_tower_title(tower)
	desc_label.text = construct_tower_desc(tower)
	
	animator.play("show")
	print("open")

func _on_World_select_tower(coord, tower):
	selection = true
	
	global_position = coord
	
	
	title_label.text = construct_tower_title(tower)
	desc_label.text = construct_tower_desc(tower)

func _on_World_unselect_tower():
	selection = false
	
	
