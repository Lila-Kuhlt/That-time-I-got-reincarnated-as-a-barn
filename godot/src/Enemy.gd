extends KinematicBody2D

const MAX_SPEED = 20

export (float, 0, 500) var health: float = 3.0

var _current_target_type = Target.NONE
var _current_target: Node2D = null

enum Target {
	NONE = 0
	TOWER = 1
	PLAYER = 2
}

var targets := [[null],[],[]] #TODO: replace null with default target

onready var _agent = $NavigationAgent2D
onready var animation_player = $AnimationRoot/AnimationPlayer

func _set_target(node: Node2D = null, type = Target.NONE):
	if _current_target == node:
		return

	if _current_target != null:
		_current_target.disconnect("tree_exited", self, "_reevaluate_target")

	if node != null:
		assert(node.is_inside_tree())
		node.connect("tree_exited", self, "_reevaluate_target", [type])

	_current_target = node
	_current_target_type = type

func _is_target_valid() -> bool:
	assert(_current_target == null || _current_target.is_inside_tree())
	return _current_target != null

func _reevaluate_target(priority):
	if priority < _current_target_type:
		return

	while priority > Target.NONE && targets[priority].size() == 0:
		priority = priority - 1

	_set_target(targets[priority][0], priority)

func warp_to(coord: Vector2):
	position = coord

# called when the enemy is hit by a projectile
func damage(damage: float):
	assert(damage >= 0.0)
	# TODO: play hit animation?
	health -= damage
	if health <= 0.0:
		# enemy dies
		queue_free()

func _physics_process(delta: float):
	# Update Goal
	#TODO: target should always be set after main buildig is added
	if _is_target_valid():
		_agent.set_target_location(_current_target.global_position)
	else:
		# TODO: set default target (farmhouse)
		return

	if not _agent.is_navigation_finished():
		var next_location = _agent.get_next_location()
		var velocity := position.direction_to(next_location) * MAX_SPEED * delta
		_agent.set_velocity(velocity)
		move_and_collide(velocity)

	_update_animation()

func _update_animation():
	if _is_target_valid():
		animation_player.play("run")
	else:
		animation_player.seek(0.0, true)
		animation_player.stop()

func _ready():
	pass

func _get_priority(target: Node2D):
	var collision_priority = Target.NONE
	if target.is_in_group("Player"):
		collision_priority = Target.PLAYER
	elif target.is_in_group("Tower"):
		collision_priority = Target.TOWER
	return collision_priority

func _on_field_of_view_entered(target: Node2D):
	var collision_priority = _get_priority(target)
	targets[collision_priority].append(target)
	_reevaluate_target(collision_priority)

func _on_field_of_view_left(target: Node2D):
	var priority = _get_priority(target)
	targets[priority].erase(target)
	_reevaluate_target(priority)
	_update_animation()
