extends Node2D



const TOWERS = {
	Globals.TowerType.Windmill : preload("res://scenes/Tower.tscn")
}

onready var Map = $Map
const Tower = preload("res://scenes/Tower.tscn")

var last_tower = null
var last_tower_location = null

var __tower_store = {}
func get_tower_at(map_pos: Vector2):
	return __tower_store.get(map_pos)

func _on_UI_screen_clicked(worldpos):	
	var curr_tower_type = $UI.toolbar.get_tower_type()

	if curr_tower_type == null:
		return
		
	var tower = TOWERS[curr_tower_type].instance()
	
	var map_pos = Map.world_to_map_pos(worldpos)
	add_child(tower)
	tower.global_position = map_pos
	tower.is_active = true
	tower.modulate.a = 1
	
	var real_map_pos = $Map/BuildingLayer.world_to_map(worldpos)
	__tower_store[real_map_pos] = tower
	
	Map.tower_place(worldpos, tower.get_tower_name())


func _process(delta):
	var map_pos = Map.world_to_map_pos(get_viewport().get_mouse_position())
	if last_tower_location != map_pos:
		
		if last_tower:
			remove_child(last_tower)
			last_tower = null
		
		var curr_tower_type = $UI.toolbar.get_tower_type()
		if curr_tower_type == null:
			return
		var tower = TOWERS[curr_tower_type].instance()
		
		last_tower = tower
		add_child(tower)
		tower.global_position = map_pos
	last_tower_location = map_pos
