extends Node2D

export var Projectile = preload("res://scenes/Projectile.tscn")

export (int) var max_health = 20
export (String) var tower_name = "NOT SET"
export (int) var attack_speed_in_sec = 2
export (int) var projectile_dmg = 1
export (int) var projectile_speed = 200
export (int) var projectile_range = 100
export (int) var farmland_radius = 1

export (bool) var is_active = true setget _set_is_active
var targets = []
var hits = []
onready var progress = $ProgressBar
onready var health = max_health

func _ready():
	$AnimationRoot/AnimationPlayer.play("default")
	$Range/CollisionShape2D.shape.radius = projectile_range
	$Timer.wait_time = attack_speed_in_sec
	progress.max_value = max_health


func _on_Range_area_entered(area):
	targets.append(area.get_parent())

func _on_Range_area_exited(area):
	var body = area.get_parent()
	targets.erase(body)
	if is_a_parent_of(body):
		remove_child(body)

func _on_Timer_timeout():
	if targets.size() > 0:
		var target = targets[0]
		var projectile = Projectile.instance()
		var target_pos = target.global_position
		add_child(projectile)
		projectile.shoot_target(target_pos)
		projectile.speed = projectile_speed
		projectile.damage = projectile_dmg

func _on_HitBox_body_entered(body):
	hits.append(body)

func _on_HitBox_body_exited(body):
	hits.erase(body)

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
