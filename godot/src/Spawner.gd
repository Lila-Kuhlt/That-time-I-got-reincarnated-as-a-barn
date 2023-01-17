extends "res://src/Enemy.gd"

const ENEMY_MAP = {
	Globals.EnemyType.Racoon: preload("res://scenes/enemies/Racoon.tscn"),
	Globals.EnemyType.Rabbit: preload("res://scenes/enemies/Rabbit.tscn"),
	Globals.EnemyType.Ant: preload("res://scenes/enemies/Ant.tscn")
}

var type = randi() % len(Globals.EnemyType)

export (int) 	var spawn_radius : int = 0
export (float) 	var spawn_probability_per_tick : float = 0.0876 # = ~0.6 per second
export (int) 	var ticks_per_second : int = 10

# Cooldown related
export (float) 	var cooldown_in_secs : float = 8.5
export (float) 	var spawn_cooldown_decrease : float = 0.022 # per second
export (float)	var min_cooldown : float = 1

var _chain_link
var _map_path : MapPath

var enemy_target = null
var spawner_active = false
var spawner_order_id = -1

var _tick_time : float
var _cooldown_counter: float = 0
var _tick_counter : float = 0
var _has_cooldown := false

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

func _init():
	_tick_time = 1.0/ticks_per_second

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
			
#			# DEBUG SHOW ALL POSITIONS
#			var p = preload("res://scenes/Projectile.tscn").instance()
#			p.speed = 0
#			get_parent().add_child(p)
#			p.global_position = target_world_pos
#			yield(get_tree().create_timer(0.3), "timeout")
			
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
	$GraceTimer.start()

# Manhat
func dst_man(a: Vector2, b: Vector2):
	return abs(a.x - b.x) + abs(a.y - b.y)
	
func deactivate_spawner():
	_try_hide_map_path()
		
	_set_active(false)
	spawner_active = false

func _can_spawn_enemy() -> bool:
	return Globals.curr_enemies < Globals.MAX_ENEMIES

# Manages the order of the Spawners and Barns
func get_chain_link():
	if not _chain_link:
		_chain_link = $ChainLink
	return _chain_link
	
func _spawn() -> bool:
	assert(_map, "_map is not set")
	assert(type != null, "EnemyType is not set for the spawner.")
	if not Globals.can_spawn_enemy():
		return false
	
#   # SPAWN ON SPAWNER FOR NOW
#	var map_pos : Vector2 = _map.world_to_map(position)
#	for dx in range(-spawn_radius, spawn_radius + 1):
#		for dy in range(-spawn_radius, spawn_radius + 1):
#			var d := Vector2(dx, dy)
#			if d != Vector2.ZERO and _map.can_place_building_at(map_pos + d):
#				free_areas.append(map_pos + d)
#	if len(free_areas) == 0:
#		return false
	var free_areas = [_map.world_to_map(global_position)]
	
	var enemy = ENEMY_MAP[type].instance()
	var spawn_position = _map.map_to_world(free_areas[randi() % len(free_areas)]) + Vector2(16, 16)
	enemy.warp_to(spawn_position)
	enemy.initial_target_barn = enemy_target
	_map.add_child(enemy)
	return true

func set_map(map):
	_map = map

func _do_tick():
	if randf() < spawn_probability_per_tick:
		_has_cooldown = _spawn()
		_cooldown_counter = 0

func _physics_process(delta):
	if not spawner_active:
		return
	cooldown_in_secs -= spawn_cooldown_decrease * delta
	cooldown_in_secs = max(min_cooldown, cooldown_in_secs)
	if _has_cooldown:
		_cooldown_counter += delta
		if _cooldown_counter >= cooldown_in_secs:
			_has_cooldown = false
			_tick_counter = cooldown_in_secs - _cooldown_counter
	else:
		_tick_counter += delta

	while(_tick_counter >= _tick_time and not _has_cooldown):
		_tick_counter -= _tick_time
		_do_tick()

func _on_RotationTimer_timeout():
	type = randi() % len(Globals.EnemyType)
	$RotationTimer.start(randi() % 5 + 10)

func _on_GraceTimer_timeout():
	self.spawner_active = true
