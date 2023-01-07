extends KinematicBody2D

const MAX_SPEED = 20

var current_target_type = Target.NONE
var current_target: Node2D = null
var health: float = 3.0

enum Target {
	NONE = 0
	TOWER = 1
	PLAYER = 2
}

export var path := NodePath()

onready var _agent = $NavigationAgent2D

func set_target(node: Node2D):
	current_target = node

# called when the enemy is hit by a projectile
func hit(damage: float):
	# TODO: play hit animation?
	health -= damage
	if health <= 0.0:
		# enemy dies
		queue_free()

func _physics_process(delta: float):
	# Update Goal
	if current_target != null and current_target.is_inside_tree():
		_agent.set_target_location(current_target.position)
	else:
		# TODO: set default target (farmhouse)
		return

	if not _agent.is_navigation_finished():
		var next_location = _agent.get_next_location()
		var velocity := position.direction_to(next_location) * MAX_SPEED * delta
		_agent.set_velocity(velocity)
		move_and_collide(velocity)

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

func _on_Area2D_area_entered(area: Node2D):
	var target = area.get_parent()
	var collision_priority = Target.NONE
	if target.is_in_group("Player"):
		collision_priority = Target.PLAYER
	elif target.is_in_group("Tower"):
		collision_priority = Target.TOWER

	if collision_priority > current_target_type:
		current_target_type = collision_priority
		current_target = target
		_agent.set_target_location(current_target.position)
