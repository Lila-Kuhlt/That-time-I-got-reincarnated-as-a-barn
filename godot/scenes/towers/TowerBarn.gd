extends "res://src/Tower.gd"

var _spawner_chain_element

func _ready():
	connect("destroyed", get_spawner_chain_element(), "_on_barn_destroyed")
	
# Manages the order of the Spawners and Barns
func get_spawner_chain_element():
	if not _spawner_chain_element:
		_spawner_chain_element = $SpawnerChainElement
	return _spawner_chain_element
