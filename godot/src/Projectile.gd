extends Node2D


# Declare member variables here. Examples:
export (int) var speed = 200
onready var target = global_position
var velocity = Vector2()

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func shoot_target(target_pos):
	target = target_pos

func _physics_process(delta):
	velocity = global_position.direction_to(target) * speed
	global_position += velocity * delta
