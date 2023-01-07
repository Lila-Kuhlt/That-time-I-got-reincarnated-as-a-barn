extends KinematicBody2D

const MAX_SPEED = .5
const DEFAULT_POS = Vector2(100.0, 100.0)

var current_target:Node2D = null

export var path := NodePath()

onready var _agent = $NavigationAgent2D

func set_target(node: Node2D):
	pass

func _process(delta):
	# Update Goal
	if current_target != null:
		_agent.set_target_location(current_target.global_position)
		pass
	
	if not _agent.is_navigation_finished():
		var next_location = _agent.get_next_location()
		var dir := position.direction_to(next_location)
		var velocity = dir * MAX_SPEED
		_agent.set_velocity(velocity)
		move_and_collide(dir)

# Called when the node enters the scene tree for the first time.
func _ready():
	_agent.set_target_location(DEFAULT_POS)
	pass # Replace with function body.
	
func _get_current_arraction(node: Node2D) -> int:
	if node == null:
		return 0
	elif node.get_parent().is_in_group(("Tower")):
		return 1
	elif node.get_parent().is_in_group(("Player")):
		return 2
	return 1

# Check if the Player is still targeted if he respawns
func _on_Area2D_area_entered(area: Node2D):
	if _get_current_arraction(area) > _get_current_arraction(current_target):
		current_target = area
		_agent.set_target_location(current_target.global_position)
