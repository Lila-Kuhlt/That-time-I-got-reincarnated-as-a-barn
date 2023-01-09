extends KinematicBody2D

signal player_inventory_changed(inventory)

export (float) var walking_speed : float = 130
export (float) var zoom_speed_mouse : float = 0.18
export (float) var zoom_speed_keyboard : float = 0.03
export (float) var min_zoom : float = 0.3
export (float) var max_zoom : float = 2.8

const animation_speed_modifier := 64

onready var _map = self.get_parent()
onready var _anim_player := $AnimationRoot/AnimationPlayer
onready var _anim_root := $AnimationRoot

onready var _scythe = $AnimationRoot/Scythe
onready var _watering_can = $AnimationRoot/WateringCan

var current_equiped_item = null
var is_using_tool = false

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

func get_inventory():
	return $Inventory

func _apply_direction(direction):
	var anim : String = _direction_map[direction][0]
	var scale : Vector2 = _direction_map[direction][1]
	_anim_player.play(anim, -1, walking_speed/animation_speed_modifier)
	_anim_root.scale = scale
	self._current_dir = direction
	
func begin_use_tool(world):
	assert(current_equiped_item)
	is_using_tool = true
	current_equiped_item.begin_use(world, self)

func end_use_tool():
	is_using_tool = false
	current_equiped_item.end_use()

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

func _process(delta):
	var zoom: float
	if Input.is_action_pressed("zoom_in"):
		zoom = -zoom_speed_keyboard
	elif Input.is_action_pressed("zoom_out"):
		zoom = zoom_speed_keyboard
	else:
		var zoom_mod: bool = Input.is_action_pressed("zoom_modifier")
		var szoom_out := zoom_mod and Input.is_action_just_released("scroll_left_mouse")
		var szoom_in := zoom_mod and Input.is_action_just_released("scroll_right_mouse")
		zoom = 1.0 if szoom_out else (-1.0 if szoom_in else 0.0)
		zoom *= zoom_speed_mouse
	zoom = min(max($Camera2D.zoom.x + zoom, min_zoom), max_zoom)
	$Camera2D.zoom = Vector2(zoom, zoom)

func equip_item(id, _null):
	if is_using_tool:
		end_use_tool()
	var equip_watering_can = id == Globals.ItemType.ToolWateringCan
	var equip_scythe = id == Globals.ItemType.ToolScythe
	_watering_can.visible = equip_watering_can
	_scythe.visible = equip_scythe
	current_equiped_item = (_scythe if equip_scythe 
							else _watering_can if equip_watering_can
							else null)


func _on_Inventory_inventory_changed(inventory):
	emit_signal("player_inventory_changed", inventory)
