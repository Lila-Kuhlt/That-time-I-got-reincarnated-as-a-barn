extends StaticBody2D

const ENEMY_PRELOAD = preload("res://scenes/enemies/Racoon.tscn")

export (int) 	var spawn_radius = 1
export (float) 	var spawn_probability_per_tick = 0.0876 # = ~0.6 per second
export (int) 	var ticks_per_second : int = 10

# Cooldown related
export (float) 	var cooldown_in_secs = 3.2
export (float) 	var spawn_cooldown_decrease = 0.2 # per second
export (float)	var min_cooldown = 0.5

var _tick_time : float
var _cooldown_counter: float = 0
var _tick_counter : float = 0
var _has_cooldown := false

var _map = null

func _init():
	_tick_time = 1.0/ticks_per_second

func _spawn() -> bool:
	assert(_map)
	if not Globals.can_spawn_enemy():
		return false 
	var enemy = ENEMY_PRELOAD.instance()
	var free_areas = []
	var map_pos : Vector2 = _map.world_to_map(position)
	for dx in range(-spawn_radius, spawn_radius + 1):
		for dy in range(-spawn_radius, spawn_radius + 1):
			var d := Vector2(dx, dy)
			if d != Vector2.ZERO and _map.can_place_building_at_map_pos(map_pos + d):
				free_areas.append(map_pos + d)
	if len(free_areas) == 0:
		return false
	var spawn_position = _map.map_to_world(free_areas[randi() % len(free_areas)])
	enemy.warp_to(spawn_position)
	_map.add_child(enemy)
	return true

func set_map(map):
	_map = map

func _do_tick():
	if randf() < spawn_probability_per_tick:
		_has_cooldown = _spawn()
		_cooldown_counter = 0

func _physics_process(delta):
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
