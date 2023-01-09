extends Node

signal inventory_changed(inventory)

export var initial_inventory = {
	Globals.ItemType.PlantChili : 5,
	Globals.ItemType.PlantTomato : 5,
	Globals.ItemType.PlantAubergine : 5,
	Globals.ItemType.PlantPotato : 5
}

var _inventory = {}

func _ready():
	# initialize data structure
	for type in initial_inventory.keys():
		_inventory[type] = initial_inventory.get(type, 0)
	
	# Sry about that
	yield(get_tree(), "idle_frame")
	emit_signal("inventory_changed", self)
	
func can_pay(cost_inventory) -> bool:
	for type in cost_inventory.get_keys():
		if cost_inventory._inventory[type] > _inventory[type]:
			return false
	return true

func _modify(modification_inventory, remove : bool = false):
	var multiplier = -1 if remove else 1
	for type in modification_inventory.get_keys():
		assert(modification_inventory.get_value(type) >= 0)
		_inventory[type] += multiplier * modification_inventory.get_value(type)
	emit_signal("inventory_changed", self)

func pay(cost_inventory):
	assert(can_pay(cost_inventory))
	_modify(cost_inventory, true)

func get_keys() -> Array:
	return _inventory.keys()
	
func get_value(key):
	return _inventory.get(key, 0)

func add(add_inventory):
	_modify(add_inventory)
