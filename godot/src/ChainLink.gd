extends Node

enum Type {
	SPAWNER
	BARN
}

export(Type) var type = Type.SPAWNER

onready var parent: Node2D = get_parent()

var order_id = -1 setget _set_order_id
var prev = null
var next = null

func _ready():
	var map = parent.get_parent()
	if type == Type.SPAWNER:
		parent.wave_pool_level = order_id - 1
		parent.set_map(map)
	
	var map_pos: Vector2 = map.world_to_map(parent.global_position)
	if type == Type.BARN:
		map.l_ground.set_cellv(map_pos, map.l_ground.INVALID_CELL)
	elif type == Type.SPAWNER:
		map.l_ground.set_cellv(map_pos, map.l_ground.wasteland_id)
	map.l_ground.update_bitmask_area(map_pos)
	
	map.emit_signal("tower_added", map_pos, parent)
	
func set_neighs(prev, next):
	self.prev = prev
	self.next = next

func set_prev(prev):
	self.prev = prev

func set_next(next):
	self.next = next

func get_all_chain_links() -> Array:
	return get_all_prevs() + [self] + get_all_nexts()
		
func get_all_nexts() -> Array:
	var all_nexts := []
	var n = self
	while n.next != null:
		n = n.next.get_chain_link()
		all_nexts.append(n)
	return all_nexts
func get_all_prevs() -> Array:
	var all_prevs := []
	var p = self
	while p.prev != null:
		p = p.prev.get_chain_link()
		all_prevs.append(p)
	all_prevs.invert()
	return all_prevs

func _replace_self_in_chain(node):
	node.global_position = parent.global_position
	node.get_chain_link().set_neighs(prev, next)
	node.get_chain_link().order_id = order_id
	
	# update the neighbors chain links of change
	if prev != null:
		prev.get_chain_link().set_next(node)
	if next != null:
		next.get_chain_link().set_prev(node)

func _update_all_chain_links():
	var last_barn = null
	var last_was_barn = false
	var total_barns = 0
	var total_spawners = 0
	
	for chain_elem in get_all_chain_links():
		match chain_elem.type:
			Type.BARN:
				last_barn = chain_elem.get_parent()
				last_was_barn = true
				total_barns += 1
			Type.SPAWNER:
				if last_was_barn or chain_elem.get_parent().active:
					chain_elem.get_parent().call_deferred("activate_spawner", last_barn)
				last_was_barn = false
				total_spawners += 1
				
	if total_barns == 0:
		Globals.emit_signal("game_lost")
	if total_spawners == 0:
		Globals.emit_signal("game_won")

func _on_spawner_destroyed():
	var barn = load("res://scenes/towers/TowerBarn.tscn").instance()
	
	# update all prev and next references
	_replace_self_in_chain(barn)
	
	# start any spawners and check for win condition
	barn.get_chain_link()._update_all_chain_links()
	barn.play_conquer_animation()
	
	# Add newly created Node to Map and immediately queue free parent (and therefore self)
	parent.get_parent().add_child(barn)
	parent.queue_free()

func _on_barn_destroyed():
	var spawner = load("res://scenes/Spawner.tscn").instance()
	
	# update all prev and next references
	_replace_self_in_chain(spawner)
	
	# start any spawners and check for win condition
	spawner.get_chain_link()._update_all_chain_links()
	
	# remove Score if (non-initial) barn destroyed
	if prev != null:
		Globals.add_score(-100)
	
	# Add newly created Node to Map and immediately queue free parent (and therefore self)
	parent.get_parent().add_child(spawner)
	parent.queue_free()

func _set_order_id(v):
	order_id = v
	if type == Type.SPAWNER:
		get_parent().wave_pool_level = order_id - 1
	
