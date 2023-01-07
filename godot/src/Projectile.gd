extends Node2D


var speed: float = 200
var damage: float = 1
var target: Vector2

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func shoot_target(target_pos: Vector2):
	target = target_pos

func _physics_process(delta: float):
	if global_position.is_equal_approx(target):
		# TODO: damage to enemies
		queue_free()
	global_position = global_position.move_toward(target, speed * delta)
