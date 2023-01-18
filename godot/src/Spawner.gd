extends "res://src/Enemy.gd"

const RAB = Globals.EnemyType.Rabbit
const ANT = Globals.EnemyType.Ant
const RAC = Globals.EnemyType.Racoon

const ENEMY_MAP = {
	RAB: preload("res://scenes/enemies/Rabbit.tscn"),
	ANT: preload("res://scenes/enemies/Ant.tscn"),
	RAC: preload("res://scenes/enemies/Racoon.tscn"),
}

const GRACE_TIME := 8.0 # sec
const CD_MEAN_INITIAL := 12.0 # sec
const CD_MEAN_DECAY := 0.04 # per sec
const CD_MEAN_MIN := 2 # sec
const SPAWN_RADIUS: int = 0

const WAVE_POOL = [
	[ # Level 1
		[RAB], [ANT]
	], [ # Level 2
		[RAB], [ANT, ANT]
	], [ # Level 3
		[RAB, RAB], [ANT, ANT, ANT], [RAC]
	], [ # Level 4
		[RAB, ANT, ANT], [RAB, RAB, ANT], [RAC]
	], [ # Level 5
		[RAB, RAB, RAB], [ANT, ANT, ANT, ANT], [RAC, RAC]
	], [ # Level 6
		[RAC, RAC, RAC, RAC]
	]
]

var _chain_link
var _map_path : MapPath

var current_cd = CD_MEAN_INITIAL
var current_timer = 0

var wave_pool_level = 0
var enemy_target = null
var spawner_active = false

var _map = null

class MapPath:
	var _has_started := false
	var _is_done := false
	var _map_positions := []
	var start_pos : Vector2
	var target_pos : Vector2
	func _init(start_pos: Vector2, target_pos: Vector2):
		self.start_pos = start_pos
		self.target_pos = target_pos
	func add_map_pos(map_pos: Vector2):
		if not _has_started:
			assert(map_pos.is_equal_approx(start_pos), "First map pos must be start pos")
			_has_started = true
		assert(not _is_done, "Path has already reached target pos")
		if not _is_done and map_pos.is_equal_approx(target_pos):
			_is_done = true
		_map_positions.append(map_pos)
	func get_path_map_positions() -> Array:
		assert(_is_done, "Path is not yet done, target pos has not been added yet")
		return _map_positions

func _ready():
	connect("enemy_died", get_chain_link(), "_on_spawner_destroyed")
	connect("enemy_died", self, "_try_hide_map_path")
	_set_active(false)
	
func _set_active(v):
	._set_active(v)
	visible = v
	
func _try_hide_map_path():
	if _map_path != null:
		_map.l_path.unregister_spawner_path(_map_path)
		_map_path = null
			
func activate_spawner(set_target = null):
	if set_target != null:
		
		_try_hide_map_path()
		
		
		enemy_target = set_target
		_agent.set_target_location(enemy_target.global_position)
		if not _agent.is_target_reachable():
			printerr("Error, could not find path from Spawner to target")
			return

		var pos_start = _map.world_to_map(global_position)
		var pos_target = _map.world_to_map(enemy_target.global_position)
		_map_path = MapPath.new(pos_start, pos_target)
		
		_map_path.add_map_pos(pos_start)
		
		var world_pos_last = global_position
		var map_pos_last: Vector2 = pos_start
		for target_world_pos in _agent.get_nav_path():
			var target_map_pos: Vector2 = _map.world_to_map(target_world_pos)
			var cur_map_pos = map_pos_last
			while cur_map_pos != target_map_pos:
				var dir = cur_map_pos.direction_to(target_map_pos)
				if abs(dir.x) > abs(dir.y):
					cur_map_pos.x += sign(dir.x)
				elif abs(dir.x) < abs(dir.y):
					cur_map_pos.y += sign(dir.y)
				else:
					cur_map_pos.y += sign(dir.y)
				_map_path.add_map_pos(cur_map_pos)
			map_pos_last = cur_map_pos	
		_map.l_path.register_spawner_path(_map_path)
	
	_set_active(true)
	$GraceTimer.start(GRACE_TIME)

func deactivate_spawner():
	_try_hide_map_path()
	_set_active(false)
	spawner_active = false

func _on_GraceTimer_timeout():
	self.spawner_active = true

# Manages the order of the Spawners and Barns
func get_chain_link():
	if not _chain_link:
		_chain_link = $ChainLink
	return _chain_link

func _physics_process(delta):
	if not spawner_active:
		return
		
	current_cd = max(current_cd - CD_MEAN_DECAY * delta, CD_MEAN_MIN)
	current_timer -= delta
	
	if current_timer < 0:
		current_timer += current_cd
		_spawn_wave()

func _spawn_wave():
	var wave_pool = WAVE_POOL[min(wave_pool_level, WAVE_POOL.size() - 1)]
	var wave = wave_pool[randi() % wave_pool.size()]
	for enemy_type in wave:
		_spawn_enemy(enemy_type)
	
func _spawn_enemy(enemy_type) -> bool:
	assert(_map, "_map is not set")
	if not Globals.can_spawn_enemy():
		return false
	
	var map_pos : Vector2 = _map.world_to_map(position)
	var free_areas = [map_pos]
	
	for target_pos in _map.l_ground.get_positions_in_radius(map_pos, 1):
		if _map.can_place_building_at(target_pos):
			free_areas.append(target_pos)
			
	if len(free_areas) == 0:
		return false
	
	var enemy = ENEMY_MAP[enemy_type].instance()
	var spawn_pos_map = free_areas[randi() % len(free_areas)]
	var spawn_pos_world = _map.map_to_world_center(spawn_pos_map)
	
	enemy.initial_target_barn = enemy_target
	_map.add_child(enemy)
	enemy.global_position = spawn_pos_world
	return true

func set_map(map):
	_map = map
