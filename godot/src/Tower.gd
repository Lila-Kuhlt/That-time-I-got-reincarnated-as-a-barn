extends Node2D

const Projectile = preload("res://scenes/Projectile.tscn")
var targets = []
var hits = []
onready var progress = $ProgressBar
var is_active = true setget _set_is_active


export (int) var health = 20
export (int) var attack_speed_in_sec = 2
export (int) var projectile_dmg = 1
export (int) var projectile_speed = 200
export (int) var projectile_range = 30


func _ready():
	$AnimationRoot/AnimationPlayer.play("Windmill")
	$Range/CollisionShape2D.shape.radius = projectile_range
	$Timer.wait_time = attack_speed_in_sec
	progress.max_value = health


func get_tower_name():
	return "Windmill"

func _on_Area2D_body_entered(body: Node2D):
	targets.append(body)

func _on_Area2D_body_exited(body: Node2D):
	targets.erase(body)
	if is_a_parent_of(body):
		remove_child(body)

func _on_Timer_timeout():
	for target in targets:
		var projectile = Projectile.instance()
		var target_pos = target.global_position
		add_child(projectile)
		projectile.shoot_target(target_pos)
		projectile.speed = projectile_speed
		projectile.damage = projectile_dmg

func _on_HitBox_body_entered(body):
	hits.append(body)

func _on_HitBox_body_exited(body):
	targets.erase(body)

func _on_HitTimer_timeout():
	var dmg = hits.size()
	health -= dmg
	if health > 0:
		progress.value = health
	else:
		queue_free()

func _set_is_active(v: bool):
	is_active = v
	$Range.monitorable = v
	$Range.monitoring = v
	
	$Collision/CollisionShape2D.disabled = not v
	
	$HitBox.monitorable = v
	$HitBox.monitoring = v
	
	modulate.a = 1 if is_active else 0.4
	
	
