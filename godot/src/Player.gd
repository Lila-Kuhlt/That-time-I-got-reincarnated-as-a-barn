extends KinematicBody2D

onready var _anim_player := $AnimationRoot/AnimationPlayer
onready var _anim_root := $AnimationRoot

enum Direction {
	None,
	Left,
	Right,
	Up,
	Down
}

const direction_map := {
	Direction.Up: ["walk_up", Vector2(1, 1)],
	Direction.Right: ["walk_side", Vector2(1, 1)],
	Direction.Left: ["walk_side", Vector2(-1, 1)],
	Direction.Down: ["walk_down", Vector2(1, 1)],
	Direction.None: ["RESET", Vector2(1, 1)]
}

var current_dir = Direction.None

func _ready():
	pass

func _apply_animation(direction):
	var anim : String = direction_map[direction][0]
	var scale : Vector2 = direction_map[direction][1]
	_anim_player.play(anim)
	_anim_root.scale = scale
	self.current_dir = direction

func _physics_process(delta):
	var dir_x := Input.get_axis("left", "right")
	var dir_y := Input.get_axis("up", "down")
	var dir := Vector2(dir_x, dir_y)
	var current_dir = ( Direction.Right if dir.x > 0
						else Direction.Left if dir.x < 0
						else Direction.Up if dir.y < 0
						else Direction.Down if dir.y > 0
						else Direction.None)

	if self.current_dir != current_dir:
		_apply_animation(current_dir)

	move_and_collide(dir)
