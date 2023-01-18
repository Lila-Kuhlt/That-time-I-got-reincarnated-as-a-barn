extends Node

func create_chain(barn: Node2D, spawners: Array):
	
	# setup loop vars
	var cur_target: Node2D = barn
	var targets_in_order := [barn]
	
	# create copy of spawner List and iterate until empty
	var spawners_left = spawners.duplicate()
	while spawners_left.size() > 0:
		# pop spawner that is closes to current target
		var spawner = get_spawner_with_min_dst_to(spawners_left, cur_target)
		
		if spawner == null:
			break
		
		spawners_left.erase(spawner)
		
		# tell this spawner of its target
		spawner._set_target(cur_target)
		
		# update loop vars
		targets_in_order.append(spawner)
		cur_target = spawner
	
	prints("Connected", targets_in_order.size()-1, "/", spawners.size(), "spawners")
	
	for i in range(targets_in_order.size()):
		var target = targets_in_order[i]
		# find prev and next in chain if there are, null otherwise
		var prev = targets_in_order[i - 1] if i > 0 else null
		var next = targets_in_order[i + 1] if i < targets_in_order.size() - 1 else null
		target.get_chain_link().order_id = i
		target.get_chain_link().set_neighs(prev, next)
	
	Globals.connect("game_started", targets_in_order[1], "activate_spawner", [targets_in_order[0]])
	
func get_spawner_with_min_dst_to(spawners, target):
	var cur_min_dst = INF
	var cur_target = null
	for spawner in spawners:
		spawner._agent.set_target_location(target.global_position)
		var dst = spawner._agent.distance_to_target()
		if dst == 0:
			continue

		if dst < cur_min_dst:
			cur_min_dst = dst
			cur_target = spawner
	return cur_target
