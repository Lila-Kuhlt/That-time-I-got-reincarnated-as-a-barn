extends "Screen.gd"

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
	Globals.ItemType.TowerWaterwheel : preload("res://scenes/towers/TowerWaterwheel.tscn")
}

const NEIGHBORS = [
	Vector2(1, 1),
	Vector2(1, 0),
	Vector2(1, -1),
	Vector2(0, 1),
	Vector2(0, -1),
	Vector2(-1, 1),
	Vector2(-1, 0),
	Vector2(-1, -1),
]

onready var map = $Navigation2D/Map
onready var player = $Navigation2D/Map/Player

signal hover_end_tower()
signal hover_start_tower(coord, tower)
signal select_tower(coord, tower)
signal unselect_tower()

var last_tower = null
var last_tower_location = null
var tower_updated = false
var _currently_selected_item = Globals.ItemType.ToolScythe
var _current_costs = null

var last_player_pos = null
var is_using = false

var barn_pos: Vector2

var __tower_store = {}
func get_tower_at(map_pos: Vector2):
	return __tower_store.get(map_pos)

var __plant_store = {}
func get_plant_at(map_pos: Vector2):
	return __plant_store.get(map_pos)

func _get_towers_around(map_pos):
	var towers = []

	for neighbour in NEIGHBORS:
		var tower = get_tower_at(map_pos + neighbour)
		if tower != null:
			towers.append(tower)

	return towers

func _get_plants_around(map_pos):
	var plants = []

	for neighbour in NEIGHBORS:
		var plant = get_plant_at(map_pos + neighbour)
		if plant != null:
			plants.append(plant)

	return plants

# check if neighbors are kept alive by a tower
func _check_plants_around(map_pos):
	for neighbour in NEIGHBORS:
		var pos: Vector2 = map_pos + neighbour
		var plant = get_plant_at(pos)
		if plant != null:
			plant._check_tower_keep_alive(_get_towers_around(pos))

func _ready():
	var ui_node = get_tree().get_nodes_in_group("UI")[0]
	ui_node.connect("item_selected", self, "_update_selected_item")

	$AudioStreamPlayer.play(0)

func _update_selected_item(selected_item, costs_or_null):
	tower_updated = true
	_currently_selected_item = selected_item
	_current_costs = costs_or_null


func _current_item_is_tool() -> bool: return _currently_selected_item in Globals.TOOLS
func _current_item_is_plant() -> bool: return _currently_selected_item in Globals.PLANTS
func _current_item_is_tower() -> bool: return _currently_selected_item in Globals.TOWERS

func _can_afford():
	return _current_costs != null and get_player_inventory().can_pay(_current_costs)

func _can_place_at(world_pos: Vector2) -> bool:
	var map_pos = map.world_to_map(world_pos)

	if _current_item_is_tool() or map.is_building_at(map_pos) or not _can_afford():
		return false
	if _current_item_is_plant():
		return map.has_farmable_ground(map_pos)
	if _current_item_is_tower():
		if _currently_selected_item == Globals.ItemType.TowerWaterwheel:
			return map.has_waterwheel_suitable_ground(map_pos)
		else:
			return map.has_tower_suitable_ground(map_pos)

	return false

func _create_current_item_at(snap_pos, is_active := true) -> Node2D:
	var item: Node2D = ITEM_PRELOADS[_currently_selected_item].instance()
	map.add_child(item)
	item.global_position = snap_pos
	item.is_active = is_active

	# TODO Throws Error because items of type Plant do not have those signals (yet)
	if item.is_in_group("Tower"):
		item.connect("hover_started", self, "emit_signal", ["hover_start_tower", snap_pos, item])
		item.connect("hover_ended", self, "emit_signal", ["hover_end_tower"])
		item.connect("clicked", self, "_on_tower_clicked", [snap_pos, item])
	return item

func _on_ModalButton_pressed():
	emit_signal("unselect_tower")
	$ModalButton.visible = false

func _on_tower_clicked(snap_pos, item):
	emit_signal("select_tower", snap_pos, item)
	$ModalButton.visible = true

func get_player_inventory():
	return player.get_inventory()

func _maybe_remove_farmland(map_pos: Vector2):
	if map.maybe_remove_farmland(map_pos):
		var plant = __plant_store.get(map_pos)
		if plant != null:
			plant.queue_free()
			__plant_store.erase(map_pos)
			map.building_place_or_remove(map_pos)

func _on_tower_removed(map_pos: Vector2):
	__tower_store.erase(map_pos)
	emit_signal("unselect_tower")
	map.on_tower_destroyed(map_pos)

	for pos in map.l_ground.get_positions_in_radius(map_pos):
		_maybe_remove_farmland(pos)

	_check_plants_around(map_pos)

	tower_updated = true

func _process(_delta):
	var is_mouse_down = $ToolButton.pressed
	var player_pos = map.world_to_map(player.global_position)
	var use_tool = is_mouse_down || Input.is_action_pressed("use_tool")
	if _current_item_is_tool():
		if not use_tool && is_using:
			is_using = false
			player.end_use_tool()
		elif use_tool && not is_using \
			|| (use_tool && is_using && player_pos != last_player_pos):
			player.begin_use_tool(self)
			is_using = true
			last_player_pos = player_pos

	var hover_coord = get_global_mouse_position()
	var snap_pos = map.snap_to_grid_center(hover_coord)

	if last_tower_location != snap_pos || tower_updated:
		tower_updated = false
		last_tower_location = snap_pos
		
		if last_tower:
			map.remove_child(last_tower)
			last_tower = null

		if _can_place_at(snap_pos):
			var tower = _create_current_item_at(snap_pos, false)
			last_tower = tower
			if _current_item_is_tower():
				map.update_preview_ground(snap_pos, tower.farmland_radius)
			else:
				map.remove_preview_ground()
		else:
			map.remove_preview_ground()

	if is_mouse_down && last_tower != null:
		last_tower.is_active = true
		var item = last_tower
		last_tower = null
		map.remove_preview_ground()
		var map_pos = map.world_to_map(snap_pos)

		if _current_item_is_tower():
			map.building_place_or_remove(map_pos, map.l_building.building_tower_id)
			map.set_ground_around_tower(map_pos, item.farmland_radius)

			__tower_store[map_pos] = item

			for plant in _get_plants_around(map_pos):
				plant._buff_tower([item])
			_check_plants_around(map_pos)

			# connect Tower remove handler to remove from both data structures on Tower death
			item.connect("tree_exiting", self, "_on_tower_removed", [map_pos], CONNECT_ONESHOT)
			item.connect("enemy_killed", map, "_on_tower_killed_enemy")
		elif _current_item_is_plant():
			map.building_place_or_remove(map_pos, map.l_building.building_plant_id)
			__plant_store[map_pos] = item
			var towers_around = _get_towers_around(map_pos)
			item._buff_tower(towers_around)
			item._check_tower_keep_alive(towers_around)
		get_player_inventory().pay(_current_costs)
