extends Node2D

var state = 0

const STATE_MAX = 4
const MIN_GROW_TIME = 5
const MAX_GROW_TIME = 10

signal on_grow (state)

export var active := false

onready var timer = $Timer
onready var sprite = $Sprite

func _ready():
	randomize()
	_update_time()
	emit_signal("on_grow", state)

func _on_grow():
	if active:
		state += 1
		if state < STATE_MAX:
			sprite.set_frame(state)
			print("Grow")
			_update_time()
			emit_signal("on_grow", state)
		else:
			active = false
			emit_signal("on_grow", -1)
			sprite.visible = false
		
func _update_time():
	var new_duration = rand_range(MIN_GROW_TIME, MAX_GROW_TIME)
	timer.wait_time = new_duration
	print(new_duration)
