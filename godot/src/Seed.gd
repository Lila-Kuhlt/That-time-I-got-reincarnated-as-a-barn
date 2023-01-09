extends Node2D

const TOWER_MULT = [
	0.1,
	0.5,
	1.0,
	0.0
]

var state = Globals.GlowState.Seed
var tower_stats = []

onready var timer = $Timer
onready var sprite = $Sprite
onready var MAX_STATE = Globals.GlowState.size()
onready var stats = $StatsStatic

export var MIN_GROW_TIME = 1
export var MAX_GROW_TIME = 1
export var FINAL_FORM_MULT = 4

signal on_grow (state)

var is_active = false setget _set_is_active

func _ready():
	randomize()
	_update_time()
	emit_signal("on_grow", state)

func _on_grow():
	if not is_active:
		return
	state += 1
	sprite.set_frame(state)
	for tower_stat in tower_stats:
		if not is_instance_valid(tower_stat[0]):
			tower_stats.erase(tower_stat[0])
		else:
			update_tower_stat(tower_stat[0], tower_stat[1])
	
	if state <= MAX_STATE - 1:
		_update_time()
		emit_signal("on_grow", state)
	if state >= MAX_STATE:
		is_active = false
		emit_signal("on_grow", -1)
		timer.stop()
		
func _update_time():
	var new_duration = rand_range(MIN_GROW_TIME, MAX_GROW_TIME)
	
	if state == MAX_STATE -1:
		new_duration = new_duration * FINAL_FORM_MULT
	
	timer.start(new_duration)

func _set_is_active(v:bool):
	is_active = v
	modulate.a = 1 if is_active else 0.4

func _buff_tower(towers):
	for tower in towers:
		var new_stat = stats.duplicate()
		tower.stats.add_child(new_stat)
		update_tower_stat(tower, new_stat)
		tower_stats.append([tower, new_stat])

func get_mult_state():
	return TOWER_MULT[state]
	
func update_tower_stat(tower, stat):
	stat.multiplicator = get_mult_state()
	tower.stats.calc_stats()
