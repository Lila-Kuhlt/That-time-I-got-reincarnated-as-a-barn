extends Node2D

onready var anim_player := $AnimationPlayer

var is_watering = false
var is_stoping = false
var _current_pos = null
var _world = null
export (float) var healvalue : float = 10

const NEIGHBORS = [
	Vector2(0,0),
	Vector2(1,1),
	Vector2(1,0),
	Vector2(1,-1),
	Vector2(0,1),
	Vector2(0,-1),
	Vector2(-1,1),
	Vector2(-1,0),
	Vector2(-1,-1),
]

func begin_use(world, player):
	var pos = world.map.world_to_map(player.global_position)
	_current_pos = pos
	_world = world
	if $Timer.is_stopped():
		start_hammer()
		$Timer.start()

func end_use():
	stop_hammer()
	if not $Timer.is_stopped():
		$Timer.stop()


const direction_map := {
	Globals.Direction.Left: Vector2(1, 1),
	Globals.Direction.Right: Vector2(-1, 1)
}

func set_direction(dir):
	assert(	dir == Globals.Direction.Right
			|| dir == Globals.Direction.Left)
	self.scale = direction_map[dir]

func start_hammer():
	anim_player.play("Hammer", -1, 2.5)
	anim_player.connect("animation_finished", self, "_on_anim_finished")

func _on_anim_finished(_name):
	anim_player.play("Hammer", -1, 2.5)

func stop_hammer():
	var anim_pos = anim_player.current_animation_position
	var anim_length = anim_player.current_animation_length
	if anim_pos < anim_length/2:
		anim_player.seek(anim_length - anim_pos)
	anim_player.disconnect("animation_finished", self, "_on_anim_finished")
	anim_player.queue("RESET")

func _on_Timer_timeout_heal():
	for dvec in NEIGHBORS:
		var pos = _current_pos + dvec
		var focus_tower = _world.get_tower_at(pos)
		if focus_tower != null && is_instance_valid(focus_tower):
			focus_tower.heal(healvalue)
