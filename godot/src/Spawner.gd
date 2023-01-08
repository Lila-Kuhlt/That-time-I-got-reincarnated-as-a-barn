extends StaticBody2D

const ENEMY_PRELOAD = preload("res://scenes/Enemy.tscn")

export (int) var spawn_radius = 1
export (float) var spawn_probability_per_secs = 0.1
export (float) var cooldown_in_secs = 3.2

var _cooldown_counter: float = 0
var _has_cooldown := false

var _map = null

func _spawn() -> bool:
	assert(_map)
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

func _physics_process(delta):
	if _has_cooldown:
		_cooldown_counter += delta
		if _cooldown_counter >= cooldown_in_secs:
			_has_cooldown = false
	elif randf() / delta < spawn_probability_per_secs:
		_has_cooldown = _spawn()
		_cooldown_counter = 0
