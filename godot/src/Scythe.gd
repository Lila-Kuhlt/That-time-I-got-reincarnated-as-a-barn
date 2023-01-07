extends Node2D

onready var anim := $AnimationPlayer

func swing():
	anim.play("swing")

func stop_swing():
	anim.play("RESET")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
