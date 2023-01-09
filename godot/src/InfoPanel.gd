extends Node2D

const HOVER_ALPHA: float = 0.7

var is_currently_animating = false
var selection = null
onready var title_label = $PanelContainer/VBoxContainer/Title
onready var desc_label = $PanelContainer/VBoxContainer/Description
onready var animator: AnimationPlayer = $AnimationPlayer
onready var animator_hover: AnimationPlayer = $HoverIndicator/AnimationPlayer

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
		"Attack Speed: " + str(tower.stats.AS) + "\n" +
		"Range: " + str(tower.stats.RG))

var selected = false

func _on_World_hover_end_tower():
	animator_hover.play("hide")

func _on_World_hover_start_tower(coord, tower):
	if selected or is_currently_animating:
		return
	global_position = coord
	title_label.text = construct_tower_title(tower)
	desc_label.text = construct_tower_desc(tower)
	animator_hover.play("show")

func _on_World_select_tower(coord, tower):
	selected = true
	global_position = coord
	animator.play("show")
	animator_hover.play("hide")
	title_label.text = construct_tower_title(tower)
	desc_label.text = construct_tower_desc(tower)
	

func _on_World_unselect_tower():
	selected = false
	animator.play("hide")
	is_currently_animating = true
	
func _on_AnimationPlayer_animation_finished(anim_name: String):
	if anim_name == "hide":
		is_currently_animating = false
