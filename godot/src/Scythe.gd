extends Node2D

onready var anim := $AnimationPlayer
onready var sfx := $AudioStreamPlayer

var is_swinging = false setget _is_swinging_set,_is_swinging_get

func swing():
	if ! is_swinging :
		is_swinging = true
		anim.play("swing")
		sfx.play()

func _is_swinging_set(_value):
	assert(false)

func _is_swinging_get():
	return is_swinging

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_animation_finished(_anim_name):
	is_swinging = false
