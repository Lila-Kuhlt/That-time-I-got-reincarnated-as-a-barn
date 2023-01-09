extends KinematicBody2D

signal player_inventory_changed(inventory)

export (float) var walking_speed : float = 130

const animation_speed_modifier := 64

onready var _anim_player := $AnimationRoot/AnimationPlayer
onready var _anim_root := $AnimationRoot

onready var _scythe = $AnimationRoot/Scythe
onready var _watering_can = $AnimationRoot/WateringCan

var current_equiped_item = null

const _direction_map := {
	Globals.Direction.Up: ["walk_up", Vector2(1, 1)],
	Globals.Direction.Right: ["walk_side", Vector2(1, 1)],
	Globals.Direction.Left: ["walk_side", Vector2(-1, 1)],
	Globals.Direction.Down: ["walk_down", Vector2(1, 1)],
	Globals.Direction.None: ["RESET", Vector2(1, 1)]
}

var _current_dir = Globals.Direction.None

func is_idle() -> bool:
	return _current_dir == Globals.Direction.None

func _ready():
	var ui_node = get_tree().get_nodes_in_group("UI")[0]
	ui_node.connect("item_selected", self, "equip_item")


func _apply_direction(direction):
	var anim : String = _direction_map[direction][0]
	var scale : Vector2 = _direction_map[direction][1]
	_anim_player.play(anim, -1, walking_speed/animation_speed_modifier)
	_anim_root.scale = scale
	self._current_dir = direction

func _physics_process(_delta):
	var dir := Input.get_vector("left", "right", "up", "down")
	var current_dir = ( Globals.Direction.Right if dir.x > 0
						else Globals.Direction.Left if dir.x < 0
						else Globals.Direction.Up if dir.y < 0
						else Globals.Direction.Down if dir.y > 0
						else Globals.Direction.None)

	if self._current_dir != current_dir:
		_apply_direction(current_dir)

	move_and_slide(dir * walking_speed, Vector2(0, -1))

func equip_item(id):
	var equip_watering_can = id == Globals.ItemType.ToolWateringCan
	var equip_scythe = id == Globals.ItemType.ToolScythe
	_watering_can.visible = equip_watering_can
	_scythe.visible = equip_scythe
	current_equiped_item = (_scythe if equip_scythe 
							else _watering_can if equip_watering_can
							else null)


func _on_Inventory_inventory_changed(inventory):
	emit_signal("player_inventory_changed", inventory)
