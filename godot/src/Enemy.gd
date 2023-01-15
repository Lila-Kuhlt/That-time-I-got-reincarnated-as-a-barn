extends KinematicBody2D

const MAX_DISTANCE_FOR_TARGET_CHANGE : float = 32.0

enum Target {
	NONE = 0
	BARN = 1
	TOWER = 2
}

export (bool) var can_attack := true
export (bool) var can_walk := true

export (float, 0, 500) var health: float = 3.0
export (int) var score := 1
export (int) var dmg := 1
export (int) var speed := 100

export (float) var knockback_resistance: float = 16.0

export (float, 0.0, 1.0) var alcohol_chance := 0.01
export (float) var alcohol_value := 1.3

var _current_target_type = Target.NONE
var _current_target: Node2D = null
var drunken_angle: float = 0.0

var knockback_velocity := Vector2(0, 0)

var active := true setget _set_active

var targets := [[null],[],[]]

onready var _agent: NavigationAgent2D = $NavigationAgent2D
onready var _animation_player = $AnimationRoot/AnimationPlayer
onready var _collision = $Collision
onready var _effect_animation_player = $AnimationRoot/EffectAnimationPlayer
onready var _field_of_view = $"Field of View"
onready var _hitbox = $Hitbox
onready var _sprite = $AnimationRoot/Sprite
onready var _has_vertical_animation = _animation_player.has_animation("run_vertical")

func _ready():
	Globals.curr_enemies += 1
	var barn_group = get_tree().get_nodes_in_group("Barn")
	if barn_group.size() == 0:
		return

	var barn = barn_group[0]
	targets[Target.BARN].append(barn)
	barn.connect("tree_exited", self, "_on_barn_destroyed", [], CONNECT_ONESHOT)
	_reevaluate_target(Target.BARN)

func _physics_process(delta: float):
	if not active:
		return
	# Move to goal
	if can_walk and _is_target_valid() and not _agent.is_navigation_finished():
			var next_location = _agent.get_next_location()
			var velocity := global_position.direction_to(next_location) * speed * delta
			if randf() < alcohol_chance:
				drunken_angle = (randf() * 2.0 - 1.0) * alcohol_value
			velocity = velocity.rotated(drunken_angle)
			_agent.set_velocity(velocity)
			_update_animation(velocity)
			var vel = velocity + knockback_velocity
			knockback_velocity = knockback_velocity.move_toward(Vector2(0,0),
				delta*self.knockback_resistance)
			move_and_collide(vel)

func _set_active(v):
	active = v

	_collision.set_deferred("disabled", not active)
	_field_of_view.monitoring = active and can_attack

	_hitbox.set_deferred("monitorable", active)

func _set_target(node: Node2D = null, type = Target.NONE):
	if _current_target == node:
		return

	if _current_target != null:
		_current_target.disconnect("tree_exited", self, "_reevaluate_target")

	if node != null:
		assert(node.is_inside_tree())
		node.connect("tree_exited", self, "_reevaluate_target", [type])

		# update NavigationAgent2Ds target
		_agent.set_target_location(node.global_position)

	_current_target = node
	_current_target_type = type

func _is_target_valid() -> bool:
	return _current_target != null && _current_target.is_inside_tree()

func _distance_from_target() -> float:
	assert(_current_target.is_inside_tree())
	assert(self.is_inside_tree())
	return _current_target.global_position.distance_to(global_position)

func _reevaluate_target(priority):
	if not can_walk or priority < _current_target_type \
		or _is_target_valid() and _distance_from_target() < MAX_DISTANCE_FOR_TARGET_CHANGE:
		return

	while priority > Target.NONE && targets[priority].size() == 0:
		priority = priority - 1

	_set_target(targets[priority][0], priority)

func _update_animation(dir):
	if _is_target_valid():
		var type = _get_animation_type()
		var direction : String

		_sprite.flip_h = dir.x <= 0
		if abs(dir.x) > abs(dir.y):
			direction = "horizontal"
			_sprite.flip_v = false
		else:
			direction = "vertical"
			if _has_vertical_animation:
				_sprite.flip_v = dir.y < 0
			else:
				_sprite.flip_v = false

		if _animation_player.has_animation(type + "_" + direction):
			_animation_player.play(type + "_" + direction)
		else:
			_animation_player.play(type)
	else:
		_animation_player.play("RESET")

func _get_animation_type() -> String:
	if _distance_from_target() <= Globals.tower_hitbox_size * 1.5:
		return "attack"
	else:
		return "run"

func _get_priority(target: Node2D):
	var collision_priority = \
		(Target.BARN if target.is_in_group("Barn")
		 else Target.TOWER if target.is_in_group("Tower")
		 else Target.NONE)
	return collision_priority

## PUBLIC
func warp_to(coord: Vector2):
	position = coord

# called when the enemy is hit by a projectile
# return true if killed
func damage(damage: float) -> bool:
	assert(damage >= 0.0)
	if not active:
		return false
	_effect_animation_player.play("hit")
	health -= damage

	if health <= 0.0:
		# enemy dies
		_set_active(false)
		Globals.curr_enemies -= 1
		Globals.add_score(score)
		_effect_animation_player.play("die")
		return true
	return false

## SIGNAL HANDLER
func _on_EffectAnimationPlayer_animation_finished(anim_name: String):
	if anim_name == "die":
		queue_free()

func _on_barn_destroyed():
	targets[Target.BARN].remove(0)
	_reevaluate_target(_current_target_type)

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
