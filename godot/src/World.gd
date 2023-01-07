extends Node2D

# Declare member variables here. Examples:
# var a = 2
# var b = "text"
onready var Map = $Map
const Tower = preload("res://scenes/Tower.tscn")
var last_tower = null
var last_tower_location = null

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

func _process(delta):
	var map_pos = Map.world_to_map_pos(get_viewport().get_mouse_position())
	if last_tower_location != map_pos:
		remove_child(last_tower)
		var tower : Node2D = Tower.instance()
		last_tower = tower
		add_child(tower)
		tower.global_position = map_pos
	last_tower_location = map_pos
