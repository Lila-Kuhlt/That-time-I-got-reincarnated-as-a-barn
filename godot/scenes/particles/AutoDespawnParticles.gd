extends Particles2D

var _despawn := false
func emit_and_despawn():
	_despawn = true

func _process(delta):
	if _despawn and not emitting:
		queue_free()
		_despawn = false
