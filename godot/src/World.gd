extends Node2D

const ITEM_PRELOADS = {
	# Items
	Globals.ItemType.ToolScythe : null,
	Globals.ItemType.ToolWateringCan : null,
	
	#Plants
	Globals.ItemType.PlantChili : preload("res://scenes/plants/Chili.tscn"),
	Globals.ItemType.PlantTomato : preload("res://scenes/plants/Tomato.tscn"),
	Globals.ItemType.PlantAubergine : preload("res://scenes/plants/Aubergine.tscn"),
	Globals.ItemType.PlantPotato : preload("res://scenes/plants/Potato.tscn"),
	
	# Towers
	Globals.ItemType.TowerWindmill : preload("res://scenes/towers/TowerWindmill.tscn"),
	Globals.ItemType.TowerWatertower : preload("res://scenes/towers/TowerWatertower.tscn"),
	Globals.ItemType.TowerWIP : preload("res://scenes/towers/TowerWindmill.tscn")
}

onready var Map = $Map
const Tower = preload("res://scenes/Tower.tscn")

signal hover_end_tower()
signal hover_start_tower(coord, tower)
signal select_tower(coord, tower)
signal unselect_tower()

var last_tower = null
var last_tower_location = null

var mouse_pressed := false

var __tower_store = {}
func get_tower_at(map_pos: Vector2):
	return __tower_store.get(map_pos)

func _on_UI_screen_clicked(worldpos):	
	var curr_item_type = $UI.toolbar.get_selected_item()

	if curr_item_type == null:
		return
		
	if curr_item_type in Globals.TOOLS:
		return
		
	var tower = ITEM_PRELOADS[curr_item_type].instance()
	
	var map_pos = Map.world_to_map_pos(worldpos)
	Map.add_child(tower)
	tower.global_position = map_pos
	tower.is_active = true

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
		
		var curr_item_type = $UI.toolbar.get_selected_item()
		
		if curr_item_type == null:
			return
		
		if curr_item_type in Globals.TOOLS:
			return

		var tower = ITEM_PRELOADS[curr_item_type].instance()
		
		
		last_tower = tower
		tower.is_active = false
		Map.add_child(tower)
		tower.global_position = map_pos
	last_tower_location = map_pos
