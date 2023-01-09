extends Node2D

const INVENTORY = preload("res://src/Inventory.gd")

onready var anim := $AnimationPlayer
onready var sfx := $AudioStreamPlayer

var is_swinging = false setget _is_swinging_set,_is_swinging_get

func begin_use(world, player):
	var pos = world.Map.world_to_map(global_position)
	var plant = world.get_plant_at(pos)
	swing()
	if plant != null:
		var add_to_inventory = plant.harvest()
		if add_to_inventory > 0:
			var type = plant.plant_type
			var inventory = player.get_inventory()
			var to_be_added = INVENTORY.new()
			to_be_added.set_inventory_content({type: add_to_inventory})
			inventory.add(to_be_added)

func end_use():
	anim.play("RESET")
	return

func swing():
	if ! is_swinging :
		is_swinging = true
		anim.play("swing")
		sfx.play()

func _is_swinging_set(_value):
	assert(false)

func _is_swinging_get():
	return is_swinging

# Called when the node enters the scene tree for the first time.
func _ready():
	pass # Replace with function body.


func _on_animation_finished(_anim_name):
	is_swinging = false
