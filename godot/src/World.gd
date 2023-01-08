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
var tower_updated = false

var mouse_pressed := false

var __tower_store = {}
func get_tower_at(map_pos: Vector2):
	return __tower_store.get(map_pos)

func _ready():
	var ui_node = get_tree().get_nodes_in_group("UI")[0]
	print(ui_node)
	ui_node.connect("item_selected", self, "_update_tower")

func _update_tower(id):
	print("Event Trigger", tower_updated)
	tower_updated = true

func _on_UI_screen_clicked(worldpos):	
	var curr_item_type = $UI.toolbar.get_selected_item()

	if (curr_item_type == null
			or curr_item_type in Globals.TOOLS
			or not Map.can_place_tower_at(worldpos)):
		return
	
	var tower:Node2D = ITEM_PRELOADS[curr_item_type].instance()
	
	var snap_pos = Map.snap_to_grid_center(worldpos)
	Map.add_child(tower)
	tower.global_position = snap_pos
	tower.is_active = true
	last_tower_location = null
	
	if curr_item_type in Globals.TOWERS:
		var map_pos: Vector2 = Map.world_to_map(snap_pos)
		
		# save this Tower in both data structures
		__tower_store[map_pos] = tower
		Map.tower_place(snap_pos, tower.tower_name)
	
		# connect Tower remove handler to remove from both data structures on Tower death
		tower.connect("child_exiting_tree", self, "_on_building_removed", [map_pos, snap_pos])

func _on_building_removed(map_pos: Vector2, snap_pos: Vector2):
	print("Building DELETED")
	__tower_store.erase(map_pos)
	Map.tower_place(snap_pos, null)

func _process(delta):
	if mouse_pressed:
		mouse_pressed = false
	else:
		mouse_pressed = Input.is_mouse_button_pressed(BUTTON_LEFT)
	var hover_coord = get_global_mouse_position()
	var hover_tower = get_tower_at(Map.world_to_map(hover_coord))
	var start_sig = "select_tower" if mouse_pressed else "hover_start_tower"
	var stop_sig = "unselect_tower" if mouse_pressed else "hover_end_tower"
	if hover_tower == null:
		emit_signal(stop_sig)
	else:
		emit_signal(start_sig, hover_coord, hover_tower)
	
	var snap_pos = Map.snap_to_grid_center(hover_coord)
	if last_tower_location != snap_pos || tower_updated:
		tower_updated = false
		last_tower_location = snap_pos
		
		if last_tower:
			Map.remove_child(last_tower)
			last_tower = null
		
		var curr_item_type = $UI.toolbar.get_selected_item()

		if (curr_item_type != null
				and not (curr_item_type in Globals.TOOLS)
				and Map.can_place_tower_at(snap_pos)):
			var tower = ITEM_PRELOADS[curr_item_type].instance()
			last_tower = tower
			tower.is_active = false
			Map.add_child(tower)
			tower.global_position = snap_pos
			if curr_item_type in Globals.TOWERS:
				Map.update_preview_ground(snap_pos, tower.farmland_radius)
			else:
				Map.remove_preview_ground()
		else:
			Map.remove_preview_ground()

func _on_Map_spawn_enemy_on_world(enemy, coord):
	print('spawn enemy at ', coord)
	enemy.warp_to(coord)
	add_child(enemy)
