extends Node2D

var state = 0

const MIN_GROW_TIME = 5
const MAX_GROW_TIME = 10

export var active := false

onready var timer = $Timer

func _ready():
	randomize()
	timer.wait_time= rand_range(MIN_GROW_TIME, MAX_GROW_TIME)

func _on_grow():
	if active:
		state += 1
		timer.wait_time= rand_range(MIN_GROW_TIME, MAX_GROW_TIME)
		print("Grow")
