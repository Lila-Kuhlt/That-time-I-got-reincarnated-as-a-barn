extends Node2D

signal enemy_soul_done

onready var _animator: AnimationPlayer = $AnimationPlayer
onready var _tween: Tween = $Tween

var world_pos_start: Vector2
var world_pos_target: Vector2

const SPEED = 64.0
const MIN_TIME = 0.5

func start_animation(world_pos_start: Vector2, world_pos_target: Vector2):
	global_position = world_pos_start
	self.world_pos_start = world_pos_start
	self.world_pos_target = world_pos_target
	$AnimationPlayer.play("show")

func _on_AnimationPlayer_animation_finished(anim_name: String):
	match anim_name:
		"show":
			_animator.play("laugh")
			
			var distance := world_pos_start.distance_to(world_pos_target)
			
			var time := distance / SPEED
			time = max(MIN_TIME, time)
			
			_tween.interpolate_property(self, "global_position", world_pos_start, world_pos_target, time, Tween.TRANS_CIRC, Tween.EASE_IN_OUT)
			_tween.start()
		"hide":
			emit_signal("enemy_soul_done")
			queue_free()

func _on_Tween_tween_all_completed():
	_animator.play("hide")
