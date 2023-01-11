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
onready var Player = $Map/Player

signal hover_end_tower()
signal hover_start_tower(coord, tower)
signal select_tower(coord, tower)
signal unselect_tower()

var last_tower = null
var last_tower_location = null
var tower_updated = false
var _currently_selected_item = Globals.ItemType.ToolScythe
var _current_costs = null

var lastt_field = null

var last_player_pos = null
var is_using = false

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
	ui_node.connect("item_selected", self, "_update_selected_item")

func _update_selected_item(selected_item, costs_or_null):
	tower_updated = true
	_currently_selected_item = selected_item
	_current_costs = costs_or_null

func _current_item_is_tower() -> bool:
	return _currently_selected_item in Globals.TOWERS

func _current_item_is_plant() -> bool:
	return _currently_selected_item in Globals.PLANTS

func _can_afford():
	return _current_costs != null and get_player_inventory().can_pay(_current_costs)

func _can_place_at(world_pos: Vector2) -> bool:
	var map_pos = Map.world_to_map(world_pos)
	
	if _currently_selected_item in Globals.TOOLS or Map.is_building_at(world_pos) or not _can_afford():
		return false
	if _currently_selected_item in Globals.PLANTS:
		return Map.is_ground_at(map_pos, "FarmSoil")
	
	if _currently_selected_item in Globals.TOWERS:
		if _currently_selected_item == Globals.ItemType.TowerWIP:
			return Map.is_ground_at(map_pos, "Water")
		else:
			return not Map.is_ground_at(map_pos, "Wasteland") and Map.can_place_building_at_map_pos(map_pos)
	
	return false
	

func _create_current_item_at(snap_pos, is_active := true) -> Node2D:
	var item: Node2D = ITEM_PRELOADS[_currently_selected_item].instance()
	Map.add_child(item)
	item.global_position = snap_pos
	item.is_active = is_active

	# TODO Throws Error because items of type Plant do not have does signals (yet)
	if item.is_in_group("Tower"):
		item.connect("hover_start", self, "emit_signal", ["hover_start_tower", snap_pos, item])
		item.connect("hover_end", self, "emit_signal", ["hover_end_tower"])
		item.connect("click", self, "_on_tower_clicked", [snap_pos, item])
	return item

func _on_ModalButton_pressed():
	emit_signal("unselect_tower")
	$ModalButton.visible = false

func _on_tower_clicked(snap_pos, item):
	emit_signal("select_tower", snap_pos, item)
	$ModalButton.visible = true

func get_player_inventory():
	return $Map/Player.get_inventory()

func _maybe_remove_farmland(map_pos: Vector2, radius: int):
	if not Map.is_farmland_at(map_pos):
		return
	var has_tower := false
	for pos in Map.get_positions_around_tower(map_pos, radius):
		if get_tower_at(pos) != null:
			has_tower = true
			break
	if not has_tower:
		Map.remove_at(map_pos)
		var plant = __plant_store.get(map_pos)
		if plant != null:
			plant.queue_free()
			__plant_store.erase(map_pos)
			Map.building_place_or_remove(map_pos, true)

func _on_building_removed(map_pos: Vector2):
	__tower_store.erase(map_pos)
	emit_signal("unselect_tower")
	Map.building_place_or_remove(map_pos, true)

	var radius = 1
	for pos in Map.get_positions_around_tower(map_pos, radius):
		_maybe_remove_farmland(pos, radius)
	var rvec := 2 * Vector2(radius, radius)
	Map.l_ground.update_bitmask_region(map_pos - rvec, map_pos + rvec)

	tower_updated = true

func _process(_delta):
	var is_mouse_down = $ToolButton.pressed
	var player_pos = Map.world_to_map(Player.global_position)
	var use_tool = is_mouse_down || Input.is_action_pressed("use_tool")
	if _currently_selected_item in Globals.TOOLS:
		if not use_tool && is_using:
			is_using = false
			Player.end_use_tool()
		elif use_tool && not is_using \
			|| (use_tool && is_using && player_pos != last_player_pos):
			Player.begin_use_tool(self)
			is_using = true
			last_player_pos = player_pos

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

	if is_mouse_down && last_tower != null:
		last_tower.is_active = true
		var item = last_tower
		last_tower = null
		Map.remove_preview_ground()
		var map_pos = Map.world_to_map(snap_pos)
		Map.building_place_or_remove(map_pos, false, _currently_selected_item in Globals.PLANTS)

		if _current_item_is_tower():
			Map.set_ground_around_tower(map_pos, item.farmland_radius)

			__tower_store[map_pos] = item

			for plant in _get_plants_around(map_pos):
				plant._buff_tower([item])

			# connect Tower remove handler to remove from both data structures on Tower death
			item.connect("tree_exiting", self, "_on_building_removed", [map_pos], CONNECT_ONESHOT)
		elif _current_item_is_plant():
			__plant_store[map_pos] = item
			item._buff_tower(_get_towers_around(snap_pos))
		get_player_inventory().pay(_current_costs)
