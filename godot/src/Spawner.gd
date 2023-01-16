extends "res://src/Enemy.gd"

const ENEMY_MAP = {
	Globals.EnemyType.Racoon: preload("res://scenes/enemies/Racoon.tscn"),
	Globals.EnemyType.Rabbit: preload("res://scenes/enemies/Rabbit.tscn"),
	Globals.EnemyType.Ant: preload("res://scenes/enemies/Ant.tscn")
}

var type = randi() % len(Globals.EnemyType)

export (int) 	var spawn_radius : int = 1
export (float) 	var spawn_probability_per_tick : float = 0.0876 # = ~0.6 per second
export (int) 	var ticks_per_second : int = 10

# Cooldown related
export (float) 	var cooldown_in_secs : float = 8.5
export (float) 	var spawn_cooldown_decrease : float = 0.022 # per second
export (float)	var min_cooldown : float = 1

var _chain_link

var enemy_target = null
var spawner_active = false
var spawner_order_id = -1

var _tick_time : float
var _cooldown_counter: float = 0
var _tick_counter : float = 0
var _has_cooldown := false

var _map = null

func _init():
	_tick_time = 1.0/ticks_per_second

func _ready():
	connect("enemy_died", get_chain_link(), "_on_spawner_destroyed")
	_set_active(false)
	
func _set_active(v):
	._set_active(v)
	visible = v
	
func activate_spawner(set_target = null):
	if set_target != null:
		enemy_target = set_target
	_set_active(true)
	self.spawner_active = true #$GraceTimer.start() TODO dont want to wait
	
func deactivate_spawner():
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
	var free_areas = []
	var map_pos : Vector2 = _map.world_to_map(position)
	for dx in range(-spawn_radius, spawn_radius + 1):
		for dy in range(-spawn_radius, spawn_radius + 1):
			var d := Vector2(dx, dy)
			if d != Vector2.ZERO and _map.can_place_building_at(map_pos + d):
				free_areas.append(map_pos + d)
	if len(free_areas) == 0:
		return false
	var enemy = ENEMY_MAP[type].instance()
	var spawn_position = _map.map_to_world(free_areas[randi() % len(free_areas)])
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
