extends Node2D


# Declare member variables here. Examples:
# var a = 2
# var b = "text"
const Projectile = preload("res://scenes/Projectile.tscn")
var targets = []
export (bool) var is_active = false
export (int) var health = 20
export (int) var attack_speed_in_sec = 2
export (int) var projectile_dmg = 1
export (int) var projectile_speed = 200
export (int) var projectile_range = 30

# Called when the node enters the scene tree for the first time.
func _ready():
	$Area2D/CollisionShape2D.shape.radius = projectile_range
	$Timer.wait_time = attack_speed_in_sec

# Called every frame. 'delta' is the elapsed time since the previous frame.
# func _process(delta):


func _on_Area2D_body_entered(body: Node2D):
	if is_active:
		targets.append(body)
	

func _on_Area2D_body_exited(body: Node2D):
	targets.remove(targets.find(body))
	remove_child(body)


func _on_Timer_timeout():
	for target in targets:
		var projectile = Projectile.instance()
		var target_pos = target.global_position
		add_child(projectile)
		projectile.shoot_target(target_pos)
		projectile.speed = projectile_speed
		projectile.damage = projectile_dmg
