extends Node2D

var speed: float = 200
var damage: float = 1.0
# the amount of enemies the projectile can pierce before hitting its final target
var piercing: int = 0
# the area of effect that gets damage when the projectile hits its final target
var area_of_effect: float = 0.0 setget _set_area_of_effect
var target: Vector2

func _set_area_of_effect(new_area_of_effect):
	area_of_effect = new_area_of_effect
	$AreaOfEffect/CollisionShape2D.shape.radius = \
		$Area2D/CollisionShape2D.shape.radius + new_area_of_effect

# Called when the node enters the scene tree for the first time.
func _ready():
	# set initial radius of AreaOfEffect
	_set_area_of_effect(area_of_effect)

func shoot_target(target_pos: Vector2):
	target = target_pos

func _physics_process(delta: float):
	if global_position.is_equal_approx(target):
		_final_countdown()
	global_position = global_position.move_toward(target, speed * delta)


func _on_enemy_hit(area):
	# collision layer 14 is for projectile-enemy collision
	if not area.is_in_group("Enemy"):
		return
	var enemy = area.get_parent()

	if piercing == 0:
		_final_countdown()
	else:
		enemy.damage(damage)
		piercing -= 1

func _final_countdown():
	for area in $AreaOfEffect.get_overlapping_areas():
		if not area.is_in_group("Enemy"):
			continue
		var enemy = area.get_parent()
		enemy.damage(damage)
	queue_free()
