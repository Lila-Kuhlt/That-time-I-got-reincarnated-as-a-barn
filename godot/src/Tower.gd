extends Node2D

signal hover_started()
signal hover_ended()
signal clicked()

signal health_changed(new_health, max_health)
signal stats_updated(tower)
signal enemy_killed(tower, enemy)
signal destroyed()

const MIN_ATTACK_SPEED := 0.1

export var Projectile = preload("res://scenes/Projectile.tscn")
export (String) var tower_name := "NOT SET"
export (bool) var can_shoot := true
export (Color) var range_indicator_color := Color(1,1,1,0.5) setget _set_range_indicator_color
export (bool) var is_active = true setget _set_is_active
export (int, 0, 100) var farmland_radius = 1
export (float, 0.0, 6400.0) var y_spawn_offset = 0.0
export (bool) var keep_alive := false

onready var stats = $Stats
onready var _health_bar = $HealthBar
onready var _range_shader = $RangeShader
onready var _hitbox = $HitBox
onready var _hittimer = $HitTimer
onready var _range = $Range
onready var _anim_player = $AnimationRoot/AnimationPlayer
onready var _attack_timer = $AttackTimer
onready var _mouse_area = $MouseArea
onready var _particles_dust: Particles2D = $ParticlesDustCloud

onready var max_health setget _set_max_health
onready var health setget _set_health

## PRIVATE
func _ready():
	_anim_player.play("default")
	stats.connect("stats_updated", self, "_on_Stats_stats_updated")
	_on_Stats_stats_updated()
	_set_health(max_health)
	_set_range_indicator_color(range_indicator_color)
	_range_shader.material = _range_shader.material.duplicate()
	_range_shader.visible = can_shoot
	$HitBox/CollisionShape2D.shape.radius = Globals.tower_hitbox_size

func _set_health(value):
	var v = min(max(value, 0), max_health)
	if health == v:
		return

	health = v
	if not is_active:
		return
	_health_bar.value = health
	_health_bar.visible = health < max_health
	emit_signal("health_changed", health, max_health)
	if health <= 0:
		_destroyed()

func _destroyed():
	_set_is_active(false)
	modulate.a = 1
	_particles_dust.emit_and_despawn(get_parent().get_parent())
	_anim_player.play("destroyed")

func _set_range(value):
	assert(value >= 0)
	$Range/CollisionShape2D.shape.radius = value
	_range_shader.rect_size = Vector2(value * 2, value * 2)
	_range_shader.rect_position = Vector2(-value, -value)
	_range_shader.material.set_shader_param("radius", value)

func _set_attack_speed(value):
	assert(value >= 0)
	_attack_timer.wait_time = 1/(max(MIN_ATTACK_SPEED, value))

func _set_max_health(value):
	assert(value > 0)
	if value == max_health:
		return

	_health_bar.max_value = value
	max_health = value
	emit_signal("health_changed", health, max_health)

func _set_is_active(v: bool):
	if v == is_active:
		return
	
	is_active = v
	_range.monitoring = v

	$Collision.set_deferred("disabled", not v)

	_hitbox.set_deferred("monitorable", v)
	_hitbox.monitoring = v

	if v:
		_hittimer.start()
		_attack_timer.start()
		_mouse_area.mouse_filter = Control.MOUSE_FILTER_PASS
		_mouse_area.connect("mouse_entered", self, "_on_mouse_entered")
		_mouse_area.connect("mouse_exited", self, "_on_mouse_exited")
		_mouse_area.connect("pressed", self, "_on_mouse_pressed")
		modulate.a = 1.0
		_particles_dust.emitting = true
	else:
		_hittimer.stop()
		_attack_timer.stop()
		_mouse_area.mouse_filter = Control.MOUSE_FILTER_IGNORE
		_mouse_area.disconnect("mouse_entered", self, "_on_mouse_entered")
		_mouse_area.disconnect("mouse_exited", self, "_on_mouse_exited")
		_mouse_area.disconnect("pressed", self, "_on_mouse_pressed")
		modulate.a = 0.4

func _set_range_indicator_color(color):
	range_indicator_color = color
	if is_inside_tree():
		_range_shader.material.set_shader_param("border_color", color)

func _select_target():
	assert(_range.monitoring)
	var targets = _range.get_overlapping_areas()
	if targets.size() == 0:
		return null

	var pos = global_position
	var min_dist = pos.distance_to(targets[0].global_position)
	var min_dist_index = 0
	for i in range(1, targets.size()):
		var dist = pos.distance_to(targets[i].global_position)
		if dist < min_dist:
			min_dist = dist
			min_dist_index = i
	return targets[min_dist_index]

## PUBLIC
func heal(value):
	assert(value > 0)
	_set_health(health + value)

func damage(value):
	assert(value > 0)
	$AnimationRoot/EffectsAnimationPlayer.play("damage")
	_set_health(health - value)

## SIGNAL HANDLER
func _on_Stats_stats_updated():
	_set_range(stats.RG)
	_set_attack_speed(stats.AS)
	_set_max_health(stats.HP)
	
	# adjust animation speed
	var d = (stats.AS / stats.initial_AS) if stats.initial_AS > 0 else 1
	_anim_player.playback_speed = d + 0.3*(d-1)*(d-1)

	emit_signal("stats_updated", self)

func _on_AttackTimer_timeout():
	if can_shoot and is_active:
		var target = _select_target()
		if target == null:
			return

		var projectile = Projectile.instance()
		var target_pos = target.global_position
		add_child(projectile)
		projectile.tower = self
		projectile.global_position.y += self.y_spawn_offset
		projectile.shoot_target(target_pos)
		projectile.speed = stats.PS
		projectile.damage = stats.DMG
		projectile.piercing = stats.PEN
		projectile.area_of_effect = stats.AOE
		projectile.knockback = stats.KB
		projectile.connect("enemy_killed", self, "_on_projectile_killed_enemy")
		$AnimationRoot/EffectsAnimationPlayer.play("shoot")

func _on_projectile_killed_enemy(tower, enemy):
	emit_signal("enemy_killed", self, enemy)

func _on_HitTimer_timeout():
	var enemies = _hitbox.get_overlapping_bodies()
	if enemies.size() == 0:
		return

	var dmg = 0
	for enemy in enemies:
		dmg += enemy.dmg
	if dmg > 0:
		damage(dmg)

func _on_mouse_entered():
	assert(is_active)
	emit_signal("hover_started")
	_range_shader.visible = can_shoot

func _on_mouse_exited():
	assert(is_active)
	emit_signal("hover_ended")
	_range_shader.visible = false

func _on_mouse_pressed():
	assert(is_active)
	emit_signal("clicked")

func _on_AnimationPlayer_animation_finished(anim_name):
	if anim_name == "destroyed":
		emit_signal("destroyed")
		queue_free()
