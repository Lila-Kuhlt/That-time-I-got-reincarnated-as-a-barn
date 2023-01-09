extends Node2D

signal hover_start()
signal hover_end()
signal click()
signal select()
signal unselect()

export var Projectile = preload("res://scenes/Projectile.tscn")
export (String) var tower_name = "NOT SET"
export var can_shoot := true
export (bool) var is_active = true setget _set_is_active
export (int) var farmland_radius = 1
export (float) var y_spawn_offset = 0.0

var targets = []
var hits = []
onready var stats = $Stats
onready var progress = $ProgressBar
onready var health = $Stats.HP setget _set_health

func _ready():
	$AnimationRoot/AnimationPlayer.play("default")
	_on_Stats_stats_updated()
	_set_health(health)

func _on_Stats_stats_updated():
	$Range/CollisionShape2D.shape.radius = $Stats.RG
	$Timer.wait_time = 1/(max(0.1, $Stats.AS))
	$ProgressBar.max_value = $Stats.HP

func _set_health(v):
	health = v
	progress.value = max(health, 0)
	progress.visible = health < stats.HP
	if health <= 0:
		queue_free()

func _on_Range_area_entered(area):
	targets.append(area.get_parent())

func _on_Range_area_exited(area):
	var body = area.get_parent()
	targets.erase(body)
	if is_a_parent_of(body):
		remove_child(body)

func _on_Timer_timeout():
	if can_shoot and targets.size() > 0:
		var target = targets[0]
		var projectile = Projectile.instance()
		var target_pos = target.global_position
		add_child(projectile)
		projectile.global_position.y += self.y_spawn_offset
		projectile.shoot_target(target_pos)
		projectile.speed = $Stats.PS
		projectile.damage = $Stats.DMG
		projectile.piercing = $Stats.PEN
		projectile.area_of_effect = $Stats.AOE

func _on_HitBox_body_entered(body):
	hits.append(body)

func _on_HitBox_body_exited(body):
	hits.erase(body)

func _on_HitTimer_timeout():
	var dmg = hits.size()
	_set_health(health - dmg)

func _set_is_active(v: bool):
	is_active = v
	$Range.monitorable = v
	$Range.monitoring = v

	$Collision/CollisionShape2D.disabled = not v

	$HitBox.monitorable = v
	$HitBox.monitoring = v
	
	$MouseArea.mouse_filter = Control.MOUSE_FILTER_PASS if is_active else Control.MOUSE_FILTER_IGNORE

	modulate.a = 1 if is_active else 0.4

var is_hovered = false
func _on_MouseArea_mouse_entered():
	if not is_active:
		return
	emit_signal("hover_start")
	is_hovered = true
func _on_MouseArea_mouse_exited():
	if not is_active:
		return
	emit_signal("hover_end")
	is_hovered = false
func _on_MouseArea_pressed():
	if not is_active:
		return
	emit_signal("click")
