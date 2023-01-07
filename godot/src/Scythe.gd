extends Node2D


onready var anim := $AnimationPlayer
onready var sprite := $Sprite

const anim_map = {
	false: "swing-right",
	true: "swing-left"
}

func flip_h(val):
	sprite.flip_h = val

func swing():
	anim.play(anim_map[sprite.flip_h])

func stop_swing():
	anim.play("RESET")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


# Called every frame. 'delta' is the elapsed time since the previous frame.
#func _process(delta):
#	pass
