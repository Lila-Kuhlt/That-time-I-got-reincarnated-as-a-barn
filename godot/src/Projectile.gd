extends Node2D

export var speed: float = 200
export var damage: float = 1.0
export var knockback: float = 0.1
# the amount of enemies the projectile can pierce before hitting its final target
export var piercing: int = 0
# the area of effect that gets damage when the projectile hits its final target
export var area_of_effect: float = 0.0 setget _set_area_of_effect

export var target: Vector2
export var source: Vector2

var is_active = true

# there is no guaranteed order of collision detection
# so we start the final countdown in the next physics step
var _start_final_countdown := false

func _set_area_of_effect(new_area_of_effect):
	assert(new_area_of_effect >= 0.0)
	area_of_effect = new_area_of_effect
	$AreaOfEffect/CollisionShape2D.shape.radius = \
		$Area2D/CollisionShape2D.shape.radius + new_area_of_effect

# Called when the node enters the scene tree for the first time.
func _ready():
	# set initial radius of AreaOfEffect
	_set_area_of_effect(area_of_effect)
	if $AnimationPlayer.has_animation("Idle"):
		$AnimationPlayer.play("Idle")

func shoot_target(target_pos: Vector2):
	target = target_pos
	source = global_position
	$RandomAudioStreamPlayer2D.play()

func _physics_process(delta: float):
	if _start_final_countdown or global_position.is_equal_approx(target):
		_final_countdown()
	global_position = global_position.move_toward(target, speed * delta)


func _on_enemy_hit(area):
	if not is_active:
		return

	# collision layer 14 is for projectile-enemy collision
	if not area.is_in_group("Enemy"):
		return
	var enemy = area.get_parent()

	if knockback > 0:
		enemy.knockback_velocity = (target - source).normalized() * knockback

	if piercing == 0:
		_start_final_countdown = true
	else:
		enemy.damage(damage)
		piercing -= 1

func _final_countdown():
	if not is_active:
		return
	
	if $AnimationPlayer.has_animation("Splash"):
		$AnimationPlayer.play("Splash")
	for area in $AreaOfEffect.get_overlapping_areas():
		if not area.is_in_group("Enemy"):
			continue
		var enemy = area.get_parent()
		enemy.damage(damage)
	is_active = false
	shoot_target(global_position)
	if($AnimationPlayer.has_animation("Splash")):
		$Timer.start($AnimationPlayer.get_animation("Splash").length)
	else:
		$Timer.start(0)

func _final_final_end():
	queue_free()
	pass # Replace with function body.
