extends StaticBody2D

const ENEMY_PRELOAD = preload("res://scenes/Enemy.tscn")

export (int) var spawn_radius = 1
export (float) var spawn_probability_per_secs = 0.1
export (float) var cooldown_in_secs = 3.2

var cooldown_counter: float = 0

signal spawn_enemy(enemy, coord, radius)

func spawn():
	var enemy = ENEMY_PRELOAD.instance()
	emit_signal('spawn_enemy', enemy, position, spawn_radius)

func _ready():
	pass

func _process(delta):
	cooldown_counter += delta
	if (cooldown_counter >= cooldown_in_secs
			and randf() / delta < spawn_probability_per_secs):
		spawn()
		cooldown_counter = 0
