extends Node2D

const ITEM_PRELOADS = {
	# Items
	Globals.ItemType.ToolScythe : null,
	Globals.ItemType.ToolWateringCan : null,

	# Plants
	Globals.ItemType.PlantChili : preload("res://scenes/plants/Chili.tscn"),
	Globals.ItemType.PlantTomato : preload("res://scenes/plants/Tomato.tscn"),
	Globals.ItemType.PlantAubergine : preload("res://scenes/plants/Aubergine.tscn"),
	Globals.ItemType.PlantPotato : preload("res://scenes/plants/Potato.tscn"),

	# Towers
	Globals.ItemType.TowerWindmill : preload("res://scenes/towers/TowerWindmill.tscn"),
	Globals.ItemType.TowerWatertower : preload("res://scenes/towers/TowerWatertower.tscn"),
	Globals.ItemType.TowerWIP : preload("res://scenes/towers/TowerWaterwheel.tscn")
}

const NEIGHBORS = [
	Vector2(1,1),
	Vector2(1,0),
	Vector2(1,-1),
	Vector2(0,1),
	Vector2(0,-1),
	Vector2(-1,1),
	Vector2(-1,0),
	Vector2(-1,-1),
]

onready var Map = $Map

signal hover_end_tower()
signal hover_start_tower(coord, tower)
signal select_tower(coord, tower)
signal unselect_tower()

var last_tower = null
var last_tower_location = null
var tower_updated = false
var _currently_selected_item = Globals.ItemType.ToolScythe

var mouse_pressed := false

var __tower_store = {}
func get_tower_at(map_pos: Vector2):
	return __tower_store.get(map_pos)

func _get_towers_around(snap_pos):
	var map_pos = Map.world_to_map(snap_pos)
	var towers = []

	for neighbour in NEIGHBORS:
		var tower = get_tower_at(map_pos + neighbour)
		if tower != null:
			towers.append(tower)

	return towers

func _ready():
	var ui_node = get_tree().get_nodes_in_group("UI")[0]
	ui_node.connect("item_selected", self, "_update_tower")

func _update_tower(selected_item):
	tower_updated = true
	_currently_selected_item = selected_item

func _current_item_is_tower() -> bool:
	return _currently_selected_item in Globals.TOWERS

func _current_item_is_plant() -> bool:
	return _currently_selected_item in Globals.PLANTS

func _can_place_at(worldpos) -> bool:
	if _currently_selected_item in Globals.TOOLS:
		return false
	if _currently_selected_item in Globals.PLANTS:
		return Map.is_ground_at(worldpos, "FarmSoil")
	if _currently_selected_item == Globals.ItemType.TowerWIP:
		return Map.is_ground_at(worldpos, "Water")
	return Map.can_place_building_at(worldpos)

func _create_current_item_at(snap_pos, is_active := true) -> Node2D:
	var item: Node2D = ITEM_PRELOADS[_currently_selected_item].instance()
	Map.add_child(item)
	item.global_position = snap_pos
	item.is_active = is_active
	return item

func _on_UI_screen_clicked(worldpos):
	if not _can_place_at(worldpos):
		return

	var snap_pos = Map.snap_to_grid_center(worldpos)
	var item := _create_current_item_at(snap_pos)
	Map.building_place(snap_pos)
	last_tower_location = null

	if _current_item_is_tower():
		var map_pos: Vector2 = Map.world_to_map(snap_pos)
		Map.set_ground_around_tower(map_pos, item.farmland_radius)
		# save this Tower in both data structures
		__tower_store[map_pos] = item

		# connect Tower remove handler to remove from both data structures on Tower death
		item.connect("tree_exiting", self, "_on_building_removed", [map_pos, snap_pos], CONNECT_ONESHOT)

	elif _current_item_is_plant():
		item._buff_tower(_get_towers_around(snap_pos))

func _on_building_removed(map_pos: Vector2, snap_pos: Vector2):
	__tower_store.erase(map_pos)
	Map.building_place(snap_pos, true)

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

		if _can_place_at(snap_pos):
			var tower = _create_current_item_at(snap_pos, false)
			last_tower = tower
			if _current_item_is_tower():
				Map.update_preview_ground(snap_pos, tower.farmland_radius)
			else:
				Map.remove_preview_ground()
		else:
			Map.remove_preview_ground()
