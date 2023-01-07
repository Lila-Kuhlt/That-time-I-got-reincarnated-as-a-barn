extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var Map = $Map
const Tower = preload("res://scenes/Tower.tscn")
var last_tower = null

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func _on_UI_screen_clicked(worldpos):
	var map_pos = Map.world_to_map_pos(worldpos)
	var tower : Node2D = Tower.instance()
	add_child(tower)
	tower.global_position = map_pos
	tower.is_active = true
	tower.modulate.a = 1
	
func _on_UI_hover_start():
	$Timer.start()

func _on_UI_hover_stop():
	$Timer.stop()

func _on_Timer_timeout():
	if last_tower != null:
		remove_child(last_tower)
	var map_pos = Map.world_to_map_pos(get_viewport().get_mouse_position())
	var tower : Node2D = Tower.instance()
	last_tower = tower
	add_child(tower)
	tower.global_position = map_pos
