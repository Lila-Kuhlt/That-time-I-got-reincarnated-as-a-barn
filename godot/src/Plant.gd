extends Node2D

const TOWER_MULT = [
	0.1,
	0.5,
	1.0,
	0.0,
]

const DROP_RATES = [0, 0, 1, 0]

# Shader stuff
const PLANT_MATERIAL = preload("res://shaders/PlantMaterial.tres") 
onready var plant_material = PLANT_MATERIAL.duplicate()
const BORDER_COLOR_WARMUP := Color(1, 1, 1, 0)
const BORDER_COLOR_READY := Color(1, 1, 1, 1)
const BORDER_COLOR_ROTTING := Color(0.7, 0, 0, 1)
const TIME_WARMUP = 0.5
const TIME_ROT_WARN = 8.0

onready var timer: Timer = $Timer
onready var animator: AnimationPlayer = $AnimationPlayer
onready var tween: Tween = $Tween
onready var sprite: Sprite = $Sprite
onready var MAX_STATE := Globals.GrowState.size() - 1
onready var stats := $StatsStatic

export var MIN_GROW_TIME = 1
export var MAX_GROW_TIME = 1
export var FINAL_FORM_MULT = 4

export var plant_type = Globals.ItemType.PlantChili

var state = Globals.GrowState.Seedling
var tower_stats = []
var _current_duration := 0.0
var is_active := false setget _set_is_active
var can_rot := true

func _ready():
	_start_timer()

func _on_grow():
	if not is_active or (not can_rot and state == Globals.GrowState.Grown):
		return
		
	state += 1
	if state < MAX_STATE:
		_start_timer()
	if state >= MAX_STATE:
		is_active = false
		timer.stop()
	
	animator.play("grow") # calls _update_sprite_frame() after a short time
	update_tower_stat()

# called by AnimationPlayer at peak of animation
func _update_sprite_frame():
	sprite.set_frame(state)
	_update_shader()

func _update_shader():
	if state == Globals.GrowState.Grown:
		sprite.material = plant_material
		
		var time_rot := min(TIME_ROT_WARN, _current_duration)
		var time_warmup := min(TIME_WARMUP, _current_duration - time_rot)
		var time_ready := _current_duration - (time_warmup + time_rot)
		
		tween.interpolate_property(sprite, "material:shader_param/color", BORDER_COLOR_WARMUP, BORDER_COLOR_READY, time_warmup)
		tween.interpolate_property(sprite, "material:shader_param/color", BORDER_COLOR_READY, BORDER_COLOR_ROTTING, time_rot, 0, 2, time_warmup + time_ready)
		tween.start()
	else:
		sprite.material = null
		tween.stop_all()

func _start_timer():
	_current_duration = rand_range(MIN_GROW_TIME, MAX_GROW_TIME)

	if state == Globals.GrowState.Grown:
		_current_duration *= FINAL_FORM_MULT

	timer.start(_current_duration)

func _set_is_active(v: bool):
	is_active = v
	modulate.a = 1.0 if is_active else 0.4

func _buff_tower(towers):
	for tower in towers:
		var new_stat = stats.duplicate()
		tower.stats.add_child(new_stat)
		tower_stats.append([tower, new_stat])
	update_tower_stat()

# check if the plant is kept alive (i.e. not rotten) by any of the towers
func _check_tower_keep_alive(towers):
	for tower in towers:
		if tower.keep_alive:
			can_rot = false
			return
	can_rot = true

func get_mult_state():
	return TOWER_MULT[state]

func update_tower_stat():
	var new_tower_stats := []
	for tower_stat in tower_stats:
		if is_instance_valid(tower_stat[0]):
			tower_stat[1].multiplicator = get_mult_state()
			tower_stat[0].stats.calc_stats()
			new_tower_stats.append(tower_stat)
	tower_stats = new_tower_stats

# Returns number of drops
func harvest() -> int: # The Holy Harvest Function
	var drops = DROP_RATES[state]

	if state == Globals.GrowState.Rotten or state == Globals.GrowState.Grown:
		state = 0
		is_active = true
		sprite.set_frame(state)
		emit_signal("on_grow", state)
		_update_shader()
		_start_timer()
		update_tower_stat()
	return drops
