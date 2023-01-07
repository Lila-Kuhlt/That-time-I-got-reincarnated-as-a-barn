extends Node2D

var state = 0

const MAX_STATE = 3
const MIN_GROW_TIME = 1
const MAX_GROW_TIME = 1
const FINAL_FORM_MULT = 4

signal on_grow (state)

export var active := false

onready var timer = $Timer
onready var sprite = $Sprite

func _ready():
	randomize()
	_update_time()
	emit_signal("on_grow", state)

func _on_grow():
	if not active:
		return
	state += 1
	sprite.set_frame(state)
	if state <= MAX_STATE - 1:
		_update_time()
		emit_signal("on_grow", state)
	if state >= MAX_STATE:
		active = false
		emit_signal("on_grow", -1)
		timer.stop()
		print("DONE GROWING")
		
func _update_time():
	var new_duration = rand_range(MIN_GROW_TIME, MAX_GROW_TIME)
	
	if state == MAX_STATE -1:
		new_duration = new_duration * FINAL_FORM_MULT
		print("FINAL_FORM")
	print(new_duration)
	timer.start(new_duration)
