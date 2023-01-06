extends KinematicBody2D


func _ready():
	pass


func _process(delta):
	var dir_x = Input.get_axis("left", "right")
	var dir_y = Input.get_axis("up", "down")
	var dir = Vector2(dir_x, dir_y)
	if dir.x == 0 && dir.y == 0:
		$AnimationRoot/AnimationPlayer.current_animation = "idle"
	else:
		$AnimationRoot/AnimationPlayer.current_animation = "walk"
	move_and_collide(dir)
	pass
