extends Particles2D

var _despawn := false
func emit_and_despawn(parent: Node2D):
	
	var pos = global_position
	get_parent().remove_child(self)
	parent.add_child(self)
	global_position = pos
	
	_despawn = true
	restart()
	emitting = true

func _process(delta):
	if _despawn and not emitting:
		queue_free()
		_despawn = false
