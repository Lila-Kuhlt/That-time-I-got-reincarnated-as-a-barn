extends Node2D

var state = 0

onready var timer = $Timer
onready var sprite = $Sprite
onready var MAX_STATE = sprite.get_hframes() * sprite.get_vframes() - 1

export var MIN_GROW_TIME = 1
export var MAX_GROW_TIME = 1
export var FINAL_FORM_MULT = 4

signal on_grow (state)

export var active := false

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
		
func _update_time():
	var new_duration = rand_range(MIN_GROW_TIME, MAX_GROW_TIME)
	
	if state == MAX_STATE -1:
		new_duration = new_duration * FINAL_FORM_MULT
	print(new_duration)
	timer.start(new_duration)
