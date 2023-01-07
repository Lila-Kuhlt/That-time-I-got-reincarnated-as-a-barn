extends KinematicBody2D

onready var anim := $AnimationRoot/AnimationPlayer
onready var sprite := $AnimationRoot/PlayerSprite

func _ready():
	pass


func _process(delta):
	var dir_x := Input.get_axis("left", "right")
	var dir_y := Input.get_axis("up", "down")
	var dir := Vector2(dir_x, dir_y)
	if dir.x == 0 && dir.y == 0:
		anim.current_animation = "idle"
	else:
		anim.current_animation = "walk"
	if dir.x > 0:
		sprite.flip_h = false
	elif dir.x < 0:
		sprite.flip_h = true

	move_and_collide(dir)
	pass
