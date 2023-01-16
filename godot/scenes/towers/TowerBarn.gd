extends "res://src/Tower.gd"

var _chain_link

func _ready():
	connect("destroyed", get_chain_link(), "_on_barn_destroyed")
	
# Manages the order of the Spawners and Barns
func get_chain_link():
	if not _chain_link:
		_chain_link = $ChainLink
	return _chain_link
