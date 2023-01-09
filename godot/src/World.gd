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

var __tower_store = {}
func get_tower_at(map_pos: Vector2):
	return __tower_store.get(map_pos)

var __plant_store = {}
func get_plant_at(map_pos: Vector2):
	return __plant_store.get(map_pos)

func _get_towers_around(snap_pos):
	var map_pos = Map.world_to_map(snap_pos)
	var towers = []

	for neighbour in NEIGHBORS:
		var tower = get_tower_at(map_pos + neighbour)
		if tower != null:
			towers.append(tower)

	return towers

func _get_plants_around(snap_pos):
	var map_pos = Map.world_to_map(snap_pos)
	var plants = []

	for neighbour in NEIGHBORS:
		var plant = get_plant_at(map_pos + neighbour)
		if plant != null:
			plants.append(plant)

	return plants

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

func _can_place_at(world_pos: Vector2) -> bool:
	var map_pos = Map.world_to_map(world_pos)
	if _currently_selected_item in Globals.TOOLS:
		return false
	if _currently_selected_item in Globals.PLANTS:
		return Map.is_ground_at(map_pos, "FarmSoil")
	if _currently_selected_item == Globals.ItemType.TowerWIP:
		return Map.is_ground_at(map_pos, "Water")
	return Map.can_place_building_at_map_pos(map_pos)

func _create_current_item_at(snap_pos, is_active := true) -> Node2D:
	var item: Node2D = ITEM_PRELOADS[_currently_selected_item].instance()
	Map.add_child(item)
	item.global_position = snap_pos
	item.is_active = is_active
	
	item.connect("hover_start", self, "emit_signal", ["hover_start_tower", snap_pos, item])
	item.connect("hover_end", self, "emit_signal", ["hover_end_tower"])
	item.connect("click", self, "_on_tower_clicked", [snap_pos, item])
	return item

var clicked_item = null
func _on_tower_clicked(snap_pos, item):
	if clicked_item == null:
		emit_signal("select_tower", snap_pos, item)
		clicked_item = item
	else:
		if clicked_item == item:
			emit_signal("unselect_tower")
			clicked_item = null
		else:
			emit_signal("unselect_tower")
			emit_signal("select_tower", snap_pos, item)
			clicked_item = item
	

func _on_screen_clicked():
	var worldpos = get_global_mouse_position()
	if not _can_place_at(worldpos):
		return

	var snap_pos = Map.snap_to_grid_center(worldpos)
	var item := _create_current_item_at(snap_pos)
	var map_pos: Vector2 = Map.world_to_map(snap_pos)
	Map.building_place(snap_pos)
	last_tower_location = null

	if _current_item_is_tower():
		Map.set_ground_around_tower(map_pos, item.farmland_radius)
		# save this Tower in both data structures
		__tower_store[map_pos] = item
		
		for plant in _get_plants_around(snap_pos):
			plant._buff_tower([item])

		# connect Tower remove handler to remove from both data structures on Tower death
		item.connect("tree_exiting", self, "_on_building_removed", [map_pos, snap_pos], CONNECT_ONESHOT)

	elif _current_item_is_plant():
		__plant_store[map_pos] = item
		item._buff_tower(_get_towers_around(snap_pos))

func _on_building_removed(map_pos: Vector2, snap_pos: Vector2):
	__tower_store.erase(map_pos)
	Map.building_place(snap_pos, true)

func _process(delta):
	var hover_coord = get_global_mouse_position()
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
