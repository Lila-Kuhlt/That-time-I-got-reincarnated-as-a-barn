extends KinematicBody2D

export (float) var walking_speed = 65

onready var _anim_player := $AnimationRoot/AnimationPlayer
onready var _anim_root := $AnimationRoot

onready var scyth = $AnimationRoot/Scythe
onready var watering_can = $AnimationRoot/WateringCan

const direction_map := {
	Globals.Direction.Up: ["walk_up", Vector2(1, 1)],
	Globals.Direction.Right: ["walk_side", Vector2(1, 1)],
	Globals.Direction.Left: ["walk_side", Vector2(-1, 1)],
	Globals.Direction.Down: ["walk_down", Vector2(1, 1)],
	Globals.Direction.None: ["RESET", Vector2(1, 1)]
}

var current_dir = Globals.Direction.None


func is_idle() -> bool:
	return current_dir == Globals.Direction.None

func _ready():
	_unequip()
	pass

func _apply_animation(direction):
	var anim : String = direction_map[direction][0]
	var scale : Vector2 = direction_map[direction][1]
	_anim_player.play(anim)
	_anim_root.scale = scale
	self.current_dir = direction

func _physics_process(delta):
	var dir := Input.get_vector("left", "right", "up", "down")
	var current_dir = ( Globals.Direction.Right if dir.x > 0
						else Globals.Direction.Left if dir.x < 0
						else Globals.Direction.Up if dir.y < 0
						else Globals.Direction.Down if dir.y > 0
						else Globals.Direction.None)

	if self.current_dir != current_dir:
		_apply_animation(current_dir)

	move_and_slide(dir * walking_speed, Vector2(0, -1))

# TODO Make this a reciever for a signal from the Toolbar
func equip_item(id):
	if not id in Globals.TOOLS:
		return
	
	if id == Globals.ItemType.ToolScythe:
		_equip_scyth()
	elif id == Globals.ItemType.ToolWateringCan:
		_equip_watering_can()

func _equip_watering_can():
	watering_can.visible = true
	scyth.visible = false
	pass

func _equip_scyth():
	scyth.visible = true
	watering_can.visible = false
	pass

func _unequip():
	scyth.visible = false
	watering_can.visible = false
	pass
