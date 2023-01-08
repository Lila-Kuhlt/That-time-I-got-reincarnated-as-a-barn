extends KinematicBody2D

const MAX_SPEED = 20

export (float, 0, 500) var health: float = 3.0

var _current_target_type = Target.NONE
var _current_target: Node2D = null

enum Target {
	NONE = 0
	BARN = 1
	TOWER = 2
}

var targets := [[null],[],[]]

onready var _agent = $NavigationAgent2D
onready var animation_player = $AnimationRoot/AnimationPlayer

func _ready():
	var barn_group = get_tree().get_nodes_in_group("Barn")
	if barn_group.size() == 0:
		return

	var barn = barn_group[0]
	targets[Target.BARN].append(barn)
	barn.connect("tree_exited", self, "_on_barn_destroyed", [], CONNECT_ONESHOT)
	_reevaluate_target(Target.BARN)

func _on_barn_destroyed():
	targets[Target.BARN].remove(0)
	_reevaluate_target(_current_target_type)

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
	if _is_target_valid():
		_agent.set_target_location(_current_target.global_position)

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
		animation_player.play("RESET")

func _get_priority(target: Node2D):
	var collision_priority = \
		(Target.BARN if target.is_in_group("Barn")
		 else Target.TOWER if target.is_in_group("Tower")
		 else Target.NONE)
	return collision_priority

func _on_field_of_view_entered(target: Node2D):
	var collision_priority = _get_priority(target)
	if collision_priority in [Target.BARN, Target.NONE]:
		# collision with enemy
		# barn is already added
		return
	targets[collision_priority].append(target)
	_reevaluate_target(collision_priority)

func _on_field_of_view_left(target: Node2D):
	var priority = _get_priority(target)
	if priority in [Target.BARN, Target.NONE]:
		# collision with enemy
		# barn is destroyed otherwise
		return
	targets[priority].erase(target)
	_reevaluate_target(priority)
	_update_animation()
