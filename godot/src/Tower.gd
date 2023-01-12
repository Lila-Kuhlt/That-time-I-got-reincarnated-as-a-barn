extends Node2D

signal hover_start()
signal hover_end()
signal click()

signal health_changed(new_health, max_health)
signal stats_updated(tower)
signal enemy_killed(tower, enemy)
signal tower_destroyed()

export var Projectile = preload("res://scenes/Projectile.tscn")
export (String) var tower_name = "NOT SET"
export var can_shoot := true
export var range_indicator_color := Color(1,1,1,0.5) setget _set_range_indicator_color
export (bool) var is_active = true setget _set_is_active
export (int) var farmland_radius = 1
export (float) var y_spawn_offset = 0.0

var targets = []
var hits = []
onready var stats = $Stats
onready var progress = $ProgressBar
onready var health = $Stats.HP setget _set_health
onready var range_shader = $RangeShader
onready var max_health = health

func _ready():
	$AnimationRoot/AnimationPlayer.play("default")
	_on_Stats_stats_updated()
	_set_health(health)
	$RangeShader.material = $RangeShader.material.duplicate()
	_set_range_indicator_color(range_indicator_color)

	$RangeShader.visible = can_shoot

func _on_Stats_stats_updated():
	var rg = $Stats.RG
	$Range/CollisionShape2D.shape.radius = rg
	$RangeShader.rect_size = Vector2(rg * 2, rg * 2)
	$RangeShader.rect_position = Vector2(-rg, -rg)
	$RangeShader.material.set_shader_param("radius", rg)

	$HitBox/CollisionShape2D.shape.radius = Globals.tower_hitbox_size
	$Timer.wait_time = 1/(max(0.1, $Stats.AS))
	$ProgressBar.max_value = $Stats.HP

	emit_signal("stats_updated", self)
	if max_health != $Stats.HP:
		max_health = $Stats.HP
		emit_signal("health_changed", health, max_health)

func _set_health(v):
	var was_changed = health != v
	health = v
	if not is_active:
		return
	progress.value = max(health, 0)
	progress.visible = health < stats.HP
	if was_changed:
		emit_signal("health_changed", health, max_health)
	if health <= 0:
		_set_is_active(false)
		modulate.a = 1
		$AnimationRoot/AnimationPlayer.play("destroyed")

func heal(value):
	if (value + health) > max_health:
		value = max_health
	else:
		value = value + health
	_set_health(value)

func _on_Range_area_entered(area):
	targets.append(area.get_parent())

func _on_Range_area_exited(area):
	var body = area.get_parent()
	targets.erase(body)
	if is_a_parent_of(body):
		remove_child(body)

func _on_Timer_timeout():
	if can_shoot and targets.size() > 0:
		var target = _select_target()
		var projectile = Projectile.instance()
		var target_pos = target.global_position
		add_child(projectile)
		projectile.global_position.y += self.y_spawn_offset
		projectile.shoot_target(target_pos)
		projectile.speed = $Stats.PS
		projectile.damage = $Stats.DMG
		projectile.piercing = $Stats.PEN
		projectile.area_of_effect = $Stats.AOE
		projectile.knockback = $Stats.KB
		projectile.connect("enemy_killed", self, "_on_projectile_killed_enemy")
		$AnimationRoot/EffectsAnimationPlayer.play("shoot")

func _on_projectile_killed_enemy(enemy):
	emit_signal("enemy_killed", self, enemy)
	
func _select_target():
	if targets.size() == 0:
		return null

	var pos = global_position
	var dist = pos.distance_to(targets[0].global_position)
	var dist_index = 0
	for i in range(targets.size()):
		if i == 0:
			continue

		var new_dist = pos.distance_to(targets[0].global_position)
		if new_dist < dist:
			dist = new_dist
			dist_index = i
	return targets[dist_index]

func _on_HitBox_body_entered(body):
	hits.append(body)

func _on_HitBox_body_exited(body):
	hits.erase(body)

func _on_HitTimer_timeout():
	var dmg = 0
	for hit in hits:
		dmg += hit.dmg
	if dmg > 0:
		$AnimationRoot/EffectsAnimationPlayer.play("damage")
	_set_health(health - dmg)

func _set_is_active(v: bool):
	is_active = v
	$Range.monitoring = v

	$Collision.set_deferred("disabled", not v)

	$HitBox.set_deferred("monitorable", v)
	$HitBox.monitoring = v

	$MouseArea.mouse_filter = Control.MOUSE_FILTER_PASS if is_active else Control.MOUSE_FILTER_IGNORE

	modulate.a = 1.0 if is_active else 0.4

var is_hovered = false
func _on_MouseArea_mouse_entered():
	if not is_active:
		return
	emit_signal("hover_start")
	range_shader.visible = can_shoot
	is_hovered = true

func _on_MouseArea_mouse_exited():
	if not is_active:
		return
	emit_signal("hover_end")
	range_shader.visible = false
	is_hovered = false

func _on_MouseArea_pressed():
	if not is_active:
		return
	emit_signal("click")

func _set_range_indicator_color(color):
	range_indicator_color = color
	if is_inside_tree():
		$RangeShader.material.set_shader_param("border_color", color)


func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "destroyed":
		emit_signal("tower_destroyed")
		queue_free()
