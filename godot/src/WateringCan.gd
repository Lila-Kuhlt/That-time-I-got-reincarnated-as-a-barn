extends Node2D

onready var anim_player := $AnimationPlayer

signal watering_finished

var is_watering = false
var is_stoping = false

const direction_map := {
	Globals.Direction.Left: Vector2(1, 1),
	Globals.Direction.Right: Vector2(-1, 1)
}

func set_direction(dir):
	assert(	dir == Globals.Direction.Right
			|| dir == Globals.Direction.Left)
	self.scale = direction_map[dir]

func start_watering():
	if is_watering && not is_stoping:
		return
	
	if is_stoping:
		anim_player.disconnect("animation_finished", self, "_on_animation_finished")
		is_stoping = false
		anim_player.queue("start_watering")
	else:
		anim_player.play("start_watering")

	is_watering = true
	anim_player.queue("water")


func stop_watering():
	if not is_watering || is_stoping:
		return
	
	is_stoping = true
	anim_player.play("stop_watering")
	anim_player.connect("animation_finished", self, "_on_animation_finished", [], CONNECT_ONESHOT)

func _on_animation_finished(name):
	is_watering = false
	is_stoping = false
	emit_signal("watering_finished")
