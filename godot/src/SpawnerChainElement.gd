extends Node

enum Type {
	SPAWNER
	BARN
}

export(Type) var type = Type.SPAWNER

onready var parent: Node2D = get_parent()

var prev = null
var next = null

func _ready():
	if type == Type.SPAWNER:
		parent.set_map(parent.get_parent())
	
func set_neighs(prev, next):
	self.prev = prev
	self.next = next

func set_prev(prev):
	self.prev = prev

func set_next(next):
	self.next = next

func _replace_self_in_chain(node):
	node.global_position = parent.global_position
	node.get_spawner_chain_element().set_neighs(prev, next)
	
	# update the neighbors SpawnerChain Elements of change
	if prev != null:
		prev.get_spawner_chain_element().set_next(node)
	if next != null:
		next.get_spawner_chain_element().set_prev(node)
	
func _on_spawner_destroyed():
	prints("_on_spawner_destroyed", prev, next)
	
	# create new Barn and instance
	var barn = load("res://scenes/towers/TowerBarn.tscn").instance()
	
	# update all prev and next references
	_replace_self_in_chain(barn)
	
	# Add newly created Node to Map and immediately queue free parent (and therefore self)
	parent.get_parent().add_child(barn)
	parent.queue_free()
	
	if next != null:
		if next.get_spawner_chain_element().type == Type.SPAWNER:
			next.call_deferred("activate_spawner")
	else:
		print("GAME WON")

func _on_barn_destroyed():
	prints("_on_barn_destroyed", prev, next)
	
	# create new Barn and instance
	var spawner = load("res://scenes/Spawner.tscn").instance()
	
	# update all prev and next references
	_replace_self_in_chain(spawner)
	
	spawner.activate_spawner()
	
	if next != null:
		if next.get_spawner_chain_element().type == Type.SPAWNER:
			next.deactivate_spawner()
	
	if prev == null:
		print("GAME LOST")
	
	# Add newly created Node to Map and immediately queue free parent (and therefore self)
	parent.get_parent().add_child(spawner)
	parent.queue_free()
	
