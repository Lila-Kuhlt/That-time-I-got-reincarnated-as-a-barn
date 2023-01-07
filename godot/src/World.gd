extends Node2D

const TOWERS = {
	Globals.TowerType.Windmill : preload("res://scenes/towers/TowerWindmill.tscn"),
	Globals.TowerType.Watertower : preload("res://scenes/towers/TowerWatertower.tscn"),
	Globals.TowerType.WIP : preload("res://scenes/towers/TowerWindmill.tscn")
}

onready var Map = $Map
const Tower = preload("res://scenes/Tower.tscn")

signal hover_end_tower()
signal hover_start_tower(coord, tower)
signal select_tower(coord, tower)
signal unselect_tower()

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
	Map.add_child(tower)
	tower.global_position = map_pos
	tower.is_active = true
	tower.modulate.a = 1
	
	var real_map_pos = $Map/BuildingLayer.world_to_map(worldpos)
	__tower_store[real_map_pos] = tower
	
	Map.tower_place(worldpos, tower.tower_name)

var mouse_pressed := false

func _process(delta):
	if mouse_pressed:
		mouse_pressed = false
	else:
		mouse_pressed = Input.is_mouse_button_pressed(BUTTON_LEFT)
	var hover_coord = get_global_mouse_position()
	var hover_tower = get_tower_at($Map/BuildingLayer.world_to_map(hover_coord))
	var start_sig = "select_tower" if mouse_pressed else "hover_start_tower"
	var stop_sig = "unselect_tower" if mouse_pressed else "hover_end_tower"
	if hover_tower == null:
		emit_signal(stop_sig)
	else:
		emit_signal(start_sig, hover_coord, hover_tower)
	
	var map_pos = Map.world_to_map_pos(get_viewport().get_mouse_position())
	if last_tower_location != map_pos:
		
		if last_tower:
			Map.remove_child(last_tower)
			last_tower = null
		
		var curr_tower_type = $UI.toolbar.get_tower_type()
		if curr_tower_type == null:
			return
		var tower = TOWERS[curr_tower_type].instance()
		
		
		last_tower = tower
		tower.is_active = false
		Map.add_child(tower)
		tower.global_position = map_pos
	last_tower_location = map_pos
