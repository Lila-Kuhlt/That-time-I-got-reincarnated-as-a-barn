extends AudioStreamPlayer2D

export var sounds = []

func play(from_position: float = 0.0):
	
	if sounds.size() == 0:
		return
	
	stream = sounds[randi() % sounds.size()]
	
	play(from_position)
