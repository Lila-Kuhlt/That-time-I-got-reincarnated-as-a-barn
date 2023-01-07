extends KinematicBody2D

onready var anim := $AnimationRoot/AnimationPlayer
onready var scythe := $AnimationRoot/Scythe
onready var anim_root := $AnimationRoot

enum Direction {
	None,
	Left,
	Right
}

const flip_map := {
	Direction.Right: Vector2(1, 1),
	Direction.Left: Vector2(-1, 1)
}

var current_dir = Direction.Right

func _ready():
	pass

func flip(val):
	 anim_root.scale = flip_map[val]

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

	var current_dir = (Direction.Right if dir.x > 0
						else Direction.Left if dir.x < 0
						else Direction.None)

	if current_dir != Direction.None && self.current_dir != current_dir:
		self.current_dir = current_dir
		flip(current_dir)

	move_and_collide(dir)
