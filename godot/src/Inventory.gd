extends Node

signal inventory_changed(inventory)

export var initial_inventory = {
	Globals.ItemType.PlantChili : 1,
	Globals.ItemType.PlantTomato : 2,
	Globals.ItemType.PlantAubergine : 3,
	Globals.ItemType.PlantPotato : 4
}

var _inventory = {}

func _ready():
	# initialize data structure
	_inventory = {}
	for type in Globals.PLANTS:
		_inventory[type] = initial_inventory.get(type, 0)
	
	# Sry about that
	yield(get_tree(), "idle_frame")
	emit_signal("inventory_changed", self)
	
func can_pay(cost_inventory) -> bool:
	for type in _inventory.keys():
		if cost_inventory._inventory[type] < _inventory[type]:
			return false
	return true

func pay(cost_inventory):
	for type in _inventory.keys():
		_inventory[type] -= cost_inventory._inventory[type]
	emit_signal("inventory_changed", self)

func try_pay(cost_inventory) -> bool:
	if can_pay(cost_inventory):
		pay(cost_inventory)
		return true
	return false

func get_keys() -> Array:
	return _inventory.keys()
	
func get_value(key):
	return _inventory.get(key, 0)
