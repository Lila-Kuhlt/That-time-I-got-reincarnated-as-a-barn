extends Node2D

var speed: float = 200
var damage: float = 1.0
var piercing: int = 1 # the maximum amount of enemies the projectile can hit in a row
var target: Vector2

const enemy_class = preload("res://src/Enemy.gd")

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.

func shoot_target(target_pos: Vector2):
	target = target_pos

func _physics_process(delta: float):
	if global_position.is_equal_approx(target):
		queue_free()
	global_position = global_position.move_toward(target, speed * delta)


func _on_enemy_hit(area):
	# collision layer 14 is for projectile-enemy collision
	var enemy = area.get_parent()
	if not enemy is enemy_class:
		return
	enemy.damage(damage)
	piercing -= 1
	if piercing == 0:
		queue_free()
