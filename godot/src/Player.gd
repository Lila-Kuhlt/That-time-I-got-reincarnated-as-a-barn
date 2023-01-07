extends KinematicBody2D

onready var anim := $AnimationRoot/AnimationPlayer
onready var sprite := $AnimationRoot/PlayerSprite
onready var scythe := $Scythe

func _ready():
	pass


func _process(delta):
	var dir_x := Input.get_axis("left", "right")
	var dir_y := Input.get_axis("up", "down")
	var dir := Vector2(dir_x, dir_y)
	if dir.x == 0 && dir.y == 0:
		anim.play("idle")
		scythe.swing()
	else:
		anim.play("walk")
		scythe.stop_swing()
	if dir.x > 0:
		sprite.flip_h = false
		scythe.flip_h(false)
	elif dir.x < 0:
		sprite.flip_h = true
		scythe.flip_h(true)

	move_and_collide(dir)
